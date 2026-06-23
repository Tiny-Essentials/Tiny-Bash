#!/bin/bash

# =============================================================================
# Script Name: tinydbbackup.sh
# Description: Multi-database backup and restore utility with JSON API support.
# Features: Single, All, Batch, and Multi-database export/import/restore.
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
JSON_MODE=false

# Variables for API Mode
ACTION=""
DB_TYPE=""
DB_NAME=""
FILE_PATH=""

# --- JSON Response Helper ---
# This function ensures that when in JSON mode, we return machine-readable data.
# In terminal mode, it provides human-readable feedback.
respond_json() {
    local status=$1
    local message=$2
    local details=$3
    if [ "$JSON_MODE" = true ]; then
        echo "=========================JSON-RESULT========================="
        printf '{"status": "%s", "message": "%s", "details": %s}\n' "$status" "$message" "$details"
        echo "=========================JSON-RESULT========================="
        [ "$status" = "error" ] && exit 1 || exit 0
    else
        if [ "$status" = "success" ]; then
            echo -e "${GREEN}[SUCCESS]${NC} $message"
        else
            echo -e "${RED}[ERROR]${NC} $message"
        fi
    fi
}

# --- Help Command ---
show_help() {
    echo -e "${BLUE}====================================================================${NC}"
    echo -e "${BOLD}          TINY DB BACKUP SYSTEM - HELP & USAGE                      ${NC}"
    echo -e "${BLUE}====================================================================${NC}"
    echo -e ""
    echo -e "${BOLD}TERMINAL MODE (Interactive):${NC}"
    echo -e "  Run the script without arguments to enter the interactive menu."
    echo -e "  Example: $0"
    echo ""
    echo -e "${BOLD}JSON API MODE (Automated):${NC}"
    echo -e "  Use flags to execute specific tasks and receive JSON output."
    echo -e "  Required flags for API mode:"
    echo -e "    ${CYAN}--json${NC}             Enable JSON output mode."
    echo -e "    ${CYAN}--action <act>${NC}    Action to perform: 'backup' or 'restore'."
    echo -e "    ${CYAN}--db_type <type>${NC}  Database type: 'mongodb', 'mysql', or 'postgres'."
    echo -e "    ${CYAN}--db_name <name>${NC}  Database name (Required for backup)."
    echo -e "    ${CYAN}--file_path <path>${NC} Path to backup file (Required for restore)."
    echo ""
    echo -e "${BOLD}EXAMPLES:${NC}"
    echo -e "  ${YELLOW}Backup a MongoDB database:${NC}"
    echo -e "  $0 --json --action backup --db_type mongodb --db_name my_database"
    echo ""
    echo -e "  ${YELLOW}Restore a MySQL database:${NC}"
    echo -e "  $0 --json --action restore --db_type mysql --db_name target_db --file_path ./backup.sql"
    echo ""
    echo -e "  ${YELLOW}Show this help:${NC}"
    echo -e "  $0 --help"
    echo -e "${BLUE}====================================================================${NC}"
}

# --- Dependency Check ---
check_dependencies() {
    if [ "$JSON_MODE" = true ] && ! command -v jq &> /dev/null; then
        echo '{"status": "error", "message": "Dependency \"jq\" is required for JSON mode."}'
        exit 1
    fi
}

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
    echo -e "${BOLD}          TINY DB BACKUP SYSTEM - v2.1.0                            ${NC}"
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
# CORE LOGIC FUNCTIONS
# =============================================================================

# --- MONGODB CORE ---
get_mongo_auth() {
    local params=""
    if [ -n "$MONGO_USER" ] && [ -n "$MONGO_PASS" ]; then
        params="--host=$MONGO_HOST --port=$MONGO_PORT --username=$MONGO_USER --password=$MONGO_PASS --authenticationDatabase=$MONGO_AUTH_DB"
    else
        params="--host=$MONGO_HOST --port=$MONGO_PORT"
    fi
    echo "$params"
}

do_mongo_backup() {
    local db_name=$1
    local target_file="${db_name}.archive"
    mongodump --db "$db_name" --archive="$target_file" $(get_mongo_auth)
    if [ $? -eq 0 ]; then
        respond_json "success" "MongoDB backup completed" "{\"db\": \"$db_name\", \"file\": \"$target_file\"}"
    else
        respond_json "error" "MongoDB backup failed" "{\"db\": \"$db_name\"}"
    fi
}

