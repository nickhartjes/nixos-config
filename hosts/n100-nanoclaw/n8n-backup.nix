{
  config,
  pkgs,
  ...
}: let
  docker = "${config.virtualisation.docker.package}/bin/docker";
  # Both workstation keys can recover a lost host; the host key permits
  # automated verification without storing another private key.
  recipients = pkgs.writeText "n8n-backup-recipients" ''
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPh1wLUOuMwH9tCGCRnEJ4lPqex1Ss2aaag6TKc/3hlD
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLBdQCyD8xsKKy5UIUfKS7l+Fl5RQ9yIMR3wGOfL90+
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDtWggZjgd5P93BkTrNUwaeyattrF4ZUgRvHC36fJNOF
  '';
in {
  systemd.services.n8n-backup = {
    description = "Encrypted, verified backup of n8n data and credential key";
    after = ["docker-n8n.service"];
    path = [pkgs.age pkgs.gnutar pkgs.sqlite pkgs.findutils];
    serviceConfig = {
      Type = "oneshot";
      StateDirectory = "n8n-backup";
      StateDirectoryMode = "0700";
      RuntimeDirectory = "n8n-backup";
      RuntimeDirectoryMode = "0700";
      UMask = "0077";
      TimeoutStartSec = "15min";
    };
    script = ''
      set -euo pipefail
      archive="$STATE_DIRECTORY/$(date -u +%Y-%m-%dT%H-%M-%SZ).tar.age"
      restart=false
      cleanup() {
        if "$restart"; then ${docker} start n8n >/dev/null; fi
        rm -f "$archive.partial"
      }
      trap cleanup EXIT
      running=$(${docker} inspect -f '{{.State.Running}}' n8n)
      if [ "$running" = true ]; then
        restart=true
        ${docker} stop --time 60 n8n >/dev/null
      fi
      # Stop writes so SQLite, its WAL and the credential key agree.
      tar -C /var/lib/n8n -cf - . | age -R ${recipients} -o "$archive.partial"
      if "$restart"; then
        ${docker} start n8n >/dev/null
        restart=false
      fi
      # Verify decryption and SQLite in a private, temporary directory.
      age -d -i /etc/ssh/ssh_host_ed25519_key "$archive.partial" |
        tar -C "$RUNTIME_DIRECTORY" -xf -
      test -s "$RUNTIME_DIRECTORY/config"
      test -s "$RUNTIME_DIRECTORY/database.sqlite"
      result=$(sqlite3 "$RUNTIME_DIRECTORY/database.sqlite" 'PRAGMA integrity_check;')
      test "$result" = ok
      mv "$archive.partial" "$archive"
      # Prune only after a new backup passes verification.
      find "$STATE_DIRECTORY" -name '*.tar.age' -type f -mtime +30 -delete
    '';
  };
  systemd.timers.n8n-backup = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "daily";
      RandomizedDelaySec = "30m";
      Persistent = true;
    };
  };
}
