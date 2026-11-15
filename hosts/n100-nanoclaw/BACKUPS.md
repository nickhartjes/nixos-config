# n8n recovery

`n8n-backup.timer` creates a daily encrypted archive under
`/var/lib/n8n-backup/`, retaining 30 days. It briefly stops a running n8n
container to capture its SQLite database, WAL and credential encryption key
together, and restarts it even if archiving fails. Before accepting an archive,
the job decrypts it and checks SQLite integrity in a private runtime directory.

The workstation's two SSH user keys and the N100 SSH host key can decrypt the
archives. Keep a workstation private key available separately from the N100.
Archives on the N100 alone do **not** protect against loss of that machine.
An off-machine destination still needs to be configured.

Inspect the latest run:

```sh
sudo systemctl start n8n-backup
sudo journalctl -u n8n-backup
sudo ls -lh /var/lib/n8n-backup
```

To restore, first decrypt an archive into a private staging directory using
`age -d -i /path/to/recovery-ssh-key backup.tar.age | tar -C staging -xf -`.
Check `sqlite3 staging/database.sqlite 'PRAGMA integrity_check;'` returns `ok`,
and confirm `staging/config` exists: it contains the key needed to decrypt
stored credentials. Keep this plaintext staging directory private.

Stop `docker-n8n.service`, preserve the current `/var/lib/n8n` directory for
rollback, and install the recovered files there, owned by UID/GID 1000 with
directory mode 0700. Restart `docker-n8n.service` and verify workflows and
credentials in the editor. Delete the plaintext staging copy afterward.
Do not restore over a running container or combine a database and config
from different backups.
