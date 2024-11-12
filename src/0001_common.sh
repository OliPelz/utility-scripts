# no shebang line here, for sourcing ONLY, works in both bash and zsh
# shebang is not working in sourced files!
#
# to source this file into any script do:
# s=${BASH_SOURCE:-${(%):-%x}} d=$(cd "$(dirname "$s")" && pwd) && source $d/common.sh
#
# small function collection

is_root() {
   : '
		Is Root

		ShortDesc: This function checks if the script is being run with root privileges.

		Description:
		This function evaluates the effective user ID (EUID) of the current user.
		It returns 0 if the script is being executed by the root user (EUID 0) and 
		returns 1 if it is being executed by a non-root user. This is useful for 
		ensuring that certain operations requiring elevated privileges are only 
		executed when the script is run as root.

		Parameters:
		- None

		Returns:
		- 0: Success (the script is running as root)
		- 1: Failure (the script is not running as root)

		Example Usage:
		if is_root; then
			echo "Running as root."
		else
			echo "Not running as root. Please run with sudo."
		fi
    '
   if [[ $EUID -ne 0 ]]; then
      return 1
   fi
   return 0
}

contains() {
    : '
		Contains

		ShortDesc: This function checks if a substring exists within a main string.

		Description:
		This function takes two strings as arguments: a main string and a substring.
		It checks if the substring is present within the main string and returns 0
		if found, or 1 if not found.

		Parameters:
		- main_string: The string in which to search for the substring.
		- substring: The string to search for within the main string.

		Returns:
		- 0: Success (the substring is found within the main string)
		- 1: Failure (the substring is not found)

		Example Usage:
		if contains "Hello, World!" "World"; then
			echo "Substring found!"
		else
			echo "Substring not found."
		fi
    '

    local main_string="$1"
    local substring="$2"
    if [[ "$main_string" == *"$substring"* ]]; then
        return 0    # Success
    else
        return 1    # Failure
    fi
}
get_full_path_script_executed_in() {
    : '
		Get Full Path of Script Executed In

		ShortDesc: This function retrieves the full directory path of the currently executing script.

		Description:
		This function checks the shell type (Bash or Zsh) and retrieves the full path of the script
		being executed. It returns the directory of the script. If the shell is unsupported, it 
		prints an error message and returns 1.

		Parameters:
		- None

		Returns:
		- 0: Success (the full directory path is printed)
		- 1: Failure (unsupported shell)

		Example Usage:
		echo "Script is located in: $(get_full_path_script_executed_in)"
    '
    local MYSHELL_NAME=$(get_current_shell_name)
    if [ "$MYSHELL_NAME" = "bash" ]; then
        script_path="${BASH_SOURCE[0]}"
    elif [ "$MYSHELL_NAME" = "zsh" ]; then
        script_path="${(%):-%x}"
    else
        echo "Unsupported shell"
        return 1
    fi
    script_dir="$(cd "$(dirname "$script_path")" && pwd)"
    echo "$script_dir"
}

get_parent_dir_name_of_script() {
    : '
        Get Parent Directory Name of the Script

        ShortDesc: This function retrieves the name of the parent directory where the currently executing script is located.

        Description:
        This function uses the `get_full_path_script_executed_in` function to obtain the full directory path of
        the currently executing script. It then extracts the parent directory name from the path.
        If the parent directory name cannot be determined, an error message is displayed, and the function returns 1.

        Parameters:
        - None

        Returns:
        - 0: Success (the parent directory name is printed)
        - 1: Failure (unable to determine parent directory)

        Example Usage:
        parent_dir_name=$(get_parent_dir_name_of_script)
        echo "Parent directory name is: $parent_dir_name"
    '

    # Get the full path where the script is executed
    local full_path
    full_path=$(get_full_path_script_executed_in)

    # Check if we successfully retrieved the full path
    if [[ $? -ne 0 || -z "$full_path" ]]; then
        echo "Failed to determine the full path of the script."
        return 1
    fi

    # Extract the parent directory name from the full path
    local parent_dir_name
    parent_dir_name=$(basename "$full_path")

    # Check if we successfully retrieved the parent directory name
    if [[ -z "$parent_dir_name" ]]; then
        echo "Failed to determine the parent directory name."
        return 1
    fi

    # Print the parent directory name
    echo "$parent_dir_name"
    return 0
}

