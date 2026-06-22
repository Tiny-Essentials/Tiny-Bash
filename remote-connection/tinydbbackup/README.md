# 🚀 Tiny DB Backup System

![Version](https://img.shields.io/badge/version-1.2.0-blue)
![Platform](https://img.shields.io/badge/platform-Linux-orange)

**Tiny DB Backup System** is a terminal-based utility designed for efficient database backup. It provides a streamlined interface to perform backups and restores for MongoDB instances, supporting single, batch, and full-instance operations.

---

## ✨ Key Features

*   📦 **Single Database Management**: Backup or restore a specific database into a single `.archive` file.
*   🌍 **Full Instance Backup**: Export all databases in the instance into one consolidated archive.
*   🔄 **Batch Operations**: 
    *   **Export**: Select multiple databases from a list to backup simultaneously.
    *   **Restore**: Import multiple `.archive` files in a single session.
*   🔍 **Database Discovery**: Automatically detects and lists all available databases in your MongoDB instance.
*   ⚙️ **Automated Configuration**: Generates a secure configuration file on its first run to automate authentication.
*   🛡️ **Security First**: Automatically sets restricted file permissions (`chmod 600`) on configuration files to protect credentials.

---

## 🛠️ Prerequisites

Before running the script, ensure your environment meets the following requirements:

1.  **Linux/Unix Environment**: Designed for Bash shells.
2.  **MongoDB Database Tools**: Must have `mongodump` and `mongorestore` installed and available in your `$PATH`.
3.  **MongoDB Shell**: `mongosh` (recommended) or `mongo` must be installed to allow database listing.

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

To automate your connection, edit the generated `tiny-db-config.conf` file. This is essential if your MongoDB requires authentication.

```bash
nano tiny-db-config.conf
```

**Configuration Parameters:**
| Parameter | Description |
| :--- | :--- |
| `MONGO_HOST` | The IP address or hostname of your MongoDB server. |
| `MONGO_PORT` | The port number (default is `27017`). |
| `MONGO_USER` | Your database username (leave empty for no auth). |
| `MONGO_PASS` | Your database password (leave empty for no auth). |
| `MONGO_AUTH_DB` | The database used for authentication (usually `admin`). |

> [!IMPORTANT]
> **Security Note**: The configuration file is protected with `chmod 600`, meaning only your Linux user can read or write to it.

---

## 📖 Usage Guide

Once the script is running, follow the interactive menu:

### 1. Exporting Data
*   **Single DB**: Choose option `1`, then type the exact name of the database.
*   **All DBs**: Choose option `2` to create a massive `all_databases.archive` file.
*   **Batch Export**: Choose option `3`. The script will show a numbered list. Type the numbers you want (e.g., `1 3 5`) separated by spaces.

### 2. Importing Data (Restore)
*   **Single File**: Choose option `5` and provide the filename (e.g., `my_db.archive`).
*   **Multiple Files**: Choose option `6`. Type the names of all files you wish to restore, separated by spaces (e.g., `db1.archive db2.archive`).

---

## 📋 Menu Structure Reference

| Option | Action | Description |
| :--- | :--- | :--- |
| **1** | `Export Single` | Backup one specific database. |
| **2** | `Export ALL` | Backup the entire MongoDB instance. |
| **3** | `Export Batch` | Backup multiple selected databases. |
| **4** | `List DBs` | Display all databases found on the server. |
| **5** | `Import Single` | Restore from one `.archive` file. |
| **6** | `Import Batch` | Restore from multiple `.archive` files. |
| **7** | `Back` | Return to the main database selection menu. |

---

## 🛡️ Security & Best Practices

*   **Credentials**: Always use the `tiny-db-config.conf` file instead of passing passwords directly in commands to prevent them from appearing in process logs.
*   **File Integrity**: Always verify the existence of your `.archive` files before attempting a restore.
*   **Environment**: It is recommended to run this script in a controlled environment with appropriate user privileges.