do_mongo_restore() {
    local file=$1
    local db_name="${file%.archive}"
    if [ ! -f "$file" ]; then respond_json "error" "File not found" "{\"file\": \"$file\"}"; fi
    mongorestore --nsInclude="${db_name}.*" --archive="$file" $(get_mongo_auth)
    if [ $? -eq 0 ]; then
        respond_json "success" "MongoDB restore completed" "{\"db\": \"$db_name\", \"file\": \"$file\"}"
    else
        respond_json "error" "MongoDB restore failed" "{\"db\": \"$db_name\"}"
    fi
}

# --- MYSQL CORE ---
do_mysql_backup() {
    local db_name=$1
    local target_file="${db_name}.sql"
    mysqldump -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$db_name" > "$target_file"
    if [ $? -eq 0 ]; then
        respond_json "success" "MySQL backup completed" "{\"db\": \"$db_name\", \"file\": \"$target_file\"}"
    else
        respond_json "error" "MySQL backup failed" "{\"db\": \"$db_name\"}"
    fi
}

do_mysql_restore() {
    local file=$1
    local db_name=$2
    if [ ! -f "$file" ]; then respond_json "error" "File not found" "{\"file\": \"$file\"}"; fi
    mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$db_name" < "$file"
    if [ $? -eq 0 ]; then
        respond_json "success" "MySQL restore completed" "{\"db\": \"$db_name\", \"file\": \"$file\"}"
    else
        respond_json "error" "MySQL restore failed" "{\"db\": \"$db_name\"}"
    fi
}

# --- POSTGRES CORE ---
do_postgres_backup() {
    local db_name=$1
    local target_file="${db_name}.sql"
    PGPASSWORD="$POSTGRES_PASS" pg_dump -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" "$db_name" > "$target_file"
    if [ $? -eq 0 ]; then
        respond_json "success" "PostgreSQL backup completed" "{\"db\": \"$db_name\", \"file\": \"$target_file\"}"
    else
        respond_json "error" "PostgreSQL backup failed" "{\"db\": \"$db_name\"}"
    fi
}

do_postgres_restore() {
    local file=$1
    local db_name=$2
    if [ ! -f "$file" ]; then respond_json "error" "File not found" "{\"file\": \"$file\"}"; fi
    PGPASSWORD="$POSTGRES_PASS" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$db_name" -f "$file"
    if [ $? -eq 0 ]; then
        respond_json "success" "PostgreSQL restore completed" "{\"db\": \"$db_name\", \"file\": \"$file\"}"
    else
        respond_json "error" "PostgreSQL restore failed" "{\"db\": \"$db_name\"}"
    fi
}

# =============================================================================
# BATCH EXPORT LOGIC (Terminal Mode Only)
# =============================================================================

