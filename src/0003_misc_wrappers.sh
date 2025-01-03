parse_yaml() {
    : '
        YAML Parsing Wrapper

        ShortDesc: A convenience function wrapping `yq` for YAML parsing with comment removal.

        Description:
        This function leverages `yq` to parse YAML data, removing all comments from the input file and
        using `-r` for raw output. It allows flexible output options:
        - inline: overwrites the input file with the parsed output
        - outfile: writes the parsed output to a specified file
        - stdout: displays the parsed output to standard output (default)

        Parameters:
        - parse_string: The `yq` parsing expression to extract the desired YAML content.
        - input_file: The YAML file to be processed.
        - output_mode: Defines where to output the result, possible values are `inline`, `outfile`, or `stdout`.
        - outfile_path (optional): If `outfile` is selected, specifies the file path for the parsed output.

        Returns:
        - 0: Success
        - 1: Failure (invalid arguments or `yq` command errors)

        Example Usage:
        parse_yaml ".metadata.name" "input.yaml" "inline"
        parse_yaml ".spec.containers[0].image" "config.yaml" "outfile" "parsed.yaml"
        parse_yaml ".some.property" "file.yaml" "stdout"
    '

    # Input validation and defaults
    local parse_string="$1"
    local input_file="$2"
    local output_mode="${3:-stdout}"
    local outfile_path="$4"

    if [[ -z "$parse_string" || -z "$input_file" ]]; then
        echo "Usage: parse_yaml <parse_string> <input_file> [output_mode] [outfile_path]" >&2
        return 1
    fi

    # Temporary variable for parsed output
    local parsed_output

    # Remove comments and parse the YAML file with `yq`
    parsed_output=$(yq -r "$parse_string" <(grep -v '^#' "$input_file") 2>/dev/null)
    local yq_exit_code=$?

    # Check for `yq` command errors
    if [[ $yq_exit_code -ne 0 ]]; then
        log_error "Failed to parse YAML file: 'yq' command returned exit code $yq_exit_code."
        return 1
    fi

    # Handle output options
    case "$output_mode" in
        inline)
            # Inline mode: overwrite the input file with parsed output
            echo "$parsed_output" > "$input_file" || {
                log_error "Error: Unable to overwrite file '$input_file'."
                return 1
            }
            ;;
        outfile)
            # Outfile mode: save to the specified outfile path
            if [[ -n "$outfile_path" ]]; then
                echo "$parsed_output" > "$outfile_path" || {
                    log_error "Error: Unable to write to file '$outfile_path'."
                    return 1
                }
            else
                log_error "Error: Outfile path not specified."
                return 1
            fi
            ;;
        stdout|*)
            # Default: stdout
            echo "$parsed_output"
            ;;
    esac

    return 0
}

check_python_import_package() {
    : '
    Check if a Python package is importable.

    This function uses the Python CLI to check if a given package can be imported.
    If the package is importable, it returns 0; otherwise, it returns 1.

    Parameters:
    - $1: Name of the Python package to check.

    Example:
        check_python_import_package "numpy"
        if [ $? -eq 0 ]; then
            echo "Package is importable."
        else
            echo "Package is not importable."
        fi
    '

    local package_name="$1"

    if [ -z "$package_name" ]; then
        echo "Error: No package name provided."
        return 2
    fi

    python3 -c "import $package_name" &>/dev/null
    if [ $? -eq 0 ]; then
        echo "Package '$package_name' is importable."
        return 0
    else
        echo "Package '$package_name' is not importable."
        return 1
    fi
}

