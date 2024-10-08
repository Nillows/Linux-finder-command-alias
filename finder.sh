####################################### INTUITIVE PROMPT BASED 'finder' #######################################

# MEANT TO BE ADDED TO .bashrc FILE

finder() {

    # Helper function to analyze and preprocess user input
    analyzeQuery() {
        IFS=' ' read -r -a queries <<< "$1"
        local processedString=""

        for query in "${queries[@]}"; do
            # If the query is enclosed in quotes (single or double)
            if [[ $query == \"*\" ]] && [[ $query == *\" ]]; then
                # Remove the leading and trailing double quotes and pass it as a literal
                query="${query%\"}"
                query="${query#\"}"
                processedString+=" -name \"$query\""
            elif [[ $query == \'*\' ]] && [[ $query == *\' ]]; then
                # Remove the leading and trailing single quotes and pass it as a literal
                query="${query%\'}"
                query="${query#\'}"
                processedString+=" -name '$query'"
            else
                # If there are no quotes, treat it as a normal input (with potential wildcards)
                processedString+=" -name \"$query\""
            fi
        done

        echo "$processedString"
    }

    # Start of user prompts

    echo "Please input the name of the directories or files you are looking for, separated by a space. Contain your search queries in quotes to perform searches with special characters."
    read userInput

    if [[ -z "$userInput" ]]; then
        echo "No response entered, exiting finder"
        return
    fi

    # Split user input into an array by spaces
    IFS=' ' read -r -a queries <<< "$userInput"

    # Setting directory to search

    echo "What directory do you want to search through? Leave empty to search through $PWD"
    read searchDirectory
    searchDirectory=${searchDirectory:-$PWD}  # Use PWD if no directory is specified

    echo "Searching in: $searchDirectory"
    echo -e "\nSubdirectories available to exclude:"
    (cd "$searchDirectory"; ls -d */)

    echo -e "\nPlease input any subdirectories you would like to EXCLUDE in your query from the list above. For multiple exclusions, please ensure an empty space is present between directory names or leave response empty to query all subdirectories."
    read exclusions

    exclusionString=""
    if [[ ! -z "$exclusions" ]]; then
        # Properly format exclusion string with relative path and wildcard
        exclusionString=$(echo "$exclusions" | awk -v dir="$searchDirectory" '{
            for (i=1; i<=NF; i++) {
                printf " ! -path \"%s/%s*\" ", dir, $i
            }
        }')
    fi

    for query in "${queries[@]}"; do
        searchString=$(analyzeQuery "$query")
        finalCommand="find $searchDirectory \( -type d -o -type f \) $searchString $exclusionString -print 2>/dev/null"

        echo -e "\n--- Searching for: $query ---"
        echo "Command Executed: $finalCommand"

        # Query Info to include exclusions
        if [[ ! -z "$exclusions" ]]; then
            searchMessage="Searching for '$query' in '$searchDirectory' excluding '$exclusions'"
        else
            searchMessage="Searching for '$query' in '$searchDirectory' in all sub directories."
        fi

        echo -e "\nQuery Info:"
        echo "$searchMessage"

        # Execute the find command with debugging options commented out
        ## set -x
        results=$(eval "$finalCommand" | awk 'END {print NR}')
        ## set +x

        echo -e "\n$results Result(s) Found!"

        if [ "$results" -gt 0 ]; then
            echo -e "\nResults:"
            eval "$finalCommand"
        else
            echo -e "\nNo results found for $query."
        fi
    done
}

alias finder=finder
