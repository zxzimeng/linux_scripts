#!/bin/bash

# Define directories to watch
REMOTE_FOLDER="/home/fox/bisvgoogledrive"
LOCAL_FOLDER="/home/fox/bisvgoogledrive_local"
COOLDOWN_FILE="/tmp/watch_dir_cooldown"
LOG_FILE="/home/fox/code/directory_changes.log"

# Check if cooldown file exists and if it's still within the cooldown period
if [ -f "$COOLDOWN_FILE" ]; then
    LAST_EXECUTION=$(cat "$COOLDOWN_FILE")
    CURRENT_TIME=$(date +%s)

    # Calculate the time since the last execution
    TIME_DIFF=$((CURRENT_TIME - LAST_EXECUTION))

    # If time since last execution is less than 60 seconds, exit
    if [ "$TIME_DIFF" -lt 60 ]; then
        exit 0
    fi
fi

# Log the current execution time
echo "$(date +%s)" > "$COOLDOWN_FILE"

# Using a flag to prevent multiple logs within the cooldown
CHANGE_DETECTED=0

# Monitor the remote folder for changes
inotifywait -m -r -e create,delete,modify,move "$REMOTE_FOLDER" | while read path action file; do
    if [ "$CHANGE_DETECTED" -eq 0 ]; then
        # Log the change
        echo "$(date): Directory changed: $action $file in $path" >> "$LOG_FILE"

        # Sync from the remote folder to the local folder
        {
            echo "Running rsync from $REMOTE_FOLDER to $LOCAL_FOLDER"
            rsync -avu --exclude="/home/fox/bisvgoogledrive/.Trash" "/home/fox/bisvgoogledrive/" "/home/fox/bisvgoogledrive_local/"
        } >> "$LOG_FILE" 2>&1

        # Set the flag to prevent additional logging
        CHANGE_DETECTED=1
    fi
done

# Reset the CHANGE_DETECTED flag after the cooldown
sleep 30
CHANGE_DETECTED=0
