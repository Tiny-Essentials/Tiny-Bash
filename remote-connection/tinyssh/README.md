# 🚀 Tiny SSH Tunneling Script

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Platform](https://img.shields.io/badge/platform-Linux-orange)

**Tiny SSH** is a lightweight, automated utility designed to simplify SSH port forwarding (tunneling). Instead of typing long, complex SSH commands every time you need to access a remote service, Tiny SSH manages your configurations, dependencies, and multiple port mappings through a simple `.env` file and intuitive CLI arguments.

---

## ✨ Key Features

*   📝 **Smart Configuration**: Automatically generates a `.env` template on its first run.
*   📦 **Auto-Dependency Management**: Detects and offers to install required tools like `sshpass` and `openssh-client`.
*   🗺️ **Flexible Port Mapping**: 
    *   **Simple**: Maps local port to the same remote port (e.g., `8080`).
    *   **Custom**: Maps local port to a different remote port (e.g., `8080:80`).
*   🚀 **Batch Tunneling**: Open multiple tunnels simultaneously in a single command.
*   🖥️ **Dual Mode Operation**: 
    *   **Interactive**: Opens a terminal session.
    *   **Quiet (Tunnel Only)**: Runs in the background as a pure tunnel (`-N` flag).
*   📜 **Session Logging**: Option to record all tunnel activity into timestamped log files.
*   🔑 **Identity Support**: Full support for SSH Key files (`IdentityFile`).

---

## 🛠️ Prerequisites

*   **Linux/Unix Environment**: Optimized for Bash.
*   **Sudo Privileges**: Required only if the script needs to install missing dependencies (`sshpass`).

---

## 🚀 Installation & Setup

1.  **Clone or Create the file**:
    Save the script as `tinyssh.sh`.

2.  **Grant Execution Permissions**:
    ```bash
    chmod +x tinyssh.sh
    ```

3.  **Initial Run & Configuration**:
    Run the script for the first time:
    ```bash
    ./tinyssh.sh
    ```
    *The script will create a `.env` file. **You must edit this file** with your server details before running it again.*

---

## 📝 Configuration (`.env`)

Edit the `.env` file to define your connection parameters. This keeps your commands short and your credentials centralized.

| Parameter | Description |
| :--- | :--- |
| `REMOTE_HOST` | The IP or domain of your remote server. |
| `PASSWORD_HOST` | The SSH password (used by `sshpass`). |
| `DEFAULT_SSH_PORT` | The port the remote server listens on (default `22`). |
| `DEFAULT_HOST_PORT` | Ports to tunnel automatically (e.g., `"8080 3000"`). |
| `BIND_ADDRESS` | Where to listen locally (`127.0.0.1` for security, `0.0.0.0` for public). |
| `IDENTITY_FILE` | Path to your private SSH key (e.g., `~/.ssh/id_rsa`). |
| `ENABLE_TERMINAL` | `true` for interactive shell, `false` for quiet tunnel. |
| `ENABLE_LOGS` | `true` to save session output to the `logs/` directory. |

> [!WARNING]
> **Security Warning**: Since this script uses `sshpass` to handle passwords, ensure your `.env` file is protected with `chmod 600 .env` to prevent unauthorized access to your credentials.

---

## 📖 Usage Guide

### 1. Default Mode
Uses all settings defined in your `.env` file.
```bash
./tinyssh.sh
```

### 2. Overriding Ports via CLI
If you want to ignore the `.env` defaults and specify specific ports for this session:
```bash
# Maps local 8080, 3000, and 9000 to the same ports on remote
./tinyssh.sh 8080 3000 9000
```

### 3. Custom Local-to-Remote Mapping
Use the `:` syntax to map a local port to a different remote port:
```bash
# Maps local 8080 to remote 80
./tinyssh.sh 8080:80
```

### 4. Combining Both
You can mix simple ports and custom mappings:
```bash
# Maps local 3000 to remote 3000 AND local 8080 to remote 80
./tinyssh.sh 3000 8080:80
```

---

## 📋 Command Line Options

| Option | Description |
| :--- | :--- |
| `-h, --help` | Displays the built-in help guide. |
| `[ports...]` | Positional arguments to override `.env` port settings. |

---

## 📂 Pro Tip: Multi-Session Management (Symlinks)

If you manage multiple remote servers, you don't need multiple copies of the script. You can use a single central script and create "session folders" that contain only their specific `.env` files. This keeps your configurations organized and your logic centralized.

### 🏗️ Recommended Directory Structure

```text
~/ssh/
├── tinyssh.sh (The main, master script)
└── sessions/
    ├── friend1/
    │   ├── .env (Specific credentials for Friend 1)
    │   └── tinyssh.sh (Symlink to the master script)
    └── friend2/
        ├── .env (Specific credentials for Friend 2)
        └── tinyssh.sh (Symlink to the master script)
```

### 🛠️ Quick Setup

1. **Create your session directories:**
   ```bash
   mkdir -p ~/ssh/sessions/friend1 ~/ssh/sessions/friend2
   ```

2. **Create the unique `.env` for each session:**
   ```bash
   touch ~/ssh/sessions/friend1/.env
   touch ~/ssh/sessions/friend2/.env
   ```

3. **Create symbolic links (symlinks) to the master script:**
   ```bash
   ln -s ~/ssh/tinyssh.sh ~/ssh/sessions/friend1/tinyssh.sh
   ln -s ~/ssh/tinyssh.sh ~/ssh/sessions/friend2/tinyssh.sh
   ```

### 🚀 Usage

Simply navigate to the desired session folder and run the script. It will automatically detect and use the `.env` file located in that specific folder.

```bash
# Access Friend 1's server
cd ~/ssh/sessions/friend1
./tinyssh.sh

# Access Friend 2's server
cd ~/ssh/sessions/friend2
./tinyssh.sh
```

> [!IMPORTANT]
> **Technical Requirement**: For this method to work, your `tinyssh.sh` script must load the configuration using `source .env` (which looks in the current working directory) instead of searching for the `.env` relative to the script's own location.
```
