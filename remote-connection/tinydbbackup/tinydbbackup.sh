#!/bin/bash

# =============================================================================
# Script Name: tinydbbackup.sh
# Description: Database backup and restore utility.
# Features: Single, All, and Multi-database export/import/restore.
# Author: Yasmin Seidel / Assistant: Isabela
# ==============================================================================

# --- Color Definitions ---
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
    echo -e "${BLUE}====================================================================${NC}"
    echo -e "${BOLD}          TINY DB BACKUP SYSTEM - v1.1.0                            ${NC}"
    echo -e "${BLUE}===================================================================${NC}"
    echo -e "${CYAN} Welcome, ${BOLD}$CURRENT_USER${NC}!${NC}"
    echo -e "${BLUE}--------------------------------------------------------------------${NC}"
}

draw_footer() {
    echo -e "${BLUE}--------------------------------------------------------------------${NC}"
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

# Function to fetch and return list of databases
get_db_list() {
    local auth=$(get_auth_params)
    # We try mongosh first (modern), then fallback to mongo (legacy)
    if command -v mongosh &> /dev/null; then
        mongosh $auth --quiet --eval "db.adminCommand('listDatabases').databases.map(d => d.name).join('\n')"
    elif command -v mongo &> /dev/null; then
        mongo $auth --quiet --eval "db.adminCommand('listDatabases').databases.map(d => d.name).join('\n')"
    else
        echo "ERROR"
    fi
}

# Core function to perform a single backup
perform_backup() {
    local db_name=$1
    echo -e "${CYAN}[...] Backing up: $db_name...${NC}"
    mongodump --db "$db_name" --archive="${db_name}.archive" $(get_auth_params)
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[SUCCESS] Created: ${db_name}.archive${NC}"
        return 0
    else
        echo -e "${RED}[ERROR] Failed to backup: $db_name${NC}"
        return 1
    fi
}

# Core function to perform a single restore
perform_restore() {
    local archive_file=$1
    if [ ! -f "$archive_file" ]; then
        echo -e "${RED}[ERROR] File '$archive_file' not found.${NC}"
        return 1
    fi

    # Extract database name from filename (stripping .archive)
    local target_db="${archive_file%.archive}"
    echo -e "${CYAN}[...] Restoring $archive_file into: $target_db...${NC}"
    mongorestore --nsInclude="${target_db}.*" --archive="$archive_file" $(get_auth_params)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[SUCCESS] Restore completed for: $target_db${NC}"
        return 0
    else
        echo -e "${RED}[ERROR] Restore failed for: $target_db${NC}"
        return 1
    fi
}

mongodb_menu() {
    while true; do
        draw_header
        echo -e "${BOLD}DATABASE TYPE: MongoDB${NC}"
        echo -e "1) Export Single Database"
        echo -e "2) Export ALL Databases (Single Archive)"
        echo -e "3) Export Multiple Databases (Batch)"
        echo -e "4) List All Databases"
        echo -e "5) Import Single Database (Restore)"
        echo -e "6) Import Multiple Databases (Batch)"
        echo -e "7) Back to Main Menu"
        echo ""
        read -p " Select an option [1-7]: " mongo_choice

        case $mongo_choice in
            1)
                draw_header
                read -p " Enter database name: " db_name
                [ -z "$db_name" ] && echo -e "${RED}Invalid name.${NC}" || perform_backup "$db_name"
                draw_footer
                ;;
            2)
                draw_header
                echo -e "${CYAN}[...] Exporting all databases into one archive...${NC}"
                mongodump --archive="all_databases.archive" $(get_auth_params)
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}[SUCCESS] Created: all_databases.archive${NC}"
                else
                    echo -e "${RED}[ERROR] Export failed.${NC}"
                fi
                draw_footer
                ;;
            3)
                draw_header
                echo -e "${YELLOW}--- Available Databases ---${NC}"
                # Get list and store in array
                IFS=$'\n' read -d '' -r -a db_array < <(get_db_list)
                
                if [[ "${db_array[0]}" == "ERROR" ]]; then
                    echo -e "${RED}Could not connect to MongoDB.${NC}"
                else
                    for i in "${!db_array[@]}"; do
                        echo -e "$((i+1))) ${db_array[$i]}"
                    done
                    echo ""
                    echo -e "${CYAN}Enter numbers separated by space (e.g., 1 3 4):${NC}"
                    read -p " Selection: " selection
                    
                    # Convert selection to array
                    read -ra selected_indices <<< "$selection"
                    
                    for idx in "${selected_indices[@]}"; do
                        # Adjust for 0-based index
                        real_idx=$((idx-1))
                        if [[ $real_idx -ge 0 && $real_idx -lt ${#db_array[@]} ]]; then
                            perform_backup "${db_array[$real_idx]}"
                        else
                            echo -e "${RED}[!] Index $idx is invalid.${NC}"
                        fi
                    done
                fi
                draw_footer
                ;;
            4)
                draw_header
                echo -e "${YELLOW}--- Database List ---${NC}"
                db_list=$(get_db_list)
                if [[ "$db_list" == "ERROR" ]]; then
                    echo -e "${RED}Connection Error.${NC}"
                else
                    echo "$db_list"
                fi
                draw_footer
                ;;
            5)
                draw_header
                read -p " Enter archive file (e.g., dbname.archive): " archive_file
                perform_restore "$archive_file"
                draw_footer
                ;;
            6)
                draw_header
                echo -e "${CYAN}Enter archive files separated by space (e.g., db1.archive db2.archive):${NC}"
                read -p " Files: " selection
                read -ra selected_files <<< "$selection"

                if [ ${#selected_files[@]} -eq 0 ]; then
                    echo -e "${RED}[ERROR] No files provided.${NC}"
                else
                    for file in "${selected_files[@]}"; do
                        perform_restore "$file"
                    done
                fi
                draw_footer
                ;;
            7) break ;;
            *) echo -e "${RED}Invalid option.${NC}"; sleep 1 ;;
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
                if command -v mongodump &> /dev/null; then
                    mongodb_menu
                else
                    echo -e "${RED}[ERROR] MongoDB tools not found.${NC}"
                    sleep 3
                fi
                ;;
            2) echo -e "${GREEN}Tiny Goodbye, $CURRENT_USER!${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid option.${NC}"; sleep 1 ;;
        esac
    done
}

# --- Execution Start ---
init_config
main_menu