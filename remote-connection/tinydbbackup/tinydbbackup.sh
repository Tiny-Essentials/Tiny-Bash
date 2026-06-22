#!/bin/bash

# ==============================================================================
# Script Name: tinydbbackup.sh
# Description: Database backup and restore utility.
# Author: Yasmin Seidel / Assistant: Isabela
# ==============================================================================

# --- Color Definitions (Professional Terminal UI) ---
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# --- Configuration Setup ---
CONFIG_FILE="tiny-db-config.conf"
CURRENT_USER=$(whoami)

# Function to create config if it doesn't exist
init_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${YELLOW}[!] Configuration file not found. Creating default config...${NC}"
        cat <<EOF > "$CONFIG_FILE"
# Tiny DB Backup Configuration File
# Fill in the details below to automate authentication.

MONGO_HOST="localhost"
MONGO_PORT="27017"
MONGO_USER=""
MONGO_PASS=""
MONGO_AUTH_DB="admin"
EOF
        chmod 600 "$CONFIG_FILE" # Security: restrict access to the owner only
        echo -e "${GREEN}[+] Configuration created successfully: $CONFIG_FILE${NC}"
        echo -e "${CYAN}Please edit $CONFIG_FILE to pre-define your database credentials.${NC}"
        sleep 2
    fi
    # Load configuration
    source "$CONFIG_FILE"
}

# --- UI Components ---
draw_header() {
    clear
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${BOLD}          TINY DB BACKUP SYSTEM - v1.0.0                    ${NC}"
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${CYAN} Welcome, ${BOLD}$CURRENT_USER${NC}!${NC}"
    echo -e "${BLUE}------------------------------------------------------------${NC}"
}

draw_footer() {
    echo -e "${BLUE}------------------------------------------------------------${NC}"
    echo -e " Press any key to return to the menu..."
    read -n 1 -s
}

# --- MongoDB Logic ---

# Function to build the authentication string based on config
get_auth_params() {
    local params=""
    if [ -n "$MONGO_USER" ] && [ -n "$MONGO_PASS" ]; then
        params="--host=$MONGO_HOST --port=$MONGO_PORT --username=$MONGO_USER --password=$MONGO_PASS --authenticationDatabase=$MONGO_AUTH_DB"
    else
        params="--host=$MONGO_HOST --port=$MONGO_PORT"
    fi
    echo "$params"
}

mongodb_menu() {
    while true; do
        draw_header
        echo -e "${BOLD}DATABASE TYPE: MongoDB${NC}"
        echo -e "1) Export Database (Backup to single file)"
        echo -e "2) Import Database (Restore from file)"
        echo -e "3) Back to Main Menu"
        echo ""
        read -p " Select an option [1-3]: " mongo_choice

        case $mongo_choice in
            1)
                draw_header
                read -p " Enter the name of the database to backup: " db_name
                if [ -z "$db_name" ]; then
                    echo -e "${RED}[ERROR] Database name cannot be empty.${NC}"
                    sleep 2
                else
                    echo -e "${CYAN}[...] Starting backup for: $db_name...${NC}"
                    # Using --archive to create a single file as requested
                    mongodump --db "$db_name" --archive="${db_name}.archive" $(get_auth_params)
                    
                    if [ $? -eq 0 ]; then
                        echo -e "${GREEN}[SUCCESS] Backup completed: ${db_name}.archive${NC}"
                    else
                        echo -e "${RED}[ERROR] Backup failed. Check your connection/credentials.${NC}"
                    fi
                fi
                draw_footer
                ;;
            2)
                draw_header
                read -p " Enter the name of the archive file (e.g., dbname.archive): " archive_file
                if [ ! -f "$archive_file" ]; then
                    echo -e "${RED}[ERROR] File '$archive_file' not found.${NC}"
                    sleep 2
                else
                    # Extract database name from filename (stripping .archive)
                    target_db="${archive_file%.archive}"
                    echo -e "${CYAN}[...] Starting restore of $archive_file into: $target_db...${NC}"
                    mongorestore --nsInclude="${target_db}.*" --archive="$archive_file" $(get_auth_params)

                    if [ $? -eq 0 ]; then
                        echo -e "${GREEN}[SUCCESS] Restore completed successfully.${NC}"
                    else
                        echo -e "${RED}[ERROR] Restore failed.${NC}"
                    fi
                fi
                draw_footer
                ;;
            3)
                break
                ;;
            *)
                echo -e "${RED}Invalid option.${NC}"
                sleep 1
                ;;
        esac
    done
}

# --- Main Controller ---

main_menu() {
    while true; do
        draw_header
        echo -e " Select the type of database to manage:"
        echo -e " 1) MongoDB"
        echo -e " 2) Exit"
        echo ""
        read -p " Choice: " main_choice

        case $main_choice in
            1)
                # Check if mongodump/mongorestore are installed before proceeding
                if command -v mongodump &> /dev/null && command -v mongorestore &> /dev/null; then
                    mongodb_menu
                else
                    echo -e "${RED}[ERROR] MongoDB Tools (mongodump/mongorestore) not found in PATH.${NC}"
                    sleep 3
                fi
                ;;
            2)
                echo -e "${GREEN}Goodbye, $CURRENT_USER!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option.${NC}"
                sleep 1
                ;;
        esac
    done
}

# --- Execution Start ---
init_config
main_menu