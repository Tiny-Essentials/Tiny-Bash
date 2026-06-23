# 🚀 Tiny DB Backup System

![Version](https://img.shields.io/badge/version-2.1.0-blue)
![Platform](https://img.shields.io/badge/platform-Linux-orange)

**Tiny DB Backup System** is a terminal-based utility designed for efficient multi-database management. It provides a streamlined, interactive interface to perform backups and restores for **MongoDB**, **MySQL/MariaDB**, and **PostgreSQL** instances, supporting single, batch, and full-instance operations.

---

## ✨ Key Features

*   🗄️ **Multi-Database Support**: Unified management for MongoDB, MySQL/MariaDB, and PostgreSQL.
*   📦 **Single Database Management**: Backup or restore a specific database into a single file (`.archive` for MongoDB, `.sql` for MySQL/Postgres).
*   🔄 **Advanced Batch Operations**: 
    *   **Batch Export**: Automatically list all databases and allow you to select multiple targets using index numbers (e.g., `1 3 4`).
    *   **Batch Import**: Restore multiple backup files in a single continuous session.
*   🌍 **Full Instance Backup**: Export all databases in a MongoDB instance into one consolidated archive.
*   🔍 **Database Discovery**: Automatically detects and lists all available databases for the selected engine.
*   ⚙️ **Automated Configuration**: Generates a secure `tiny-db-config.conf` file on its first run to automate authentication.
*   🛡️ **Security First**: Automatically sets restricted file permissions (`chmod 600`) on configuration files to protect sensitive credentials.

---

## 🛠️ Prerequisites

Ensure your environment has the necessary database client tools installed and available in your `$PATH`:

1.  **Linux/Unix Environment**: Designed for Bash shells.
2.  **MongoDB Tools**: `mongodump`, `mongorestore`, and `mongosh`.
3.  **MySQL/MariaDB Tools**: `mysqldump` and `mysql`.
4.  **PostgreSQL Tools**: `pg_dump` and `psql`.

---

## 🚀 Installation & Setup

1.  **Clone or Create the file**:
    Save the script as `tinydbbackup.sh`.

2.  **Grant Execution Permissions**:
    Open your terminal and run:
    ```bash
    chmod +x tinydbbackup.sh
    ```

3.  **Initial Execution**:
    Run the script for the first time:
    ```bash
    ./tinydbbackup.sh
    ```
    *On the first run, the system will automatically create a `tiny-db-config.conf` file.*

---

## 📝 Configuration

To automate your connections, edit the generated `tiny-db-config.conf` file. This prevents the need to type credentials manually and keeps them out of the command history.

```bash
nano tiny-db-config.conf
```

---

## 📖 Usage Guide

Once the script is running, follow the interactive menu:

### 1. Exporting Data
*   **Single DB**: Choose the database type, then select `Export Single Database` and type the name.
*   **All DBs (MongoDB)**: Choose `Export ALL Databases` to create one large `.archive` file.
*   **Batch Export (Multi-DB)**: 
    1. Select `Export Multiple Databases`.
    2. The system will fetch and display a numbered list of all databases.
    3. Enter the desired numbers separated by spaces (e.g., `1 2 5`) and press `Enter`.

### 2. Importing Data (Restore)
*   **Single File**: Provide the exact filename (e.g., `my_database.sql` or `my_db.archive`).
*   **Multiple Files**: Select `Import Databases`, then type the filenames separated by spaces (e.g., `db1.sql db2.sql`).

---

## 🛡️ Security & Best Practices

*   **Credential Safety**: Always use the `tiny-db-config.conf` file. Never hardcode passwords in scripts or pass them as direct command-line arguments.
*   **Verification**: After a batch operation, verify that the expected number of `.sql` or `.archive` files were created in your directory.
*   **Permissions**: If you move the script to another machine, ensure you re-apply `chmod 600` to your configuration file.