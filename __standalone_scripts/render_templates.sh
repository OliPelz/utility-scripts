#!/bin/bash

set -euo pipefail

: '
Render Templates Script with {{var_name}} Support

ShortDesc: A script for rendering templates using environment variables, supporting `{{var_name}}` placeholders and preserving literal `${var_name}`.

Description:
This script processes a directory of template files, replacing `{{var_name}}` placeholders with corresponding environment variable values defined in a separate file. It also preserves any literal `${var_name}` placeholders in the templates by escaping and restoring them during processing.
IMPORTANT: the script only considers files ending with .j2 !
IMPORTANT2: you can also render out folder names from variables using syntax: 
            MY_VAR=ohboy =>  ./__{{MY_VAR}}__/xxx.yaml.j2  =render it using script==> ./ohboy/xxx.yaml 

Parameters:
--template-dir <path>: The directory containing the template files to process.
--output-dir <path>: The base directory where rendered templates will be saved.
--env-file <path>: OPTIONAL! A file containing environment variable definitions for rendering templates. 
                   If not provided, use the environment from the process calling this script
--help: Display usage information and exit.

Behavior:
1. Replaces `{{var_name}}` with `${var_name}` for compatibility with `envsubst`.
2. Preserves literal `${var_name}` placeholders in the templates.
3. Substitutes `${var_name}` placeholders using environment variables loaded from the specified file.
4. Maintains the original directory structure of the template directory in the output directory.

Environment Variables:
- Variables defined in the `--env-file` are loaded and used for substitution in the templates.

Returns:
- 0: Success
- 1: Failure (e.g., missing parameters, directory not found, or file inaccessible).
'
fc_log_info() {
    echo -e "\033[0;32m[INFO]\033[0m $1" >&2  # Green
}

fc_log_info2() {
    echo -e "\033[0;36m[INFO]\033[0m $1" >&2  # Cyan
}

fc_log_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1" >&2  # Red
}

fc_log_warning() {
    echo -e "\033[1;33m[WARNING]\033[0m $1" >&2  # Bold Yellow
}

# Function to replace __{{VARIABLE_NAME}}__ in directory names
process_directory_name() {
    local dir="$1"
    fc_log_info "Processing directory name: $dir"
    echo "$dir" | sed -E "s/__\{\{([a-zA-Z0-9_]+)\}\}__/$(eval echo \${\1})/g"
}

# Function to display usage
usage() {
    echo "Usage: $0 --template-dir TEMPLATE_DIR --output-dir OUTPUT_DIR [--env-file ENV_FILE]"
    echo ""
    echo "Options:"
    echo "  --template-dir   Directory containing template files."
    echo "  --output-dir     Directory for rendered files."
    echo "  --env-file       Optional: File with environment variable definitions."
    echo "  --help           Display usage information."
    exit 1
}

# Parse command-line arguments
TEMPLATE_DIR=""
OUTPUT_DIR=""
ENV_FILE=""

fc_log_info "Parsing command-line arguments..."
while [[ $# -gt 0 ]]; do
    case "$1" in
        --template-dir)
            TEMPLATE_DIR="$2"
            fc_log_info "Template directory set to: $TEMPLATE_DIR"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            fc_log_info "Output directory set to: $OUTPUT_DIR"
            shift 2
            ;;
        --env-file)
            ENV_FILE="$2"
            fc_log_info "Environment file set to: $ENV_FILE"
            shift 2
            ;;
        --help)
            usage
            ;;
        *)
            fc_log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required parameters
if [[ -z "$TEMPLATE_DIR" || -z "$OUTPUT_DIR" ]]; then
    fc_log_error "Missing required parameters."
    usage
fi

# Validate template directory
if [[ ! -d "$TEMPLATE_DIR" ]]; then
    fc_log_error "Template directory '$TEMPLATE_DIR' does not exist."
    exit 1
fi

# Load environment variables if env-file is provided
if [[ -n "$ENV_FILE" ]]; then
    if [[ ! -f "$ENV_FILE" ]]; then
        fc_log_error "Environment file '$ENV_FILE' does not exist."
        exit 1
    fi
    fc_log_info "Loading environment variables from '$ENV_FILE'..."
    set -a
    source "$ENV_FILE"
    set +a
else
    fc_log_info "Using current process environment variables."
fi

# Process templates
fc_log_info "Starting template processing..."
find "$TEMPLATE_DIR" -type f -name '*.j2' | while read -r template; do
    fc_log_info "Processing template: $template"

    # Define relative path
    relative_path="${template#$TEMPLATE_DIR/}"
    fc_log_info "Relative path: $relative_path"

    # Process directory names for variables
    relative_dir="$(dirname "$relative_path")"
    processed_dir="$(process_directory_name "$relative_dir")"
    output_path="$OUTPUT_DIR/$processed_dir/$(basename "${relative_path%.j2}")"

    fc_log_info "Output path: $output_path"

    # Create output subdirectory if necessary
    mkdir -p "$(dirname "$output_path")"
    fc_log_info "Created output directory: $(dirname "$output_path")"

    # Preprocess placeholders, e.g., to replace dir names
    sed -E '
        s/\$\{([a-zA-Z0-9_]+)\}/__LITERAL_OPEN__\1__LITERAL_CLOSE__/g;
        s/\{\{([a-zA-Z0-9_]+)\}\}/${\1}/g
    ' "$template" |
    envsubst |
    sed -E '
        s/__LITERAL_OPEN__/\\${/g;
        s/__LITERAL_CLOSE__/}/g
    ' > "$output_path"

    fc_log_info "Template rendered: $output_path"
done

fc_log_info "Templates have been successfully rendered to '$OUTPUT_DIR'."
