#!/bin/bash

# Tiny SSH :3
# Idea by JasminDreasond
# Made with Google Gemini

ENV_FILE=".env"

# Function to generate a default .env file if it doesn't exist
create_default_env() {
    echo "Creating a default $ENV_FILE file..."
    cat << EOF > "$ENV_FILE"
# --- Tiny SSH Configuration File ---
REMOTE_HOST=""          # The remote host you want to access. Ex: server.example.com
PASSWORD_HOST=""        # The SSH password (Use sshpass -p)
DEFAULT_SSH_PORT=22     # Port through which the SSH tunnel will be established

# Default ports used when no arguments are given.
# You can define multiple ports here separated by space! 
# Examples: "8080 3000 9000" or custom mappings like "8080:80 3000:3000"
DEFAULT_HOST_PORT="8080"

# Local IP address for proxy listening. 
# Use "127.0.0.1" (localhost only) or "0.0.0.0" (all available IPs).
BIND_ADDRESS="127.0.0.1"

# Identity file path (leave empty "" to disable)
IDENTITY_FILE=""

# Set to "true" to open the server terminal, 
# or "false" to keep it as a quiet tunnel only (-N).
ENABLE_TERMINAL="true"

# Logging configuration
ENABLE_LOGS="false"     # Set to "true" to enable session logging
LOG_DIR="logs"          # Directory where session logs will be stored
EOF
    echo ">>> A template '$ENV_FILE' has been created. Please edit it with your credentials before running again! <<<"
    exit 0
}

# Load Environment Variables
if [ -f "$ENV_FILE" ]; then
    # shellcheck source=/dev/null
    source "$ENV_FILE"
else
    create_default_env
fi

# Function to display help instructions
show_help() {
    echo "========================================================================="
    echo "      Tiny SSH Tunneling Script - Help Guide :3"
    echo "========================================================================="
    echo "Usage:"
    echo "  $0 [ports...]"
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this beautiful help message and exit."
    echo ""
    echo "Examples of usage:"
    echo "  1. Default mode (No arguments):"
    echo "     $0"
    echo "     -> Automatically mirrors all ports configured in your .env inside"
    echo "        the DEFAULT_HOST_PORT variable (Current: $DEFAULT_HOST_PORT)."
    echo ""
    echo "  2. Overriding with specific ports via CLI:"
    echo "     $0 8080 3000 9000"
    echo "     -> Ignores the .env defaults and maps local 8080, 3000, and 9000."
    echo ""
    echo "  3. Custom local-to-remote mapping via CLI (Using ':'):"
    echo "     $0 8080:80 3000:3000"
    echo "     -> Maps local 8080 to remote 80, and local 3000 to remote 3000."
    echo ""
    echo "Note: Configure your environment inside the external '$ENV_FILE' file!"
    echo "========================================================================="
}

# Check for help flags
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# Function to check and install dependencies
check_dependencies() {
    local PACKAGES_TO_INSTALL=()

    if ! command -v ssh &> /dev/null; then
        PACKAGES_TO_INSTALL+=("openssh-client")
    fi

    if ! command -v sshpass &> /dev/null; then
        PACKAGES_TO_INSTALL+=("sshpass")
    fi

    if [ ${#PACKAGES_TO_INSTALL[@]} -ne 0 ]; then
        echo "Missing dependencies: ${PACKAGES_TO_INSTALL[*]}"
        read -p "Would you like to install them now? (y/n): " choice
        case "$choice" in 
            [Yy]* ) 
                echo "Updating and installing packages..."
                sudo apt update && sudo apt install -y "${PACKAGES_TO_INSTALL[@]}"
                ;;
            * ) 
                echo "Error: Dependencies are required to run this script."
                exit 1
                ;;
        esac
    fi
}

# Run dependency check
check_dependencies

# Safety check: Ensure REMOTE_HOST is defined before continuing
if [ -z "$REMOTE_HOST" ]; then
    echo "Error: REMOTE_HOST is not set in your $ENV_FILE file."
    echo "Please configure it before running the script."
    exit 1
fi

# Core logic: If no arguments are passed, split DEFAULT_HOST_PORT string into an array.
if [ $# -eq 0 ]; then
    # Unquoted assignment allows the shell to split strings by spaces into an array safely here
    # shellcheck disable=SC2206
    PORTS=($DEFAULT_HOST_PORT)
else
    PORTS=("$@")
fi

# Main execution logic wrapped into a function to allow clean log redirection if needed
run_ssh_tunnel() {
    # Build the multiple -L flags dynamically using a loop
    local TUNNEL_FLAGS=""
    echo "----------------------------------------"
    echo "Configuring Port Forwarding:"

    for PORT in "${PORTS[@]}"; do
        local L_PORT R_PORT
        # Supports syntax local_port:remote_port or just port (maps to same)
        if [[ "$PORT" == *":"* ]]; then
            L_PORT="${PORT%%:*}"
            R_PORT="${PORT#*:}"
        else
            L_PORT="$PORT"
            R_PORT="$PORT"
        fi
        
        echo " -> Mapped: $BIND_ADDRESS:$L_PORT => Remote:$R_PORT"
        TUNNEL_FLAGS="$TUNNEL_FLAGS -L $L_PORT:$BIND_ADDRESS:$R_PORT"
    done

    # Check if IdentityFile is provided
    local ID_OPT=""
    if [ -n "$IDENTITY_FILE" ]; then
        ID_OPT="-o IdentityFile=$IDENTITY_FILE"
    fi

    # Terminal vs Tunnel-only logic
    local N_FLAG="-N"
    if [ "$ENABLE_TERMINAL" = "true" ]; then
        N_FLAG=""
    fi

    echo "----------------------------------------"
    echo "Starting SSH Tunnel..."
    echo "Remote Host:             $REMOTE_HOST"
    echo "SSH Tunnel Gateway Port: $DEFAULT_SSH_PORT"
    [ -n "$IDENTITY_FILE" ] && echo "Identity File Path:      $IDENTITY_FILE"
    echo "Operation Mode:          $( [ "$ENABLE_TERMINAL" = "true" ] && echo "Interactive Terminal Session" || echo "Tunnel Only (Quiet)")"
    echo "----------------------------------------"

    # Executing the command with all generated tunnels
    sshpass -p "$PASSWORD_HOST" ssh $ID_OPT $N_FLAG $TUNNEL_FLAGS "$REMOTE_HOST" -p "$DEFAULT_SSH_PORT"
}

# Logger Logic wrapper
if [ "$ENABLE_LOGS" = "true" ]; then
    # Ensure log directory exists
    mkdir -p "$LOG_DIR"
    
    # Generate timestamped filename: YYYY-MM-DD_HH-MM-SS.log
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    LOG_FILE="$LOG_DIR/ssh_session_$TIMESTAMP.log"
    
    echo "Logging enabled. Saving session to: $LOG_FILE"
    
    # Run the tunnel function and pipe all output (stdout and stderr) to tee
    run_ssh_tunnel 2>&1 | tee "$LOG_FILE"
else
    # Run normally without logs
    run_ssh_tunnel
fi