# standardnotesexport
Export notes from standardnotes backup file to .txt files in tag-based folder structure. 
The names of the files are the titles of notes, the `created_at` and `updated_at` metadata are preserved.

Works on Linux with bash shell. Tested on Ubuntu WSL.

Instructions:
1. Make a decrypted backup.
2. Save the file `Standard Notes Backup and Import File.txt` as `notes_backup.json`
3. Save the script from this project to a file in the same folder as the `notes_backup.json` file. Name this script: `extract_notes.sh`
4. Make the script executable and run it.
