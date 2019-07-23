#!/bin/sh
BACKUP_DATE="$(date +%Y-%m-%d_%H:%M)"
BACKUP_FILE="/backups/"$BACKUP_DATE"_dump.tar.gz"
DB_FILE="/backups/db.sql"

# Dump Postgres database to file
pg_dump -h xnat-db -U xnat -d xnat -Fc > $DB_FILE

# compress and Copy backup to storage
tar -czf $BACKUP_FILE $DB_FILE
rm $DB_FILE

