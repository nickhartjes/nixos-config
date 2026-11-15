# PostgreSQL backup checks

The full/incremental timers run `pgbackrest check` before creating a backup.
Missing containers, Docker errors, repository failures and failed backups
fail the unit and trigger a Slack notification through the existing
Alertmanager webhook credential. Check the notification service journal if
delivery fails. A stopped stack no longer silently skips its scheduled backup.

Inspect repository metadata without restoring into a live database:

```sh
sudo docker exec -u postgres scraper-db pgbackrest --stanza=scraper info
sudo docker exec -u postgres logto-db pgbackrest --stanza=logto info
sudo journalctl -u 'pgbackrest-*'
```

The Logto image in the scraper repository supplies its pgBackRest config and
stanza setup. This repository checks that setup at backup time; it does not
manage the image's implementation.

A successful `check` or backup is not a restore drill. Periodically restore
the latest backup with the matching PostgreSQL major version into an isolated
data directory and isolated server, using a read-only copy of the repository
credentials where possible. Do not mount production data or permit the test
server to archive WAL into the production stanza. Verify startup, expected
databases and representative application queries, then remove the isolated
test data. This drill requires access to the running deployment and backup
repository and is not performed by the configuration checks.
