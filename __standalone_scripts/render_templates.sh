#!/bin/bash

set -euo pipefail

: '
Render Templates Script with {{var_name}} Support

ShortDesc: A script for rendering templates using environment variables, supporting `{{var_name}}` placeholders and preserving literal `${var_name}`.

Description:
This script processes a directory of template files, replacing `{{var_name}}` placeholders with corresponding environment variable values. It also supports renaming directories containing placeholders in their names.
It will also work with ${varname} javascript and bash $VARNAME variables by NOT expanding them! Only {{ var_name }} will be expanded which is cool

IMPORTANT: Only files ending with `.j2` are processed!
IMPORTANT2: Directory names with placeholders like `__{{VAR_NAME}}__` are renamed based on the variable value.
IMPORTANT3: you now can define a template like dotfile-myfilename.txt.j2 and it will be rendered to .myfilename.txt
IMPORTANT4: Files with .ut extension are copied to the output directory without any modifications.

Parameters:
--template-dir <path>: The directory containing the template files to process.
--output-dir <path>: The base directory where rendered templates will be saved.
--env-file <path>: OPTIONAL! A file containing environment variable definitions for rendering templates. 
                   If not provided, uses the current environment variables.
--help: Display usage information and exit.

Examples:
./render_templates.sh --template-dir ./templates --output-dir ./output --env-file envfile.env


Returns:
- 0: Success
- 1: Failure (e.g., missing parameters, directory not found, or file inaccessible).
'


# Logging functions
fc_log_info() {
    echo -e "\033[0;32m[INFO]\033[0m $1" >&2
}
fc_log_warning() {
    echo -e "\033[1;33m[WARNING]\033[0m $1" >&2
}
fc_log_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1" >&2
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

while [[ $# -gt 0 ]]; do
    case "$1" in
        --template-dir)
            TEMPLATE_DIR="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --env-file)
            ENV_FILE="$2"
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
    fc_log_error "Both --template-dir and --output-dir are required."
    usage
fi

if [[ ! -d "$TEMPLATE_DIR" ]]; then
    fc_log_error "Template directory '$TEMPLATE_DIR' does not exist."
    exit 1
fi

# Load environment variables if env file provided
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

# Function to process and rename placeholders in directory/file names
process_placeholders() {
    local input="$1"
    local transformed

    # Replace placeholders and handle the special `dotfile-` prefix
    transformed=$(echo "$input" | sed -E 's/__\{\{([a-zA-Z0-9_]+)\}\}__/${\1}/g; s/^dotfile-/\./' | envsubst)

    # Log transformations for dotfile- prefixed files
    if [[ "$input" == dotfile-* ]]; then
        fc_log_info "Transformed dotfile prefix: '$input' -> '$transformed'"
    fi

    # Log transformations for directory placeholders
    if [[ "$input" =~ __\{\{.*\}\}__ ]]; then
        fc_log_info "Transformed placeholder in directory: '$input' -> '$transformed'"
    fi

    echo "$transformed"
}



# Copy and process directory structure
fc_log_info "Copying and processing directories from '$TEMPLATE_DIR' to '$OUTPUT_DIR'..."
# mindepth 1 = exclude base dir itself
find "$TEMPLATE_DIR" -mindepth 1 -type d | while read -r dir; do
    relative_dir="${dir#$TEMPLATE_DIR/}"  # Strip the template directory prefix
    processed_dir=$(process_placeholders "$relative_dir")  # Replace placeholders in the relative path
    output_dir="$OUTPUT_DIR/$processed_dir"

    fc_log_info "Creating directory: $output_dir"
    mkdir -p "$output_dir"
done

# Process `.ut` files (copy untouched)
fc_log_info "Copying .ut files without modification..."
find "$TEMPLATE_DIR" -type f -name '*.ut' | while read -r ut_file; do
    relative_path="${ut_file#$TEMPLATE_DIR/}"
    output_path="$OUTPUT_DIR/$relative_path"

    fc_log_info "Copying: $ut_file -> $output_path"
    mkdir -p "$(dirname "$output_path")"
    cp "$ut_file" "$output_path"
done

# Process templates
fc_log_info "Processing templates..."
find "$TEMPLATE_DIR" -type f -name '*.j2' | while read -r template; do
    relative_path="${template#$TEMPLATE_DIR/}"

    # Check if the file has a 'dotfile-' prefix and transform it
    base_name=$(basename "$relative_path")
    dir_name=$(dirname "$relative_path")

    if [[ "$base_name" == dotfile-* ]]; then
        # Handle 'dotfile-' prefixed filenames
        transformed_filename=".$(basename "${base_name#dotfile-}" .j2)"
        relative_path="$dir_name/$transformed_filename"
        fc_log_info "Transformed dotfile prefix: '$base_name' -> '$transformed_filename'"
    else
        # Remove the `.j2` extension for non-dotfile-prefixed files
        transformed_filename=$(basename "${base_name%.j2}")
        relative_path="$dir_name/$transformed_filename"
    fi

    # Process placeholders in the relative path
    processed_path=$(process_placeholders "$relative_path")
    output_path="$OUTPUT_DIR/$processed_path"

    # Log and render the template
    fc_log_info "Rendering template: $template -> $output_path"
    mkdir -p "$(dirname "$output_path")"

    sed -E '
        s/\$\{([a-zA-Z0-9_]+)\}/__LITERAL_OPEN__\1__LITERAL_CLOSE__/g;
        s/\{\{([a-zA-Z0-9_]+)\}\}/${\1}/g
    ' "$template" |
    envsubst |
    sed -E '
        s/__LITERAL_OPEN__/\${/g;
        s/__LITERAL_CLOSE__/}/g
    ' > "$output_path"
done


fc_log_info "Templates have been successfully rendered to '$OUTPUT_DIR'."