do_mongo_batch_export() {
    draw_header
    echo -e "${CYAN}Fetching database list...${NC}"
    # Get list of DB names using mongosh
    mapfile -t dbs < <(mongosh $(get_mongo_auth) --quiet --eval "db.adminCommand('listDatabases').databases.forEach(d => print(d.name))")

    if [ ${#dbs[@]} -eq 0 ]; then
        echo -e "${RED}No databases found.${NC}"
        draw_footer
        return
    fi

    echo -e "${BOLD}Available Databases:${NC}"
    for i in "${!dbs[@]}"; do
        echo -e "$((i+1))) ${dbs[$i]}"
    done
    echo ""
    read -p "Enter numbers (e.g. 1 2): " selection
    read -ra choices <<< "$selection"

    for choice in "${choices[@]}"; do
        idx=$((choice-1))
        if [[ $idx -ge 0 && $idx -lt ${#dbs[@]} ]]; then
            do_mongo_backup "${dbs[$idx]}"
        else
            echo -e "${RED}[!] Invalid index: $choice${NC}"
        fi
    done
    draw_footer
}

do_mysql_batch_export() {
    draw_header
    echo -e "${CYAN}Fetching database list...${NC}"
    # -N: skip headers, -s: silent/raw
    mapfile -t dbs < <(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" -N -s -e "SHOW DATABASES;")

    if [ ${#dbs[@]} -eq 0 ]; then
        echo -e "${RED}No databases found.${NC}"
        draw_footer
        return
    fi

    echo -e "${BOLD}Available Databases:${NC}"
    for i in "${!dbs[@]}"; do
        echo -e "$((i+1))) ${dbs[$i]}"
    done
    echo ""
    read -p "Enter numbers (e.g. 1 2): " selection
    read -ra choices <<< "$selection"

    for choice in "${choices[@]}"; do
        idx=$((choice-1))
        if [[ $idx -ge 0 && $idx -lt ${#dbs[@]} ]]; then
            do_mysql_backup "${dbs[$idx]}"
        else
            echo -e "${RED}[!] Invalid index: $choice${NC}"
        fi
    done
    draw_footer
}

do_postgres_batch_export() {
    draw_header
    echo -e "${CYAN}Fetching database list...${NC}"
    # -t: tuples only, -A: unaligned (clean list)
    mapfile -t dbs < <(PGPASSWORD="$POSTGRES_PASS" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -t -A -c "\l")

    if [ ${#dbs[@]} -eq 0 ]; then
        echo -e "${RED}No databases found.${NC}"
        draw_footer
        return
    fi

    echo -e "${BOLD}Available Databases:${NC}"
    for i in "${!dbs[@]}"; do
        echo -e "$((i+1))) ${dbs[$i]}"
    done
    echo ""
    read -p "Enter numbers (e.g. 1 2): " selection
    read -ra choices <<< "$selection"

    for choice in "${choices[@]}"; do
        idx=$((choice-1))
        if [[ $idx -ge 0 && $idx -lt ${#dbs[@]} ]]; then
            do_postgres_backup "${dbs[$idx]}"
        else
            echo -e "${RED}[!] Invalid index: $choice${NC}"
        fi
    done
    draw_footer
}

# =============================================================================
# JSON API PROCESSOR
# =============================================================================

process_api_logic() {
    case "$ACTION" in
        "backup")
            if [[ -z "$DB_NAME" ]]; then respond_json "error" "db_name is required for backup"; fi
            case "$DB_TYPE" in
                "mongodb") do_mongo_backup "$DB_NAME" ;;
                "mysql")   do_mysql_backup "$DB_NAME" ;;
                "postgres") do_postgres_backup "$DB_NAME" ;;
                *)         respond_json "error" "Unsupported db_type for backup" ;;
            esac
            ;;
        "restore")
            if [[ -z "$FILE_PATH" || -z "$DB_NAME" ]]; then respond_json "error" "file_path and db_name are required for restore"; fi
            case "$DB_TYPE" in
                "mongodb") do_mongo_restore "$FILE_PATH" ;;
                "mysql")   do_mysql_restore "$FILE_PATH" "$DB_NAME" ;;
                "postgres") do_postgres_restore "$FILE_PATH" "$DB_NAME" ;;
                *)         respond_json "error" "Unsupported db_type for restore" ;;
            esac
            ;;
        *)
            respond_json "error" "Invalid action. Use 'backup' or 'restore'."
            ;;
    esac
}

# =============================================================================
# MONGODB MENU (Terminal Mode)
# =============================================================================

mongodb_menu() {
    while true; do
        draw_header
        echo -e "${BOLD}DATABASE TYPE: MongoDB${NC}"
        echo -e "1) Export Single Database"
        echo -e "2) Export ALL Databases"
        echo -e "3) Export Multiple Databases"
        echo -e "4) List All Databases"
        echo -e "5) Import Databases"
        echo -e "6) Back to Main Menu"
        echo ""
        read -p " Select an option [1-6]: " choice
        case $choice in
            1) draw_header; read -p " Enter database name: " db_name; do_mongo_backup "$db_name"; draw_footer ;;
            2) draw_header; mongodump --archive="all_mongo_dbs.archive" $(get_mongo_auth); draw_footer ;;
            3) do_mongo_batch_export ;;
            4) draw_header; mongosh $(get_mongo_auth) --quiet --eval "db.adminCommand('listDatabases').databases.map(d => d.name).join('\n')"; draw_footer ;;
            5) 
                draw_header
                echo -e "${CYAN}Enter archive files separated by space:${NC}"
                read -p " Files: " selection
                read -ra files <<< "$selection"
                for f in "${files[@]}"; do do_mongo_restore "$f"; done
                draw_footer ;;
            6) break ;;
            *) echo -e "${RED}Invalid.${NC}"; sleep 1 ;;
        esac
    done
}