test_env_variable_defined() {
    : '
    Test Environment Variable (Defined, Non-Empty, or Both)

    ShortDesc: This function checks if a specified environment variable is defined, non-empty, or both.

    Description:
    This function takes the name of an environment variable as the first argument and an optional mode
    ("defined" or "non-empty") as the second argument. By default, it checks if the variable is defined
    and not empty. If "defined" is provided, it checks if the variable is defined, regardless of its value.
    If "non-empty" is provided, it checks if the variable is non-empty, regardless of whether its defined.

    Parameters:
    - ARG: The name of the environment variable to check.
    - MODE (optional): The mode to check ("defined", "non-empty", or default).

    Returns:
    - 0: Success (the condition specified by the mode is met)
    - 1: Failure (the condition specified by the mode is not met)

    Example Usages:
    
	1. Check if variable is defined and non-empty (default mode):


		MY_VAR="Hello"
		if test_env_variable_defined "MY_VAR"; then
			echo "MY_VAR is defined and non-empty."
		fi
		# Output: MY_VAR is defined and non-empty.

	2. Check if variable is defined (MODE="defined"):

		unset MY_VAR
		if test_env_variable_defined "MY_VAR" "defined"; then
			echo "MY_VAR is defined."
		else
			echo "MY_VAR is not defined."
		fi
		# Output: MY_VAR is not defined.

	3. Check if variable is non-empty (MODE="non-empty"):

		MY_VAR=""
		if test_env_variable_defined "MY_VAR" "non-empty"; then
			echo "MY_VAR is non-empty."
		else
			echo "MY_VAR is empty or not defined."
		fi
		# Output: MY_VAR is empty or not defined.

    '

    local ARG="$1"
    local MODE="${2:-both}"

    case "$MODE" in
        "defined")
            # Check if the variable is defined
            if [ "${!ARG+set}" = "set" ]; then
                return 0  # Variable is defined
            else
                return 1  # Variable is not defined
            fi
            ;;
        "non-empty")
            # Check if the variable is non-empty
            if [ -n "${!ARG}" ]; then
                return 0  # Variable is non-empty
            else
                return 1  # Variable is empty or not defined
            fi
            ;;
        "both" | *)
            # Default mode: Check if the variable is defined and not empty
            if [ "${!ARG+set}" = "set" ] && [ -n "${!ARG}" ]; then
                return 0  # Variable is defined and non-empty
            else
                return 1  # Variable is not defined or is empty
            fi
            ;;
    esac
}

is_var_true() {
    : '
		Is Variable True

		ShortDesc: This function checks if a specified environment variable is set to "true".

		Description:
		This function takes the name of an environment variable as an argument and checks
		if it is defined. If defined, it converts the variables value to lowercase and checks
		if it is equal to "true". The function returns 0 if the variable is set and true, and
		1 if the variable is not defined or is not true.

		Parameters:
		- var_name: The name of the environment variable to check.

		Returns:
		- 0: Success (the variable is defined and set to "true")
		- 1: Failure (the variable is not defined or is not "true")

		Example Usage:
		if is_var_true "MY_VAR"; then
			echo "MY_VAR is set to true."
		else
			echo "MY_VAR is not set to true."
		fi
    '
    local var_name="$1"  # Store the variable name
    local var_value

    # Call test_env_variable_defined with the variable name as a string
    if test_env_variable_defined "${var_name}"; then
        # Access the value of the variable using indirect expansion
        var_value="${!var_name,,}"  # Convert the value to lowercase

        if [ "${var_value}" == "true" ]; then
            return 0  # Success, the variable is set and true
        fi
    fi

    return 1  # Failure, the variable is either not set or not true
}


create_temp() {
    : '
		Create Temporary File or Directory

		ShortDesc: This function creates a temporary file or directory and optionally deletes it on exit.

		Description:
		This function creates a temporary file or directory based on the specified type.
		It uses `mktemp` to create the temporary item and can automatically delete it
		when the script exits. The user can specify a suffix for the temporary item and
		whether it should be deleted upon exit.

		Parameters:
		- type: The type of temporary item to create ("file" or "dir").
		- delete_on_exit: A boolean value indicating whether to delete the temporary item on exit
		  (optional; defaults to true).
		- suffix: An optional suffix to append to the temporary item name (optional; defaults to an empty string).

		Returns:
		- 0: Success (the path of the created temporary item is printed)
		- 1: Failure (if an invalid type is specified)

		Example Usage:
		temp_file=$(create_temp "file" true ".txt")
		echo "Temporary file created at: $temp_file"

		temp_dir=$(create_temp "dir" false)
		echo "Temporary directory created at: $temp_dir"
    '
    local type="$1"
    local delete_on_exit="${2:-true}"
    local suffix="${3:-''}"
    local temp_path=""

    if [[ "$type" == "file" ]]; then
        temp_path=$(mktemp --suffix $suffix)
    elif [[ "$type" == "dir" ]]; then
        temp_path=$(mktemp -d --suffix $suffix)
    else
        echo "Invalid type specified. Use 'file' or 'dir'."
        return 1
    fi
    echo "$temp_path"

    if [[ "$delete_on_exit" == true ]]; then
        trap 'rm -rf "$temp_path"' EXIT
    fi
}

