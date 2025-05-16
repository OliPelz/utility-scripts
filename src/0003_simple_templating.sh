simple_template() {
  : '
    simple_template

    ShortDesc: Replace {{VARNAME}} placeholders in a template file using exported environment variables.

    Description:
    This function replaces placeholders like {{VARNAME}}, {{HOSTNAME}}, etc., in a template file
    with the values of corresponding environment variables. The placeholders must exactly match
    the variable names. All variables must be passed as a comma-separated string and must be
    exported in the environment before calling the function.

    Parameters:
    - vars_csv: A comma-separated list of environment variable names to substitute (e.g., "UID,GID,LOCATION_PATH").
    - template_file: Path to the input template file containing {{VAR}} placeholders.
    - output_file: Path where the rendered output should be written.

    Returns:
    - 0: Success. Output written to file.
    - 1: Failure if a variable is not set or the template file is missing.

    Example Usage:
    UID=1111
    GID=2222
    LOCATION_PATH="/a/b/c"
    export UID GID LOCATION_PATH
    simple_template "UID,GID,LOCATION_PATH" templates/compose/docker-compose.yml.template docker-compose.generated.yml


    the corresponding template could look like this:
    $ cat templates/compose/docker-compose.yml.template:

    [...]
    user: "{{UID}}"
    group: "{{GID}}"
    location: "{{LOCATION_PATH}}"
    [...]
  '

  local vars_str="$1"
  local template_file="$2"
  local output_file="$3"

  # Check if template file exists
  [[ ! -f "$template_file" ]] && { echo "Template file not found: $template_file"; return 1; }

  # Convert comma-separated vars into array
  IFS=',' read -ra VARS <<< "$vars_str"

  # Build sed expressions
  local sed_exprs=""
  for var in "${VARS[@]}"; do
    if [[ -z "${!var+x}" ]]; then
      echo "Error: environment variable '$var' is not set or exported"
      return 1
    fi
    sed_exprs+=" -e s|{{${var}}}|${!var}|g"
  done

  # Execute sed with dynamic expressions
  eval sed $sed_exprs "$template_file" > "$output_file"
}

