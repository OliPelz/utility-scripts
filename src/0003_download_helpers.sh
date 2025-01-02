#!/bin/bash

download_file_from_github () {
    : '
        Download File from GitHub

        ShortDesc: Downloads a file from a GitHub repository, supporting both public and private repos.

        Description:
        This function downloads a file from a specified GitHub repository. By default, it downloads from public repositories.
        If the --private parameter is provided, it uses an authentication token for private repository access.
        It also supports setting a timeout and running in dry-run mode to output the generated curl command.

        Parameters:
        --token (required for private repos): GitHub token for authentication.
        --repo_owner (required): Owner of the GitHub repository.
        --repo_name (required): Name of the GitHub repository.
        --file_path (required): Path to the file within the repository.
        --branch (optional): Branch from which to download the file. Defaults to 'main'.
        --output_file (optional): Output file name. Defaults to the basename of the file path.
        --timeout (optional): Timeout for the download in seconds. Defaults to 600 seconds.
        --private (optional): Download from a private repository.
        --dry-run (optional): Show the curl command without executing it.

        Example Usage:
        download_file_from_github --token "<TOKEN>" --repo_owner "<OWNER>" --repo_name "<REPO>" --file_path "<PATH>" [--private] [--timeout 300] [--dry-run]
    '

    # Default parameters
    local GITHUB_TOKEN=""
    local REPO_OWNER=""
    local REPO_NAME=""
    local FILE_PATH=""
    local BRANCH="main"
    local OUTPUT_FILE=""
    local TIMEOUT=600
    local PRIVATE=false
    local DRY_RUN=false

    # Parse arguments
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --token) GITHUB_TOKEN="$2"; shift ;;
            --repo_owner) REPO_OWNER="$2"; shift ;;
            --repo_name) REPO_NAME="$2"; shift ;;
            --file_path) FILE_PATH="$2"; shift ;;
            --branch) BRANCH="$2"; shift ;;
            --output_file) OUTPUT_FILE="$2"; shift ;;
            --timeout) TIMEOUT="$2"; shift ;;
            --private) PRIVATE=true ;;
            --dry-run) DRY_RUN=true ;;
            *) echo "Unknown parameter: $1"; return 1 ;;
        esac
        shift
    done

    # Validate required parameters
    if [[ -z "$REPO_OWNER" || -z "$REPO_NAME" || -z "$FILE_PATH" ]]; then
        echo "Usage: download_file_from_github --repo_owner <OWNER> --repo_name <REPO> --file_path <PATH> [--branch <BRANCH>] [--output_file <OUTPUT_FILE>] [--timeout <SECONDS>] [--private] [--dry-run]"
        return 1
    fi

    # Set output file name if not provided
    OUTPUT_FILE="${OUTPUT_FILE:-$(basename "$FILE_PATH")}"

    # Construct curl command based on public/private repository
    local curl_cmd=("curl" "-L" "--max-time" "$TIMEOUT" "-o" "$OUTPUT_FILE")
    if [[ "$PRIVATE" == true ]]; then
        if [[ -z "$GITHUB_TOKEN" ]]; then
            echo "[ERROR] GitHub token is required for private repository access."
            return 1
        fi
        curl_cmd+=("-H" "Authorization: token $GITHUB_TOKEN" "-H" "Accept: application/vnd.github.v3.raw")
    else
        curl_cmd+=("-H" "Accept: application/vnd.github.v3.raw")
    fi
    curl_cmd+=("https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents/$FILE_PATH?ref=$BRANCH")

    # Dry-run: Show the command without executing
    if [[ "$DRY_RUN" == true ]]; then
        echo "Dry-run: ${curl_cmd[@]}"
        return 0
    fi

    # Execute the curl command and handle response
    if "${curl_cmd[@]}"; then
        echo "File downloaded successfully to $OUTPUT_FILE."
        return 0
    else
        echo "[ERROR] Failed to download the file."
        return 1
    fi
}


# Example usage (uncomment to test):
# download_from_private_github "your_personal_access_token" "owner" "repo" "path/to/file.txt" "main" "output.txt"

download_directory_from_github() {
    : '
        Download Directory from GitHub

        ShortDesc: Downloads a directory from a public or private GitHub repository.

        Parameters:
        - --github_token <token> (required for private repos): GitHub token for authorization.
        - --repo_owner <owner>: Owner of the repository.
        - --repo_name <name>: Repository name.
        - --dir_path <directory_path>: Directory path to download from the repository.
        - --branch <branch_name> (optional): Branch to download from, default is "main".
        - --output_dir <directory> (optional): Local output directory to save the downloaded files.
        - --private: Set this flag for downloading from private repositories.

        Example Usage:
        download_directory_from_github --repo_owner "user" --repo_name "repo" --dir_path "path/to/dir" --branch "main" --output_dir "./local_dir" --private
    '

    # Initialize variables
    local github_token=""
    local repo_owner=""
    local repo_name=""
    local dir_path=""
    local branch="main"
    local output_dir=""
    local private=false

    # Parse arguments
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --github_token) github_token="$2"; shift ;;
            --repo_owner) repo_owner="$2"; shift ;;
            --repo_name) repo_name="$2"; shift ;;
            --dir_path) dir_path="$2"; shift ;;
            --branch) branch="$2"; shift ;;
            --output_dir) output_dir="$2"; shift ;;
            --private) private=true ;;
            *) echo "Unknown parameter: $1"; return 1 ;;
        esac
        shift
    done

    # Check required parameters
    if [[ -z "$repo_owner" || -z "$repo_name" || -z "$dir_path" ]]; then
        echo "Error: Missing required parameters."
        echo "Usage: download_directory_from_github --repo_owner <owner> --repo_name <name> --dir_path <directory> [--branch <branch>] [--output_dir <directory>] [--private]"
        return 1
    fi

    # Set output directory to the directory path if not provided
    output_dir="${output_dir:-$dir_path}"

    # Construct the GitHub API URL
    local api_url="https://api.github.com/repos/$repo_owner/$repo_name/contents/$dir_path?ref=$branch"

    # Set up the curl command
    local curl_cmd="curl -L"
    if $private; then
        # Add authentication header for private repositories
        if [[ -z "$github_token" ]]; then
            echo "Error: GitHub token is required for private repositories."
            return 1
        fi
        curl_cmd+=" -H \"Authorization: token $github_token\""
    fi
    curl_cmd+=" -H \"Accept: application/vnd.github.v3.raw\" \"$api_url\""

    # Create output directory if it doesn't exist
    mkdir -p "$output_dir" || { echo "Failed to create output directory $output_dir"; return 1; }

    # Execute curl command and download files
    eval "$curl_cmd" -o "$output_dir/$dir_path.zip"

    # Check if the download was successful
    if [[ $? -eq 0 ]]; then
        echo "Directory downloaded successfully to $output_dir."
        return 0
    else
        echo "Failed to download the directory."
        return 1
    fi
}

