{
  config,
  pkgs,
  ...
}: let
  # Use the same docker the host runs so CLI/daemon never skew.
  dockerBin = "${config.virtualisation.docker.package}/bin/docker";

  # One-shot backup for a named container/stanza via pgBackRest.
  # No-op if the container isn't running (stopped/redeploying stack won't fail the unit).
  mkBackup = container: stanza: type:
    pkgs.writeShellScript "pgbackrest-${stanza}-${type}.sh" ''
      set -euo pipefail
      if [ "$(${dockerBin} inspect -f '{{.State.Running}}' ${container} 2>/dev/null)" != "true" ]; then
        echo "${container} not running; skipping ${stanza} ${type} backup"
        exit 0
      fi
      exec ${dockerBin} exec -u postgres ${container} \
        pgbackrest --stanza=${stanza} --type=${type} backup
    '';

  mkService = container: stanza: type: {
    description = "pgBackRest ${type} backup (${stanza} DB → S3)";
    after = ["docker.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = mkBackup container stanza type;
    };
  };
in {
  # Scheduled pgBackRest backups. WAL archiving is continuous (PITR); these
  # add the periodic full/incr base backups so repo1-retention-full=2 prunes.
  #
  # scraper-db: full Sunday 01:00, incr Mon-Sat 02:00
  # logto-db:   full Sunday 01:30, incr Mon-Sat 02:30 (30-min offset avoids S3 contention)
  #
  # NOTE: logto-db backups require Dockerfile.logto-db to have a configured
  # pgbackrest stanza (pgbackrest.conf, stanza-create). The current Dockerfile
  # only installs pgbackrest; stanza config is a follow-up task.
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
