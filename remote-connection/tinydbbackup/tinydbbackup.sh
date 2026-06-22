#!/bin/bash

# =============================================================================
# Script Name: tinydbbackup.sh
# Description: Multi-database backup and restore utility.
# Features: Single, All, and Multi-database export/import/restore.
# Author: Yasmin Seidel / Assistant: Isabela
# =============================================================================

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

# --- MongoDB ---
MONGO_HOST="localhost"
MONGO_PORT="27017"
MONGO_USER=""
MONGO_PASS=""
MONGO_AUTH_DB="admin"

# --- MySQL / MariaDB ---
MYSQL_HOST="localhost"
MYSQL_PORT="3306"
MYSQL_USER=""
MYSQL_PASS=""

# --- PostgreSQL ---
POSTGRES_HOST="localhost"
POSTGRES_PORT="5432"
POSTGRES_USER=""
POSTGRES_PASS=""
EOF
        chmod 600 "$CONFIG_FILE" # Security: restrict access to the owner only
        echo -e "${GREEN}[+] Configuration created successfully: $CONFIG_FILE${NC}"
        echo -e "${CYAN}Please edit $CONFIG_FILE to pre-define your credentials.${NC}"
        sleep 2
    fi
    # Load configuration
    source "$CONFIG_FILE"
}

# --- UI Components ---
draw_header() {
    clear
    echo -e "${BLUE}====================================================================${NC}"
    echo -e "${BOLD}          TINY DB BACKUP SYSTEM - v2.0.0                            ${NC}"
    echo -e "${BLUE}===================================================================${NC}"
    echo -e "${CYAN} Welcome, ${BOLD}$CURRENT_USER${NC}!${NC}"
    echo -e "${BLUE}--------------------------------------------------------------------${NC}"
}

draw_footer() {
    echo -e "${BLUE}--------------------------------------------------------------------${NC}"
    echo -e " Press any key to return to the menu..."
    read -n 1 -s
}

# =============================================================================
# MONGODB LOGIC
# =============================================================================

# Function to build the authentication string based on config
get_mongo_auth() {
    local params=""
    if [ -n "$MONGO_USER" ] && [ -n "$MONGO_PASS" ]; then
        params="--host=$MONGO_HOST --port=$MONGO_PORT --username=$MONGO_USER --password=$MONGO_PASS --authenticationDatabase=$MONGO_AUTH_DB"
    else
        params="--host=$MONGO_HOST --port=$MONGO_PORT"
    fi
    echo "$params"
}

get_mongo_db_list() {
    local auth=$(get_mongo_auth)
    # We try mongosh first (modern), then fallback to mongo (legacy)
    if command -v mongosh &> /dev/null; then
        mongosh $auth --quiet --eval "db.adminCommand('listDatabases').databases.map(d => d.name).join('\n')"
    elif command -v mongo &> /dev/null; then
        mongo $auth --quiet --eval "db.adminCommand('listDatabases').databases.map(d => d.name).join('\n')"
    else
        echo "ERROR"
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
        read -p " Select an option [1-7]: " choice

        case $choice in
            1)
                draw_header
                read -p " Enter database name: " db_name
                [ -z "$db_name" ] && echo -e "${RED}Invalid name.${NC}" || mongodump --db "$db_name" --archive="${db_name}.archive" $(get_mongo_auth)
                draw_footer ;;
            2)
                draw_header
                mongodump --archive="all_mongo_dbs.archive" $(get_mongo_auth)
                draw_footer ;;
            3)
                draw_header
                # Get list and store in array
                IFS=$'\n' read -d '' -r -a db_array < <(get_mongo_db_list)
                if [[ "${db_array[0]}" == "ERROR" ]]; then
                    echo -e "${RED}Connection Error.${NC}"
                else
                    for i in "${!db_array[@]}"; do echo -e "$((i+1))) ${db_array[$i]}"; done
                    read -p " Enter numbers (e.g. 1 2): " sel
                    read -ra idxs <<< "$sel"
                    for i in "${idxs[@]}"; do
                        real=$((i-1))
                        [ $real -ge 0 ] && mongodump --db "${db_array[$real]}" --archive="${db_array[$real]}.archive" $(get_mongo_auth)
                    done
                fi
                draw_footer ;;
            4)
                draw_header
                get_mongo_db_list
                draw_footer ;;
            5)
                draw_header
                read -p " Enter archive file: " file
                mongorestore --nsInclude="${file%.archive}.*" --archive="$file" $(get_mongo_auth)
                draw_footer ;;
            6)
                draw_header
                echo -e "${CYAN}Enter archive files separated by space:${NC}"
                read -p " Files: " selection
                read -ra files <<< "$selection"
                for f in "${files[@]}"; do
                    mongorestore --nsInclude="${f%.archive}.*" --archive="$f" $(get_mongo_auth)
                done
                draw_footer ;;
            7) break ;;
            *) echo -e "${RED}Invalid.${NC}"; sleep 1 ;;
        esac
    done
}

# =============================================================================
# MYSQL / MARIADB LOGIC
# =============================================================================

