#!/bin/bash

# Extracts a key-value pair from the value in a dictionary of dictionaries
dict_of_dict_parse_entry() {
    : '
    Extracts a specific key-value pair from the structured value in a dictionary.

    Example Data Structure:
    declare -A EXTERNAL_DEPENDENCY_REPOS=(
        ["example1"]="name:example1,repo:https://github.com/example1.git,path:/path/to/example1"
        ["example2"]="name:example2,repo:https://github.com/example2.git,path:/path/to/example2"
    )

    Parameters:
        $1 (entry): The value string (e.g., "name:example1,repo:...")
        $2 (key): The key to extract (e.g., "name", "repo", "path")

    Example Usage:
        entry="${EXTERNAL_DEPENDENCY_REPOS[example1]}"
        result=$(dict_of_dict_parse_entry "$entry" "repo")
        echo $result  # Output: https://github.com/example1.git
    '
    local entry="$1"
    local key="$2"
    echo "$entry" | tr ',' '\n' | grep -E "^${key}:" | cut -d':' -f2-
}

# Adds or updates an entry in a dictionary of dictionaries
dict_of_dict_add_or_update_entry() {
    : '
    Adds or updates an entry in a dictionary of dictionaries.

    Parameters:
        $1 (dict_name): Name of the associative array.
        $2 (key): The key for the dictionary.
        $3 (entry): The structured value string (e.g., "name:...,repo:...,path:...")

    Example Usage:
        dict_of_dict_add_or_update_entry "EXTERNAL_DEPENDENCY_REPOS" "example3" "name:example3,repo:...,path:..."
    '
    local dict_name="$1"
    local key="$2"
    local entry="$3"
    eval "${dict_name}[$key]=\"$entry\""
}

# Removes an entry from a dictionary of dictionaries
dict_of_dict_remove_entry() {
    : '
    Removes an entry from a dictionary of dictionaries.

    Parameters:
        $1 (dict_name): Name of the associative array.
        $2 (key): The key to remove.

    Example Usage:
        dict_of_dict_remove_entry "EXTERNAL_DEPENDENCY_REPOS" "example2"
    '
    local dict_name="$1"
    local key="$2"
    eval "unset ${dict_name}[$key]"
}

# Lists all keys in a dictionary of dictionaries
dict_of_dict_list_keys() {
    : '
    Lists all keys in a dictionary of dictionaries.

    Parameters:
        $1 (dict_name): Name of the associative array.

    Example Usage:
        keys=$(dict_of_dict_list_keys "EXTERNAL_DEPENDENCY_REPOS")
        echo $keys  # Output: example1 example2
    '
    local dict_name="$1"
    eval "echo \${!${dict_name}[@]}"
}

# Iterates over all entries in a dictionary of dictionaries
dict_of_dict_iterate_entries() {
    : '
    Iterates over all entries in a dictionary of dictionaries and runs a command.

    Parameters:
        $1 (dict_name): Name of the associative array.
        $2 (command): Command to execute for each entry.

    Example Usage:
        dict_of_dict_iterate_entries "EXTERNAL_DEPENDENCY_REPOS" "
            name=$(dict_of_dict_parse_entry "$value" "name")
            repo=$(dict_of_dict_parse_entry "$value" "repo")
            echo "Processing $name from $repo"
        "
    '
    local dict_name="$1"
    local command="$2"
    eval "
        for key in \${!${dict_name}[@]}; do
            value=\${${dict_name}[\$key]}
            ${command}
        done
    "
}
