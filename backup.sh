#!/bin/bash

# EasyBackup - simple file backup to Telegram and Discord

while getopts "c:" opt; do
    case $opt in
    c)
        CONFIG_FILE="$OPTARG"
        ;;
    *)
        echo "Usage: $0 -c <config_file>"
        exit 1
        ;;
    esac
done

if [ -z "$CONFIG_FILE" ]; then
    echo "Error: Config file not specified. Use -c <config_file>"
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found at $CONFIG_FILE"
    exit 1
fi

get_config() {
    jq -r "$1 // \"\"" "$CONFIG_FILE"
}

BACKUP_DIR="/tmp/backup"
BACKUP_INTERVAL_TIME=$(get_config '.backup_interval_time')
BOT_TOKEN=$(get_config '.telegram.bot_token')
CHAT_ID=$(get_config '.telegram.chat_id')
DISCORD_BACKUP_URL=$(get_config '.discord.backup_url')

mapfile -t BACKUP_PATHS < <(jq -r '.paths[]?' "$CONFIG_FILE")

SLEEP_TIME=$((BACKUP_INTERVAL_TIME * 60))

SPLIT_PATH="$BACKUP_DIR/split"

TELEGRAM_MAX_SIZE=$((49 * 1024 * 1024))
DISCORD_MAX_SIZE=$((7 * 1024 * 1024))

mkdir -p "$BACKUP_DIR"
mkdir -p "$SPLIT_PATH"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - $1"
}

get_file_size() {
    local file_path="$1"
    if [[ -f "$file_path" ]]; then
        stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path" 2>/dev/null || echo 0
    else
        echo 0
    fi
}

split_file() {
    local file_path="$1"
    local max_size="$2"
    local platform="$3"

    local file_name=$(basename "$file_path")
    local split_dir="$SPLIT_PATH/${platform}_${file_name%.*}"

    mkdir -p "$split_dir"
    split -b "$max_size" "$file_path" "$split_dir/part_"

    local part_num=1
    for part in "$split_dir"/part_*; do
        if [[ -f "$part" ]]; then
            mv "$part" "$split_dir/${file_name}.part$(printf "%03d" $part_num)"
            ((part_num++))
        fi
    done

    echo "$split_dir"
}

send_backup_to_telegram() {
    local file_path="$1"
    local file_size=$(get_file_size "$file_path")

    if [[ $file_size -gt $TELEGRAM_MAX_SIZE ]]; then
        log "File size ($file_size bytes) exceeds Telegram limit. Splitting into parts..."
        local split_dir=$(split_file "$file_path" "$TELEGRAM_MAX_SIZE" "telegram")
        for part in "$split_dir"/*; do
            log "Sending $part to Telegram..."
            curl -s -F document=@"$part" "https://api.telegram.org/bot$BOT_TOKEN/sendDocument?chat_id=$CHAT_ID" >/dev/null
        done
        rm -rf "$split_dir"
    else
        log "Sending $(basename "$file_path") to Telegram..."
        curl -s -F document=@"$file_path" "https://api.telegram.org/bot$BOT_TOKEN/sendDocument?chat_id=$CHAT_ID" >/dev/null
    fi
}

send_backup_to_discord() {
    local file_path="$1"
    local file_size=$(get_file_size "$file_path")

    if [[ $file_size -gt $DISCORD_MAX_SIZE ]]; then
        log "File size ($file_size bytes) exceeds Discord limit. Splitting into parts..."
        local split_dir=$(split_file "$file_path" "$DISCORD_MAX_SIZE" "discord")
        for part in "$split_dir"/*; do
            log "Sending $part to Discord..."
            curl -s -F "file=@$part" "$DISCORD_BACKUP_URL" >/dev/null
        done
        rm -rf "$split_dir"
    else
        log "Sending $(basename "$file_path") to Discord..."
        curl -s -F "file=@$file_path" "$DISCORD_BACKUP_URL" >/dev/null
    fi
}

cleanup_temp_files() {
    rm -rf "$SPLIT_PATH"/telegram_* "$SPLIT_PATH"/discord_*
}

backup_files() {
    local file_name="files-$(date '+%Y-%m-%d_%H-%M-%S').tar.gz"
    local full_path="$BACKUP_DIR/$file_name"

    tar -czf "$full_path" "${BACKUP_PATHS[@]}"

    if [[ -f "$full_path" ]]; then
        local file_size=$(get_file_size "$full_path")
        log "Backup file created: $file_name (Size: $(($file_size / 1024 / 1024))MB)"

        send_backup_to_telegram "$full_path"
        send_backup_to_discord "$full_path"

        rm -f "$full_path"
        log "Backup file $file_name sent and cleaned up"
    else
        log "Error: Backup file was not created"
    fi

    cleanup_temp_files
}

trap cleanup_temp_files EXIT

log "EasyBackup started. Backup directory: $BACKUP_DIR"
log "Telegram size limit: $(($TELEGRAM_MAX_SIZE / 1024 / 1024))MB, Discord size limit: $(($DISCORD_MAX_SIZE / 1024 / 1024))MB"

while true; do
    log "Creating files backup..."
    backup_files
    log "Backup finished. Sleeping for $SLEEP_TIME seconds..."
    sleep "$SLEEP_TIME"
done