download_if_newer_or_different_size() {
	: '
	    Download File Only if Newer or Different Size

	    ShortDesc: Downloads a file from a given URL only if it is newer or has a different size than the local file.

	    Description:
	    This function checks whether a file at a given URL is newer or has a different size compared to a local file. 
	    It uses HTTP headers such as "Content-Length" and "Last-Modified" for comparison and downloads the file only 
	    when necessary. It also validates the download and provides detailed error handling.

	    Parameters:
	    - url (required): The URL of the file to download.
	    - output_file (required): The path to the local file where the downloaded content will be saved.

	    Behavior:
	    1. Checks the HTTP response code of the URL to ensure it is 200 OK.
	    2. Fetches "Content-Length" and "Last-Modified" headers from the URL.
	    3. Compares the size of the local file with "Content-Length".
	    4. Compares the modification date of the local file with "Last-Modified" (if available).
	    5. Downloads the file if:
		- The local file does not exist.
		- The file size differs.
		- The remote file is newer (based on "Last-Modified").
	    6. Handles errors gracefully, including connectivity issues, missing headers, and invalid downloads.

	    Returns:
	    - 0: Success (file is downloaded or already up-to-date).
	    - 3: Failed to fetch headers from the URL.
	    - 4: Non-200 HTTP response.
	    - 5: Missing "Content-Length" header.
	    - 6: Download failed.

	    Example Usages:
	    
	    1. Download if newer or different size:

		download_if_newer_or_different_size "https://example.com/file.zip" "/path/to/file.zip"

	    2. Handle missing file:

		# If the file does not exist locally, it will be downloaded.
		download_if_newer_or_different_size "https://example.com/missing.zip" "/path/to/missing.zip"

	    3. Debugging failed downloads:

		# Use verbose output to debug:
		bash -x ./your_script.sh

	'
    local url="$1"
    local output_file="$2"

    echo "Checking $url for updates..."

    # Use curl to fetch headers
    local headers temp_file
    temp_file=$(mktemp)

    curl -sI "$url" >"$temp_file" || {
        echo "Error: Failed to fetch headers for $url. Please check your connection or the URL."
        rm -f "$temp_file"
        return 3
    }

    # Extract useful headers
    local remote_last_modified remote_size http_status
    http_status=$(awk '/^HTTP/{print $2}' "$temp_file")
    remote_last_modified=$(awk -F': ' '/^Last-Modified/{print $2}' "$temp_file" | tr -d '\r')
    remote_size=$(awk -F': ' '/^Content-Length/{print $2}' "$temp_file" | tr -d '\r')

    # Check HTTP response code
    if [[ "$http_status" != "200" ]]; then
        echo "Error: HTTP response for $url is $http_status. Expected 200 OK."
        rm -f "$temp_file"
        return 4
    fi

    # If remote size is missing
    if [[ -z "$remote_size" ]]; then
        echo "Warning: Content-Length header missing for $url. Downloading file anyway."
        curl -L -o "$output_file" "$url" || {
            echo "Error: Failed to download $url."
            rm -f "$temp_file"
            return 5
        }
        echo "Download complete: $output_file"
        rm -f "$temp_file"
        return 0
    fi

    # Check if file exists locally
    if [[ -f "$output_file" ]]; then
        local local_size local_last_modified
        local_size=$(stat --format="%s" "$output_file")
        local_last_modified=$(stat --format="%Y" "$output_file")

        # Compare sizes
        if [[ "$local_size" -ne "$remote_size" ]]; then
            echo "File size mismatch: local=$local_size, remote=$remote_size. Downloading updated file..."
        elif [[ -n "$remote_last_modified" ]]; then
            # Compare last modified time
            local remote_unix_time
            remote_unix_time=$(date -d "$remote_last_modified" +%s 2>/dev/null)

            if [[ "$local_last_modified" -lt "$remote_unix_time" ]]; then
                echo "Remote file is newer. Downloading updated file..."
            else
                echo "Local file is up-to-date."
                rm -f "$temp_file"
                return 0
            fi
        else
            echo "Warning: No Last-Modified header available for comparison. Downloading file anyway."
        fi
    else
        echo "Local file does not exist. Downloading..."
    fi

    # Download the file
    curl -L -o "$output_file" "$url" || {
        echo "Error: Failed to download $url."
        rm -f "$temp_file"
        return 6
    }

    echo "Download complete: $output_file"
    rm -f "$temp_file"
    return 0
}
