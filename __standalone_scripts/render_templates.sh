#!/bin/bash

set -euo pipefail

: '
Render Templates Script with {{var_name}} Support

ShortDesc: A script for rendering templates using environment variables, supporting `{{var_name}}` placeholders and preserving literal `${var_name}`.

Description:
This script processes a directory of template files, replacing `{{var_name}}` placeholders with corresponding environment variable values defined in a separate file. It also preserves any literal `${var_name}` placeholders in the templates by escaping and restoring them during processing.

Parameters:
--template-dir <path>: The directory containing the template files to process.
--output-dir <path>: The base directory where rendered templates will be saved.
--env-file <path>: A file containing environment variable definitions for rendering templates.
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

Example Directory Structure:
template_dir/
├── subdir1/
│   └── template1.txt
└── subdir2/
    └── template2.txt

Example Template (`template1.txt`):
Hello, my name is {{NAME}}.
I live in {{CITY}}.
This is a literal: ${LITERAL_VAR}.

Example Environment File (`data.env`):
NAME="John Doe"
CITY="Springfield"

Example Usage:
# Render templates with environment variables
./render_templates.sh --template-dir template_dir --output-dir output_dir --env-file data.env

# Expected Output
output_dir/
├── subdir1/
│   └── template1.txt
└── subdir2/
    └── template2.txt

Contents of `output_dir/subdir1/template1.txt`:
Hello, my name is John Doe.
I live in Springfield.
This is a literal: ${LITERAL_VAR}.

Advanced Usage:
# Display usage information
./render_templates.sh --help

# Debug processing step-by-step
bash -x ./render_templates.sh --template-dir template_dir --output-dir output_dir --env-file data.env
'


# Function to display usage
usage() {
    echo "Usage: $0 --template-dir TEMPLATE_DIR --output-dir OUTPUT_DIR --env-file ENV_FILE"
    echo ""
    echo "Options:"
    echo "  --template-dir   Directory containing template files."
    echo "  --output-dir     Directory for rendered files."
    echo "  --env-file       File with environment variable definitions."
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
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required parameters
if [[ -z "$TEMPLATE_DIR" || -z "$OUTPUT_DIR" || -z "$ENV_FILE" ]]; then
    echo "Error: Missing required parameters."
    usage
fi

# Validate template directory
if [[ ! -d "$TEMPLATE_DIR" ]]; then
    echo "Error: Template directory '$TEMPLATE_DIR' does not exist."
    exit 1
fi

# Validate environment file
if [[ ! -f "$ENV_FILE" ]]; then
    echo "Error: Environment file '$ENV_FILE' does not exist."
    exit 1
fi

# Load environment variables
set -a
source "$ENV_FILE"
set +a

# Process templates
find "$TEMPLATE_DIR" -type f | while read -r template; do
    # Define output path
    relative_path="${template#$TEMPLATE_DIR/}"
    output_path="$OUTPUT_DIR/$relative_path"

    # Create output subdirectory if necessary
    mkdir -p "$(dirname "$output_path")"

    # Preprocess placeholders:
    # 1. Replace {{var_name}} with ${var_name}
    # 2. Escape literal ${var_name} to prevent replacement
    sed -E '
        s/\$\{([a-zA-Z0-9_]+)\}/__LITERAL_OPEN__\1__LITERAL_CLOSE__/g;
        s/\{\{([a-zA-Z0-9_]+)\}\}/${\1}/g
    ' "$template" |
    envsubst |
    sed -E '
        s/__LITERAL_OPEN__/\\${/g;
        s/__LITERAL_CLOSE__/}/g
    ' > "$output_path"
done

echo "Templates have been successfully rendered to '$OUTPUT_DIR'."