mysql_menu() {
    while true; do
        draw_header
        echo -e "${BOLD}DATABASE TYPE: MySQL / MariaDB${NC}"
        echo -e "1) Export Single Database"
        echo -e "2) Export ALL Databases"
        echo -e "3) List All Databases"
        echo -e "4) Import Single Database (Restore)"
        echo -e "5) Import Multiple Databases (Batch)"
        echo -e "6) Back to Main Menu"
        echo ""
        read -p " Select an option [1-6]: " choice

        case $choice in
            1)
                draw_header
                read -p " Enter database name: " db_name
                mysqldump -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$db_name" > "${db_name}.sql"
                [ $? -eq 0 ] && echo -e "${GREEN}[SUCCESS] ${db_name}.sql created.${NC}" || echo -e "${RED}[ERROR] Failed.${NC}"
                draw_footer ;;
            2)
                draw_header
                mysqldump -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" --all-databases > "all_mysql_dbs.sql"
                [ $? -eq 0 ] && echo -e "${GREEN}[SUCCESS] all_mysql_dbs.sql created.${NC}" || echo -e "${RED}[ERROR] Failed.${NC}"
                draw_footer ;;
            3)
                draw_header
                mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" -e "SHOW DATABASES;"
                draw_footer ;;
            4)
                draw_header
                read -p " Enter .sql file: " file
                read -p " Enter target database name: " db_name
                mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$db_name" < "$file"
                [ $? -eq 0 ] && echo -e "${GREEN}[SUCCESS] Restore complete.${NC}" || echo -e "${RED}[ERROR] Failed.${NC}"
                draw_footer ;;
            5)
                draw_header
                echo -e "${CYAN}Enter .sql files separated by space:${NC}"
                read -p " Files: " selection
                read -ra files <<< "$selection"
                for f in "${files[@]}"; do
                    if [ -f "$f" ]; then
                        read -p " Target DB for $f: " db_name
                        mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$db_name" < "$f"
                        [ $? -eq 0 ] && echo -e "${GREEN}[SUCCESS] $f restored.${NC}" || echo -e "${RED}[ERROR] $f failed.${NC}"
                    else
                        echo -e "${RED}[!] File $f not found.${NC}"
                    fi
                done
                draw_footer ;;
            6) break ;;
            *) echo -e "${RED}Invalid.${NC}"; sleep 1 ;;
        esac
    done
}

# =============================================================================
# POSTGRESQL LOGIC
# ===============================================================================

postgres_menu() {
    while true; do
        draw_header
        echo -e "${BOLD}DATABASE TYPE: PostgreSQL${NC}"
        echo -e "1) Export Single Database"
        echo -e "2) Export ALL Databases"
        echo -e "3) List All Databases"
        echo -e "4) Import Single Database (Restore)"
        echo -e "5) Import Multiple Databases (Batch)"
        echo -e "6) Back to Main Menu"
        echo ""
        read -p " Select an option [1-6]: " choice

        case $choice in
            1)
                draw_header
                read -p " Enter database name: " db_name
                # Using PGPASSWORD for non-interactive automation
                PGPASSWORD="$POSTGRES_PASS" pg_dump -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" "$db_name" > "${db_name}.sql"
                [ $? -eq 0 ] && echo -e "${GREEN}[SUCCESS] ${db_name}.sql created.${NC}" || echo -e "${RED}[ERROR] Failed.${NC}"
                draw_footer ;;
            2)
                draw_header
                PGPASSWORD="$POSTGRES_PASS" pg_dumpall -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" > "all_postgres_dbs.sql"
                [ $? -eq 0 ] && echo -e "${GREEN}[SUCCESS] all_postgres_dbs.sql created.${NC}" || echo -e "${RED}[ERROR] Failed.${NC}"
                draw_footer ;;
            3)
                draw_header
                PGPASSWORD="$POSTGRES_PASS" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -t -c "\l"
                draw_footer ;;
            4)
                draw_header
                read -p " Enter .sql file: " file
                read -p " Enter target database name: " db_name
                PGPASSWORD="$POSTGRES_PASS" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$db_name" -f "$file"
                [ $? -eq 0 ] && echo -e "${GREEN}[SUCCESS] Restore complete.${NC}" || echo -e "${RED}[ERROR] Failed.${NC}"
                draw_footer ;;
            5)
                draw_header
                echo -e "${CYAN}Enter .sql files separated by space:${NC}"
                read -p " Files: " selection
                read -ra files <<< "$selection"
                for f in "${files[@]}"; do
                    if [ -f "$f" ]; then
                        read -p " Target DB for $f: " db_name
                        PGPASSWORD="$POSTGRES_PASS" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$db_name" -f "$f"
                        [ $? -eq 0 ] && echo -e "${GREEN}[SUCCESS] $f restored.${NC}" || echo -e "${RED}[ERROR] $f failed.${NC}"
                    else
                        echo -e "${RED}[!] File $f not found.${NC}"
                    fi
                done
                draw_footer ;;
            6) break ;;
            *) echo -e "${RED}Invalid.${NC}"; sleep 1 ;;
        esac
    done
}

# --- Main Controller ---

main_menu() {
    while true; do
        draw_header
        echo -e " Select the type of database to manage:"
        echo -e " 1) MongoDB"
        echo -e " 2) MySQL / MariaDB (Test)"
        echo -e " 3) PostgreSQL (Test)"
        echo -e " 4) Exit"
        echo ""
        read -p " Choice: " main_choice

        case $main_choice in
            1)
                if command -v mongodump &> /dev/null; then mongodb_menu; else echo -e "${RED}[ERROR] MongoDB tools not found.${NC}"; sleep 2; fi ;;
            2)
                if command -v mysqldump &> /dev/null; then mysql_menu; else echo -e "${RED}[ERROR] MySQL tools not found.${NC}"; sleep 2; fi ;;
            3)
                if command -v pg_dump &> /dev/null; then postgres_menu; else echo -e "${RED}[ERROR] PostgreSQL tools not found.${NC}"; sleep 2; fi ;;
            4) echo -e "${GREEN}Tiny Goodbye, $CURRENT_USER!${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid option.${NC}"; sleep 1 ;;
        esac
    done
}

# --- Execution Start ---
init_config
main_menu