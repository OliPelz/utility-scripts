#!/bin/bash

# Extracts a key-value pair from an entry in an array of dictionaries
array_of_dict_parse_entry() {
    : '
    Extracts a specific key-value pair from a structured entry.

    Example Data Structure:
    declare -a EXTERNAL_DEPENDENCY_REPOS=(
        "name:example1,repo:https://github.com/example1.git,path:/path/to/example1"
        "name:example2,repo:https://github.com/example2.git,path:/path/to/example2"
    )

    Parameters:
        $1 (entry): The structured value string (e.g., "name:...,repo:...,path:...")
        $2 (key): The key to extract (e.g., "name", "repo", "path")

    Example Usage:
        entry="${EXTERNAL_DEPENDENCY_REPOS[0]}"
        result=$(array_of_dict_parse_entry "$entry" "repo")
        echo $result  # Output: https://github.com/example1.git
    '
    local entry="$1"
    local key="$2"
    echo "$entry" | tr ',' '\n' | grep -E "^${key}:" | cut -d':' -f2-
}

# Adds an entry to an array of dictionaries
array_of_dict_add_entry() {
    : '
    Adds an entry to an array of dictionaries.

    Parameters:
        $1 (array_name): Name of the array.
        $2 (entry): The structured value string (e.g., "name:...,repo:...,path:...")

    Example Usage:
        array_of_dict_add_entry "EXTERNAL_DEPENDENCY_REPOS" "name:example3,repo:...,path:..."
    '
    local array_name="$1"
    local entry="$2"
    eval "${array_name}+=(\"$entry\")"
}

# Removes an entry from an array of dictionaries
array_of_dict_remove_entry() {
    : '
    Removes an entry from an array of dictionaries.

    Parameters:
        $1 (array_name): Name of the array.
        $2 (entry): The structured value string to remove.

    Example Usage:
        array_of_dict_remove_entry "EXTERNAL_DEPENDENCY_REPOS" "name:example1,repo:...,path:..."
    '
    local array_name="$1"
    local entry="$2"
    eval "${array_name}=(\"\${${array_name}[@]/$entry}\")"
}

# Prints all entries in an array of dictionaries
array_of_dict_print_entries() {
    : '
    Prints all entries in an array of dictionaries.

    Parameters:
        $1 (array_name): Name of the array.

    Example Usage:
        array_of_dict_print_entries "EXTERNAL_DEPENDENCY_REPOS"
    '
    local array_name="$1"
    eval "
        for entry in \"\${${array_name}[@]}\"; do
            echo \"Entry: \$entry\"
        done
    "
}

# Iterates over an array of dictionaries
array_of_dict_iterate_entries() {
    : '
    Iterates over all entries in an array of dictionaries and runs a command.

    Parameters:
        $1 (array_name): Name of the array.
        $2 (command): Command to execute for each entry.

    Example Usage:
        array_of_dict_iterate_entries "EXTERNAL_DEPENDENCY_REPOS" "
            name=$(array_of_dict_parse_entry "$entry" "name")
            repo=$(array_of_dict_parse_entry "$entry" "repo")
            echo "Processing $name from $repo"
        "
    '
    local array_name="$1"
    local command="$2"
    eval "
        for entry in \"\${${array_name}[@]}\"; do
            ${command}
        done
    "
}