# =============================================================================
# MYSQL / MARIADB MENU (Terminal Mode)
# =============================================================================

mysql_menu() {
    while true; do
        draw_header
        echo -e "${BOLD}DATABASE TYPE: MySQL / MariaDB${NC}"
        echo -e "1) Export Single Database"
        echo -e "2) Export Multiple Databases"
        echo -e "3) List All Databases"
        echo -e "4) Import Databases"
        echo -e "5) Back to Main Menu"
        echo ""
        read -p " Select an option [1-5]: " choice
        case $choice in
            1) draw_header; read -p " Enter database name: " db_name; do_mysql_backup "$db_name"; draw_footer ;;
            2) do_mysql_batch_export ;;
            3) draw_header; mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" -e "SHOW DATABASES;"; draw_footer ;;
            4) 
                draw_header
                echo -e "${CYAN}Enter .sql files separated by space:${NC}"
                read -p " Files: " selection
                read -ra files <<< "$selection"
                for f in "${files[@]}"; do
                    if [ -f "$f" ]; then
                        read -p " Target DB for $f: " db_name
                        do_mysql_restore "$f" "$db_name"
                    else
                        echo -e "${RED}[!] File $f not found.${NC}"
                    fi
                done
                draw_footer ;;
            5) break ;;
            *) echo -e "${RED}Invalid.${NC}"; sleep 1 ;;
        esac
    done
}

# ===============================================================================
# POSTGRESQL MENU (Terminal Mode)
# ===============================================================================

postgres_menu() {
    while true; do
        draw_header
        echo -e "${BOLD}DATABASE TYPE: PostgreSQL${NC}"
        echo -e "1) Export Single Database"
        echo -e "2) Export Multiple Databases"
        echo -e "3) List All Databases"
        echo -e "4) Import Databases"
        echo -e "5) Back to Main Menu"
        echo ""
        read -p " Select an option [1-5]: " choice
        case $choice in
            1) draw_header; read -p " Enter database name: " db_name; do_postgres_backup "$db_name"; draw_footer ;;
            2) do_postgres_batch_export ;;
            3) draw_header; PGPASSWORD="$POSTGRES_PASS" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -t -c "\l"; draw_footer ;;
            4) 
                draw_header
                echo -e "${CYAN}Enter .sql files separated by space:${NC}"
                read -p " Files: " selection
                read -ra files <<< "$selection"
                for f in "${files[@]}"; do
                    if [ -f "$f" ]; then
                        read -p " Target DB for $f: " db_name
                        do_postgres_restore "$f" "$db_name"
                    else
                        echo -e "${RED}[!] File $f not found.${NC}"
                    fi
                done
                draw_footer ;;
            5) break ;;
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
        echo -e " 2) MySQL / MariaDB (Not tested)"
        echo -e " 3) PostgreSQL (Not tested)"
        echo -e " 4) Exit"
        echo ""
        read -p " Choice: " main_choice
        case $main_choice in
            1) if command -v mongodump &> /dev/null; then mongodb_menu; else echo -e "${RED}Error: MongoDB tools not found.${NC}"; sleep 2; fi ;;
            2) if command -v mysqldump &> /dev/null; then mysql_menu; else echo -e "${RED}Error: MySQL tools not found.${NC}"; sleep 2; fi ;;
            3) if command -v pg_dump &> /dev/null; then postgres_menu; else echo -e "${RED}Error: PostgreSQL tools not found.${NC}"; sleep 2; fi ;;
            4) echo -e "${GREEN}Tiny Goodbye, $CURRENT_USER!${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid option.${NC}"; sleep 1 ;;
        esac
    done
}

# --- Execution Start ---
init_config
check_dependencies

# --- Argument Parsing Engine ---
while [[ $# -gt 0 ]]; do
    case $1 in
        --json)
            JSON_MODE=true
            shift
            ;;
        --action)
            ACTION="$2"
            shift 2
            ;;
        --db_type)
            DB_TYPE="$2"
            shift 2
            ;;
        --db_name)
            DB_NAME="$2"
            shift 2
            ;;
        --file_path)
            FILE_PATH="$2"
            shift 2
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown argument: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# --- Main Decision Logic ---
if [ "$JSON_MODE" = true ]; then
    if [[ -z "$ACTION" ]]; then
        respond_json "error" "Missing required argument: --action"
    else
        process_api_logic
    fi
else
    main_menu
fi