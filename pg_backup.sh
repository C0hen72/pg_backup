#!/bin/bash

CONFIG_FILE="config.json"
LOG_FILE="backup.log"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Config file not found: $CONFIG_FILE" | tee -a "$LOG_FILE"
  exit 1
fi

# Lade die Datenbanken aus der JSON-Konfigurationsdatei
databases=$(jq -c '.databases[]' "$CONFIG_FILE")

# Backup-Funktion
do_full_backup() {
  local hostname=$1
  local port=$2
  local username=$3
  local password=$4
  local backup_dir=$5
  local retain_days=$6
  local db_names=$7

  echo "$(date +%Y-%m-%dT%H:%M:%S) - Starting full backup for host: $hostname" | tee -a "$LOG_FILE"

  # Setze das Passwort für die PostgreSQL-Verbindung
  export PGPASSWORD="$password"

  # Erstelle das Backup-Verzeichnis
  local final_backup_dir="$backup_dir/$(date +%Y-%m-%d)/"
  if ! mkdir -p "$final_backup_dir"; then
    echo "$(date +%Y-%m-%dT%H:%M:%S) - Error creating backup directory: $final_backup_dir. Skipping host: $hostname" | tee -a "$LOG_FILE"
    return
  fi

  # Bestimme die zu sichernden Datenbanken
  if [ "$db_names" != "null" ]; then
    databases=$(echo "$db_names" | jq -r '.[]')
  else
    databases=$(psql -h "$hostname" -p "$port" -U "$username" -At -c "SELECT datname FROM pg_database WHERE NOT datistemplate AND datallowconn" 2>/dev/null)
    if [ $? -ne 0 ]; then
      echo "$(date +%Y-%m-%dT%H:%M:%S) - Error connecting to PostgreSQL on host: $hostname. Skipping..." | tee -a "$LOG_FILE"
      return
    fi
  fi

  # Full Backups
  echo "$(date +%Y-%m-%dT%H:%M:%S) - Performing full backups for host: $hostname" | tee -a "$LOG_FILE"
  local backuped_databases=()
  for db in $databases; do
    if pg_dump -Fp -h "$hostname" -p "$port" -U "$username" "$db" | gzip > "$final_backup_dir/${db}.sql.gz"; then
      backuped_databases+=("$db")
    else
      echo "$(date +%Y-%m-%dT%H:%M:%S) - Error backing up database: $db on host: $hostname. Skipping..." | tee -a "$LOG_FILE"
    fi
  done

  echo "$(date +%Y-%m-%dT%H:%M:%S) - Backup for host $hostname completed. Databases: $(IFS=,; echo "${backuped_databases[*]}")" | tee -a "$LOG_FILE"

  # Backup-Aufbewahrung
  if [ "$retain_days" -ne -1 ]; then
    find "$backup_dir" -type d -mtime +$retain_days -exec rm -rf {} \;
    echo "$(date +%Y-%m-%dT%H:%M:%S) - Removed backups older than $retain_days days in $backup_dir" | tee -a "$LOG_FILE"
  else
    echo "$(date +%Y-%m-%dT%H:%M:%S) - Retaining all backups for $backup_dir" | tee -a "$LOG_FILE"
  fi
}

# Schleife durch alle Datenbanken in der JSON
for db_config in $databases; do
  hostname=$(echo "$db_config" | jq -r '.hostname')
  port=$(echo "$db_config" | jq -r '.port // 5432')
  username=$(echo "$db_config" | jq -r '.username')
  password=$(echo "$db_config" | jq -r '.password')
  backup_dir=$(echo "$db_config" | jq -r '.backup_dir')
  retain_days=$(echo "$db_config" | jq -r '.retain_days')
  db_names=$(echo "$db_config" | jq -c '.db_names // null')

  do_full_backup "$hostname" "$port" "$username" "$password" "$backup_dir" "$retain_days" "$db_names"
done

unset PGPASSWORD

echo "$(date +%Y-%m-%dT%H:%M:%S) - All backups completed." | tee -a "$LOG_FILE"
