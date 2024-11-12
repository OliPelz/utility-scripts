# function collection which do their task idempotent
# in a nutshell the functions in here are ported ansible modules
# like lineinfile etc

############################################################
#
# URL based functions
#
############################################################

get_url() {
   : '
      Get URL

      ShortDesc: This function downloads a file from a specified URL.

      Description:
      This function retrieves a file from the internet using the provided URL.
      It checks if the target file already exists and prompts the user for
      overwriting it if it has changed.

      Parameters:
      - url: The URL from which to download the file.
      - output_file: The file path where the downloaded content will be saved
        (optional; defaults to the name derived from the URL).

      Returns:
      - 0: Success
      - 1: Failure (if the URL is invalid or download fails)

      Example Usage:
      get_url "https://example.com/file.txt" "localfile.txt"
  '

    local url=""
    local dest=""
    local overwrite=false

    # Define usage message
    local usage="Usage: get_url -u <url> -d <destination_file> [-o] [-h]
  -h                : Show this help message
  -u <url>          : URL to fetch the file from
  -d <destination_file>: Local file to save the downloaded content
  -o                : Prompt for overwrite if the file has changed"

# Parse options
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -h|--help)
                echo $usage
                return 0
                ;;
            -u|--url)
                url="$2"
                shift 2
                ;;
            -d|--destination)
                dest="$2"
                shift 2
                ;;
            -o|--overwrite)
                overwrite=1
                shift
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
    done

    # Check required parameters
    if [[ -z "$url" || -z "$dest" ]]; then
        echo "Both URL and destination file are required."
        echo "$usage"
        return 1
    fi

    # Fetch the file
    echo "Fetching $url..."
    temp_file=$(mktemp)

    if curl -fsSL "$url" -o "$temp_file"; then
        # Check if destination file exists
        if [[ -f "$dest" ]]; then
            # Compare checksums to see if the file has changed
            if ! cmp -s "$temp_file" "$dest"; then
                echo "File has changed."
                echo "Current destination file: $dest"
                echo "New file: $temp_file"

                if $overwrite; then
                    read -p "Do you want to overwrite $dest? (y/n): " answer
                    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
                        mv "$temp_file" "$dest"
                        echo "File updated: $dest"
                    else
                        echo "Keeping the original file: $dest"
                        rm "$temp_file"
                    fi
                else
                    echo "Keeping the original file: $dest"
                    rm "$temp_file"
                fi
            else
                echo "File has not changed. No update needed."
                rm "$temp_file"
            fi
        else
            echo "Downloading to $dest..."
            mv "$temp_file" "$dest"
            echo "File downloaded: $dest"
        fi
    else
        echo "Failed to fetch $url"
        rm "$temp_file"
        return 1
    fi

    return 0
}

############################################################
#
# file manipulation -  sed, awk, grep stuff
#
############################################################




lineinfile() {
    : '
        Line In File

        ShortDesc: This function ensures a specific line is present in a file.

        Description:
        This function checks for a specified line in a given file. If the line does not exist,
        it adds it to the file. If the line already exists, it can be updated based on parameters.
        The function also allows for specifying whether to create the file if it does not exist.
        Additionally, you can choose to add the line at the beginning or end of the file.

        Parameters:
        - -f <file>: The path to the file to be modified.
        - -l <line>: The line of text to ensure is present in the file.
        - -a: Add the line if it doesn’t already exist.
        - -r: Remove the line if it exists.
        - -p <position>: Add position - either "beginning" or "end" (optional; defaults to "end").
        - -d disable idempotency, by default we DO idempotency. This will add regardless if exists or not
        - -o <output_file>: Copy output to a specified file instead of modifying the original.

        Returns:
        - 0: Success
        - 1: Failure (if file operations fail or the file cannot be created)

        Example Usage:
        lineinfile -f "example.txt" -l "This is a new line." -a -p beginning
    '

    local file line action disable_idempotency="false" output_file position="end"

    # Parse arguments
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -f) file="$2"; shift ;;
            -l) line="$2"; shift ;;
            -a) action="add" ;;
            -r) action="remove" ;;
            -p) position="$2"; shift ;;
            -d) disable_idempotency="true" ;;
            -o) output_file="$2"; shift ;;
            *) echo "Unknown option: $1"; return 1 ;;
        esac
        shift
    done

    # Check for required parameters
    if [[ -z "$file" || -z "$line" ]]; then
        echo "Usage: lineinfile -f <file> -l <line> [-a | -r] [-p <beginning|end>] [-d] [-o <output_file>]" >&2
        return 1
    fi

    # Define the function to add a line
    add_line() {
        if [[ "$disable_idempotency" == "false" ]] && grep -qF -- "$line" "$file"; then
            log_debug "Line already exists and ignoring: $line"
        else
            if [[ "$position" == "beginning" ]]; then
                sed -i "1i $line" "$file"
            else
                echo "$line" >> "$file"
            fi
            log_debug "Line added at $position: $line"
        fi
    }

    # Define the function to remove a line
    remove_line() {
        if grep -qF -- "$line" "$file"; then
            sed -i "/^$(echo "$line" | sed 's/[\/&]/\\&/g')$/d" "$file"
            log_debug "Line removed: $line"
        else
            log_debug "Line not found: $line"
        fi
    }

    # Perform the action
    if [[ -n "$output_file" ]]; then
        cp "$file" "$output_file"
        file="$output_file"
    fi

    if [[ "$action" == "add" ]]; then
        add_line
    elif [[ "$action" == "remove" ]]; then
        remove_line
    else
        log_error "No action specified. Use -a to add or -r to remove."
        return 1
    fi
}
