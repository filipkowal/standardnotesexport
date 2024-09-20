#!/bin/bash

# Input JSON file
INPUT_FILE="notes_backup.json"

# Create directory for untagged notes
INBOX_DIR="Inbox"
mkdir -p "$INBOX_DIR"

# Parse all tags and notes, and save notes to corresponding tag folders
jq -c '.items[] | select(.content_type == "Tag")' "$INPUT_FILE" | while IFS= read -r tag; do
    TAG_TITLE=$(echo "$tag" | jq -r '.content.title')
    SAFE_TAG_TITLE=$(echo "$TAG_TITLE" | sed 's/[\/:*?"<>|]/_/g')  # Sanitize tag title
    mkdir -p "$SAFE_TAG_TITLE"

    echo "Processing tag: $TAG_TITLE"  # Print tag title for debugging

    # Gather all note UUIDs for this tag
    jq -r '.content.references[] | select(.content_type == "Note") | .uuid' <<< "$tag" | while IFS= read -r NOTE_UUID; do
        # Find the corresponding note
        NOTE=$(jq -c --arg uuid "$NOTE_UUID" '.items[] | select(.uuid == $uuid and .content_type == "Note")' "$INPUT_FILE")
        NOTE_TITLE=$(echo "$NOTE" | jq -r '.content.title')
        NOTE_TEXT=$(echo "$NOTE" | jq -r '.content.text')
        NOTE_CREATED_AT=$(echo "$NOTE" | jq -r '.created_at')
        NOTE_UPDATED_AT=$(echo "$NOTE" | jq -r '.updated_at')

        # Sanitize note title for use as a filename
        SAFE_NOTE_TITLE=$(echo "$NOTE_TITLE" | sed 's/[\/:*?"<>|]/_/g')

        if [ -n "$NOTE_TITLE" ]; then
            echo "Saving note '$SAFE_NOTE_TITLE' in folder '$SAFE_TAG_TITLE'"
            echo "$NOTE_TEXT" > "$SAFE_TAG_TITLE/$SAFE_NOTE_TITLE.txt"
            touch -d "$NOTE_CREATED_AT" "$SAFE_TAG_TITLE/$SAFE_NOTE_TITLE.txt"
            touch -d "$NOTE_UPDATED_AT" "$SAFE_TAG_TITLE/$SAFE_NOTE_TITLE.txt"
        else
            echo " - [Note not found: $NOTE_UUID]"
        fi
    done
done

# Now, process notes that don't belong to any tag and save them in Inbox
jq -c '.items[] | select(.content_type == "Note")' "$INPUT_FILE" | while IFS= read -r note; do
    UUID=$(echo "$note" | jq -r '.uuid')
    TITLE=$(echo "$note" | jq -r '.content.title')
    TEXT=$(echo "$note" | jq -r '.content.text')
    CREATED_AT=$(echo "$note" | jq -r '.created_at')
    UPDATED_AT=$(echo "$note" | jq -r '.updated_at')

    # Check if the note already exists in a tag folder
    if ! jq -e --arg uuid "$UUID" '.items[] | select(.content_type == "Tag") | .content.references[] | select(.uuid == $uuid)' "$INPUT_FILE" > /dev/null; then
        SAFE_TITLE=$(echo "$TITLE" | sed 's/[\/:*?"<>|]/_/g')
        echo "Saving note '$SAFE_TITLE' in Inbox"
        echo "$TEXT" > "$INBOX_DIR/$SAFE_TITLE.txt"
        touch -d "$CREATED_AT" "$INBOX_DIR/$SAFE_TITLE.txt"
        touch -d "$UPDATED_AT" "$INBOX_DIR/$SAFE_TITLE.txt"
    fi
done
