git_clone_or_pull() {
    : '
        Git Clone or Pull

        ShortDesc: This function clones a Git repository if it does not exist, or pulls the latest changes if it does.

        Description:
        The function checks whether a specified Git repository directory already exists. If the directory exists,
        it pulls the latest changes from the remote repository. If it does not exist, the function clones the repository.
        Optionally, it can append the directory name to the `.gitignore` file if specified. Additionally, the function can
        clean up the target directory by removing untracked files and resetting changes if the --clean flag is provided.

        Parameters:
        - --repo_url: The URL of the Git repository to clone or pull.
        - --target_dir (optional): The target directory where the repository should be cloned. If not provided, the repository
                                   will be cloned into a directory named after the repository.
        - --add_to_gitignore (optional): A flag ("true" or "false") to determine whether to add the directory name to `.gitignore`.
                                         Defaults to "false".
        - --clean (optional): A flag to clean the repository directory before pulling (defaults to "false").

        Returns:
        - 0: Success
        - 1: Failure if the Git commands fail or if invalid parameters are used.

        Example Usage:
        git_clone_or_pull --repo_url "https://github.com/user/repo.git" --target_dir "my_repo" --add_to_gitignore "true" --clean
    '

    # Parameters
    local repo_url=""
    local target_dir=""
    local add_to_gitignore="false"
    local clean="false"

    # Parse arguments
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --repo_url) repo_url="$2"; shift ;;
            --target_dir) target_dir="$2"; shift ;;
            --add_to_gitignore) add_to_gitignore="$2"; shift ;;
            --clean) clean="true" ;;
            *) echo "Unknown parameter: $1"; return 1 ;;
        esac
        shift
    done

    # Check if repo_url is provided
    if [[ -z "$repo_url" ]]; then
        echo "Error: --repo_url is required"
        return 1
    fi

    # Extract the repository name from the URL
    local org_repo_name
    org_repo_name=$(basename "$repo_url" .git)
    local repo_dir="${target_dir:-$org_repo_name}"

    # Check if the repository directory exists
    if [ -d "$repo_dir" ]; then
        echo "Repository '$org_repo_name' already exists."

        # Optionally clean the repo before pulling
        if [ "$clean" == "true" ]; then
            echo "Cleaning up repository directory before pulling..."
            (cd "$repo_dir" && git clean -fd && git reset --hard) || return 1
        fi

        echo "Pulling latest changes..."
        (cd "$repo_dir" && git pull > /dev/null) || return 1
    else
        echo "Cloning repository '$org_repo_name' into '$repo_dir'..."
        git clone "$repo_url" "$repo_dir" || return 1
    fi

    # Optionally add the directory name to .gitignore
    if [ "$add_to_gitignore" == "true" ]; then
        [ -f .gitignore ] && grep -q "^${repo_dir}$" .gitignore || echo "$repo_dir" >> .gitignore
    fi

    return 0
}
