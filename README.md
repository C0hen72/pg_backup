# PostgreSQL Backup Script

This repository contains a Bash script and a JSON configuration file for backing up PostgreSQL databases across multiple servers. The script supports:

- Full backups for specified databases or all databases on a server.
- Rotational backups with customizable retention policies.
- Logging of backup operations.

## Configuration File (`config.json`)
The `config.json` file defines the servers and databases to be backed up. Below is the structure and explanation of its fields:

### JSON Structure
```json
{
  "databases": [
    {
      "hostname": "127.0.0.1",
      "port": 5432,
      "username": "user1",
      "password": "password1",
      "backup_dir": "/backups/db1",
      "retain_days": 7,
      "db_names": ["db1", "db2"]
    },
    {
      "hostname": "192.168.1.10",
      "port": 5432,
      "username": "user2",
      "password": "password2",
      "backup_dir": "/backups/db2",
      "retain_days": -1
    }
  ]
}
```

### Fields Explanation
- **`hostname`**: The hostname or IP address of the PostgreSQL server.
- **`port`**: (Optional) The port on which the PostgreSQL server is listening. Defaults to `5432` if not specified.
- **`username`**: The username for connecting to the PostgreSQL server.
- **`password`**: The password for the specified user.
- **`backup_dir`**: The directory where backups will be stored. Each backup run will create a subdirectory with the current date.
- **`retain_days`**: The number of days to keep old backups. Use `-1` to retain all backups indefinitely.
- **`db_names`**: (Optional) An array of database names to back up. If omitted, all databases on the server will be backed up.

## Script Usage

### Prerequisites
- Install `jq` for parsing JSON:
  ```bash
  sudo apt update
  sudo apt install jq
  ```
- Ensure `pg_dump` and `psql` are installed and compatible with your PostgreSQL server versions.

### Running the Script
1. Place the `pg_backup.sh` script and `config.json` file in the same directory.
2. Make the script executable:
   ```bash
   chmod +x pg_backup.sh
   ```
3. Run the script:
   ```bash
   ./pg_backup.sh
   ```

### Logging
The script logs all operations to a file named `backup.log`. Each log entry includes a timestamp and details of the operation.

## Example Log File
```
2025-01-06T17:21:05 - Starting full backup for host: 127.0.0.1
2025-01-06T17:21:06 - Performing full backups for host: 127.0.0.1
2025-01-06T17:21:07 - Backup for host 127.0.0.1 completed. Databases: db1, db2
2025-01-06T17:21:07 - Removed backups older than 7 days in /backups/db1
2025-01-06T17:21:10 - Starting full backup for host: 192.168.1.10
2025-01-06T17:21:11 - Performing full backups for host: 192.168.1.10
2025-01-06T17:21:12 - Backup for host 192.168.1.10 completed. Databases: db3, db4
```

## Features
- **Selective Backups**: Specify databases to back up with `db_names`, or back up all databases if omitted.
- **Retention Policy**: Automatically delete old backups based on the `retain_days` setting.
- **Error Handling**: Skips servers or databases that encounter errors during the backup process.

## Contributing
Feel free to fork this repository and submit pull requests for improvements or additional features.

## License
This project is licensed under the MIT License.

