{
  config,
  pkgs,
  ...
}: let
  # Use the same docker the host runs so CLI/daemon never skew.
  dockerBin = "${config.virtualisation.docker.package}/bin/docker";

  # One-shot backup for a named container/stanza via pgBackRest.
  # Missing/stopped containers and Docker errors must count as missed backups.
  mkBackup = container: stanza: type:
    pkgs.writeShellScript "pgbackrest-${stanza}-${type}.sh" ''
      set -euo pipefail
      running=$(${dockerBin} inspect -f '{{.State.Running}}' ${container})
      if [ "$running" != "true" ]; then
        echo "${container} not running; ${stanza} ${type} backup failed" >&2
        exit 1
      fi
      ${dockerBin} exec -u postgres ${container} pgbackrest --stanza=${stanza} check
      exec ${dockerBin} exec -u postgres ${container} \
        pgbackrest --stanza=${stanza} --type=${type} backup
    '';

  mkService = container: stanza: type: {
    description = "pgBackRest ${type} backup (${stanza} DB → S3)";
    after = ["docker.service"];
    wants = ["docker.service"];
    onFailure = ["pgbackrest-notify@%n.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = mkBackup container stanza type;
      TimeoutStartSec = "6h";
    };
  };
in {
  # Scheduled pgBackRest backups. WAL archiving is continuous (PITR); these
  # add the periodic full/incr base backups so repo1-retention-full=2 prunes.
  #
  # scraper-db: full Sunday 01:00, incr Mon-Sat 02:00
  # logto-db:   full Sunday 01:30, incr Mon-Sat 02:30 (30-min offset avoids S3 contention)
  #
  # The Logto image renders its pgbackrest config and creates its stanza at
  # startup. `check` above verifies repository access and WAL archiving before
  # each backup; a successful backup still needs a separate restore drill.
  systemd.services."pgbackrest-notify@" = {
    description = "Notify Slack of a failed PostgreSQL backup (%i)";
    serviceConfig = {
      Type = "oneshot";
      LoadCredential = "webhook:${config.age.secrets."velomo-alpha/alertmanager-slack-url".path}";
    };
    path = [pkgs.curl pkgs.jq];
    scriptArgs = "%i";
    script = ''
      set -euo pipefail
      payload=$(jq -n --arg unit "$1" '{text: ("PostgreSQL backup failed on velomo-alpha: " + $unit + ". Inspect journalctl -u " + $unit)}')
      # Keep the webhook out of argv and the journal.
      printf 'url = "%s"\n' "$(cat "$CREDENTIALS_DIRECTORY/webhook")" |
        curl --config - --fail --silent --show-error --retry 3 --max-time 30 \
          -H 'Content-Type: application/json' --data "$payload"
    '';
  };
  systemd.services.pgbackrest-scraper-full = mkService "scraper-db" "scraper" "full";
  systemd.services.pgbackrest-scraper-incr = mkService "scraper-db" "scraper" "incr";
  systemd.services.pgbackrest-logto-full = mkService "logto-db" "logto" "full";
  systemd.services.pgbackrest-logto-incr = mkService "logto-db" "logto" "incr";

  systemd.timers.pgbackrest-scraper-full = {
    description = "Weekly full pgBackRest backup (scraper)";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "Sun 01:00";
      Persistent = true;
      RandomizedDelaySec = "15m";
    };
  };

  systemd.timers.pgbackrest-scraper-incr = {
    description = "Daily incremental pgBackRest backup (scraper)";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "Mon..Sat 02:00";
      Persistent = true;
      RandomizedDelaySec = "15m";
    };
  };

  systemd.timers.pgbackrest-logto-full = {
    description = "Weekly full pgBackRest backup (logto)";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "Sun 01:30";
      Persistent = true;
      RandomizedDelaySec = "15m";
    };
  };

  systemd.timers.pgbackrest-logto-incr = {
    description = "Daily incremental pgBackRest backup (logto)";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "Mon..Sat 02:30";
      Persistent = true;
      RandomizedDelaySec = "15m";
    };
  };
}
