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

download_if_newer() {
    : '
        Download File If Newer

        ShortDesc: Downloads a file only if it is newer than the local copy or if the file does not exist locally.

        Description:
        This function uses curl to download a file from a URL only if the remote file is newer than the local file
        or if the local file does not exist. It leverages the `-z` flag in curl for modification date comparison.

        Parameters:
        - $1 (required): URL of the file to download.
        - $2 (required): Local file path where the downloaded file will be saved.

        Returns:
        - 0: File downloaded or up-to-date.
        - 1: Missing required arguments (URL or output file path).
        - 2: Download failed.

        Example Usage:
        download_if_newer "https://example.com/file.zip" "/local/path/file.zip"
    '

    local url=$1
    local output_file=$2

    # Validate inputs
    if [[ -z "$url" || -z "$output_file" ]]; then
        echo "Error: Missing required arguments: URL or output file path."
        return 1
    fi

    # Ensure output file directory exists
    local output_dir
    output_dir=$(dirname "$output_file")
    mkdir -p "$output_dir"

    # Debug logging
    echo "Downloading $url to $output_file..."

    # Check if file exists
    if [[ -e "$output_file" ]]; then
        # Use curl with -z for modification time comparison
        if curl -L -z "$output_file" -o "$output_file" "$url"; then
            echo "File downloaded or up-to-date: $output_file"
            return 0
        else
            echo "Error: Failed to download $url to $output_file"
            return 2
        fi
    else
        # Download file since it doesn't exist locally
        if curl -L -o "$output_file" "$url"; then
            echo "File downloaded: $output_file"
            return 0
        else
            echo "Error: Failed to download $url to $output_file"
            return 2
        fi
    fi
}

download_if_size_differs() {
    : '
        Download File If Size Differs

        ShortDesc: Downloads a file only if the remote file size differs from the local file size.

        Description:
        This function checks the size of a file on the remote server and compares it with the size of the local file.
        If the sizes differ, or if the local file does not exist, it downloads the file.

        Parameters:
        - $1 (required): URL of the file to download.
        - $2 (required): Local file path where the downloaded file will be saved.

        Returns:
        - 0: File downloaded or up-to-date.
        - 1: Missing required arguments (URL or output file path).
        - 2: Failed to retrieve remote file size.
        - 3: Download failed.

        Example Usage:
        download_if_size_differs "https://example.com/file.zip" "/local/path/file.zip"
    '

    local url=$1
    local output_file=$2

    # Validate inputs
    if [[ -z "$url" || -z "$output_file" ]]; then
        echo "Error: Missing required arguments: URL or output file path."
        return 1
    fi

    # Ensure output file directory exists
    local output_dir
    output_dir=$(dirname "$output_file")
    mkdir -p "$output_dir"

    # Debug logging
    echo "Checking remote size for $url..."

    # Get remote file size
    local remote_size
    remote_size=$(curl -sI "$url" | awk '/^Content-Length:/ {print $2}' | tr -d '\r')

    if [[ -z "$remote_size" ]]; then
        echo "Error: Failed to retrieve remote file size for $url."
        return 2
    fi

    echo "Remote file size: $remote_size bytes"

    # Check if local file exists and get its size
    if [[ -e "$output_file" ]]; then
        local local_size
        local_size=$(stat -c%s "$output_file" 2>/dev/null || echo 0)

        echo "Local file size: $local_size bytes"

        # Compare sizes
        if [[ "$remote_size" -eq "$local_size" ]]; then
            echo "File sizes match. Skipping download."
            return 0
        fi
    else
        echo "Local file does not exist. Proceeding to download."
    fi

    # Download file
    echo "Downloading $url to $output_file..."
    if curl -L -o "$output_file" "$url"; then
        echo "File downloaded: $output_file"
        return 0
    else
        echo "Error: Failed to download $url to $output_file"
        return 3
    fi
}