detect_distribution() {
     : '
		Detect Distribution

		ShortDesc: This function detects the Linux distribution based on the /etc/os-release file.

		Description:
		This function checks for the presence of the /etc/os-release file, which contains information 
		about the operating system. It sources this file to retrieve the distribution ID and uses 
		a case statement to determine the type of Linux distribution. It returns a string indicating 
		the distribution type or an error message if the distribution is unsupported or cannot be determined.

		Parameters:
		- None

		Returns:
		- "RHEL": If the distribution is Fedora, CentOS, or RHEL.
		- "ARCH": If the distribution is Arch Linux.
		- "DEBIAN": If the distribution is Ubuntu or Debian.
		- "NONE": If the distribution is unsupported or if the /etc/os-release file cannot be found.

		Example Usage:
		distro=$(detect_distribution)
		if [[ "$distro" != "NONE" ]]; then
			echo "Detected distribution: $distro"
		else
			echo "Failed to detect distribution."
		fi
    '
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "${ID}" in
            fedora|centos|rhel)
                return "RHEL"
                ;;
            arch)
                return "ARCH"
                ;;
            ubuntu|debian)
                return "DEBIAN"
                ;;
            *)
                echo "Unsupported distribution: ${ID}"
                return "NONE"
                ;;
        esac
    else
        echo "Cannot determine distribution."
        return "NONE"
    fi
}

check_command_installed() {
    : '
    Check Command Installed

    ShortDesc: Checks if a specified command is accessible and installed on the system.

    Description:
    This function verifies if a given command is available in the system’s PATH, indicating that it
    is installed and accessible. It is useful for checking dependencies before running other scripts or commands.

    Parameters:
    - command_name: The name of the command to check (e.g., "curl", "git").

    Returns:
    - 0: Success (the command is accessible and installed)
    - 1: Failure (the command is not found)

    Example Usage:
    check_command_installed "curl" && echo "Curl is installed." || echo "Curl is not installed."
    '

    local command_name="$1"

    if command -v "$command_name" &> /dev/null; then
        return 0  # Command is accessible
    else
        return 1  # Command is not found
    fi
}

check_string_starts_with() {
    : '
    Check If String Starts With Substring

    ShortDesc: Determines if a given string starts with a specified substring.

    Description:
    This function checks if a provided string starts with a specific substring.
    It also has an optional parameter to ignore leading whitespaces in the string
    before performing the comparison.

    Parameters:
    - string: The string to check.
    - substring: The substring to check if the string starts with.
    - ignore_whitespace (optional): If set to "true", leading whitespaces in the string
      will be ignored before the comparison.

    Returns:
    - 0: If the string starts with the substring.
    - 1: If the string does not start with the substring.

    Example Usage:
    check_string_starts_with "Hello World" "Hello"      # Returns 0
    check_string_starts_with "   Hello World" "Hello" true # Returns 0
    check_string_starts_with "Goodbye World" "Hello"    # Returns 1
    '

    local string="$1"
    local substring="$2"
    local ignore_whitespace="${3:-false}"

    if [ "$ignore_whitespace" = "true" ]; then
        # Trim leading whitespace
        string="$(echo "$string" | sed 's/^[[:space:]]*//')"
    fi

    # Check if the string starts with the substring
    if [[ "$string" == "$substring"* ]]; then
        return 0
    else
        return 1
    fi
}

list_subdirectories() {
    : '
        List Subdirectories

        ShortDesc: This function lists subdirectory names up to a specified depth.

        Description:
        Given a directory path, this function prints the names of its subdirectories up to the specified depth.
        By default, it lists the subdirectories at the first level (max depth of 1). Optionally, a different
        maximum depth can be provided.

        Parameters:
        - dir: The directory path where to search for subdirectories.
        - max_depth: Optional. The maximum depth for searching subdirectories (default is 1).

        Returns:
        - 0: Success (subdirectories printed)
        - 1: Failure (directory does not exist or invalid depth)

        Example Usage:
        list_subdirectories "/path/to/directory"
        list_subdirectories "/path/to/directory" 2
    '

    local dir="$1"
    local max_depth="${2:-1}"

    # Check if the provided directory exists
    if [ ! -d "$dir" ]; then
        echo "Error: Directory does not exist: $dir"
        return 1
    fi

    # Find and list subdirectories up to the specified max depth
    find "$dir" -mindepth 1 -maxdepth "$max_depth" -type d -exec basename {} \;
}


