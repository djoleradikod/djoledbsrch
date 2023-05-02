#!/bin/bash

# Log file location
LOG_FILE="/tmp/JOsearch_db.log"

# Function to log messages
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a $LOG_FILE
}

# Ask for a string to search in the DB
echo "Enter the search string:"
read search_string

# Define the query to get table names excluding tables with 'task' in their names
table_query="SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_name NOT ILIKE '%task%';"

# Execute the query and store the result in a variable
tables=$(psql -h localhost -U postgres -d platform -t -c "$table_query" 2>>$LOG_FILE)

if [ -z "$tables" ]; then
    log "No tables found, exiting."
    exit 1
fi

# Loop through each table and search for the given string
result_file="/tmp/JOsearch_result_$(date +"%Y%m%d%H%M%S").txt"
touch $result_file

for table in $tables; do
    log "Searching in table: $table"
    search_query="SELECT * FROM $table WHERE to_tsvector('english', to_jsonb($table)) @@ plainto_tsquery('english', '$search_string');"
    psql -h localhost -U postgres -d platform -c "$search_query" 2>>$LOG_FILE | tee -a $result_file
done
