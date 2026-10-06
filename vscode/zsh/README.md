# Oh My Zsh Setup for Visual Studio Code

A simple guide to installing Zsh with Oh My Zsh (featuring the default `robbyrussell` theme) and configuring it as your default terminal profile in Visual Studio Code.

---

## Prerequisites & Installation

Open your terminal and run the following commands to install Zsh, Git, and Oh My Zsh:

```bash
# Update package list and install dependencies
sudo apt update && sudo apt install zsh git curl -y

# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

During installation, if prompted to change your default shell to Zsh, you can select `Yes` (or skip if you only want to use it within VS Code).

---

## Setting Up Zsh in Visual Studio Code

To use Oh My Zsh inside VS Code without changing your system-wide terminal defaults, set Zsh as the default profile for VS Code's integrated terminal.

### Method 1: Via VS Code Settings (UI)

1. Open **Visual Studio Code**.
2. Press `Ctrl + ,` to open **Settings**.
3. In the search bar at the top, enter:

```text
terminal.integrated.defaultProfile.linux
```

4. Select **`zsh`** from the dropdown menu.

---

### Method 2: Via `settings.json`

1. Press `Ctrl + Shift + P` to open the Command Palette.
2. Type `Preferences: Open User Settings (JSON)` and press `Enter`.
3. Add the following line inside your settings JSON object:

```json
"terminal.integrated.defaultProfile.linux": "zsh"
```

---

## NVM & Node.js Environment Fix (Fix "command not found: npm / yarn")

If VS Code's integrated Zsh terminal returns `zsh: command not found: npm` or `yarn`, it usually means your NVM/Node environment variables are not being loaded automatically when opening a new shell session.

Open your `settings.json` in VS Code (`Ctrl + Shift + P` -> `Preferences: Open User Settings (JSON)`) and configure `terminal.integrated.profiles.linux` as follows:

```json
"terminal.integrated.profiles.linux": {
  "zsh": {
    "path": "/usr/bin/zsh",
    "args": ["-l"]
  }
}

```

---

## Verification

1. Open a new terminal in VS Code using `Ctrl + Shift + '` (or via **Terminal -> New Terminal**).
2. You should now see the `robbyrussell` prompt featuring Git branch status indicators (e.g., `➜  project git:(main) ✗`).
3. Run `node -v` and `npm -v` to ensure your binaries are fully recognized by Zsh.
