is_root() {
if [[ $EUID -ne 0 ]]; then
return 1
fi
return 0
}
contains() {
local main_string="$1"
local substring="$2"
if [[ "$main_string" == *"$substring"* ]]; then
return 0
else
return 1
fi
}
get_full_path_script_executed_in() {
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
local full_path
full_path=$(get_full_path_script_executed_in)
if [[ $? -ne 0 || -z "$full_path" ]]; then
echo "Failed to determine the full path of the script."
return 1
fi
local parent_dir_name
parent_dir_name=$(basename "$full_path")
if [[ -z "$parent_dir_name" ]]; then
echo "Failed to determine the parent directory name."
return 1
fi
echo "$parent_dir_name"
return 0
}
test_env_variable_defined() {
local ARG="$1"
local MODE="${2:-both}"
case "$MODE" in
"defined")
if [ "${!ARG+set}" = "set" ]; then
return 0
else
return 1
fi
;;
"non-empty")
if [ -n "${!ARG}" ]; then
return 0  # Variable is non-empty
else
return 1
fi
;;
"both" | *)
if [ "${!ARG+set}" = "set" ] && [ -n "${!ARG}" ]; then
return 0  # Variable is defined and non-empty
else
return 1
fi
;;
esac
}
is_var_true() {
local var_name="$1"
local var_value
if test_env_variable_defined "${var_name}"; then
var_value="${!var_name,,}"
if [ "${var_value}" == "true" ]; then
return 0  # Success, the variable is set and true
fi
fi
return 1  # Failure, the variable is either not set or not true
}
create_temp() {
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
local command_name="$1"
if command -v "$command_name" &> /dev/null; then
return 0
else
return 1
fi
}
check_string_starts_with() {
local string="$1"
local substring="$2"
local ignore_whitespace="${3:-false}"
if [ "$ignore_whitespace" = "true" ]; then
string="$(echo "$string" | sed 's/^[[:space:]]*//')"
fi
if [[ "$string" == "$substring"* ]]; then
return 0
else
return 1
fi
}
list_subdirectories() {
local dir="$1"
local max_depth="${2:-1}"
if [ ! -d "$dir" ]; then
echo "Error: Directory does not exist: $dir"
return 1
fi
find "$dir" -mindepth 1 -maxdepth "$max_depth" -type d -exec basename {} \;
}
if [ -n "$BASH_VERSION" ]; then
declare -A bash_colors
bash_colors["black"]="\033[0;30m"
bash_colors["red"]="\033[0;31m"
bash_colors["green"]="\033[0;32m"
bash_colors["yellow"]="\033[0;33m"
bash_colors["blue"]="\033[0;34m"
bash_colors["purple"]="\033[0;35m"
bash_colors["cyan"]="\033[0;36m"
bash_colors["white"]="\033[0;37m"
bash_colors["bblack"]="\033[1;30m"
bash_colors["bred"]="\033[1;31m"
bash_colors["bgreen"]="\033[1;32m"
bash_colors["byellow"]="\033[1;33m"
bash_colors["bblue"]="\033[1;34m"
bash_colors["bpurple"]="\033[1;35m"
bash_colors["bcyan"]="\033[1;36m"
bash_colors["bwhite"]="\033[1;37m"
bash_colors["iblack"]="\033[0;90m"
bash_colors["ired"]="\033[0;91m"
bash_colors["igreen"]="\033[0;92m"
bash_colors["iyellow"]="\033[0;93m"
bash_colors["iblue"]="\033[0;94m"
bash_colors["ipurple"]="\033[0;95m"
bash_colors["icyan"]="\033[0;96m"
bash_colors["iwhite"]="\033[0;97m"
bash_colors["biblack"]="\033[1;90m"
bash_colors["bired"]="\033[1;91m"
bash_colors["bigreen"]="\033[1;92m"
bash_colors["biyellow"]="\033[1;93m"
bash_colors["biblue"]="\033[1;94m"
bash_colors["bipurple"]="\033[1;95m"
bash_colors["bicyan"]="\033[1;96m"
bash_colors["biwhite"]="\033[1;97m"
bash_colors["reset"]="\033[0m"
elif [ -n "$ZSH_VERSION" ]; then
typeset -A zsh_colors
zsh_colors=(
[black]="%F{black}"
[red]="%F{red}"
[green]="%F{green}"
[yellow]="%F{yellow}"
[blue]="%F{blue}"
[purple]="%F{magenta}"
[cyan]="%F{cyan}"
[white]="%F{white}"
[bblack]="%F{black}%B"
[bred]="%F{red}%B"
[bgreen]="%F{green}%B"
[byellow]="%F{yellow}%B"
[bblue]="%F{blue}%B"
[bpurple]="%F{magenta}%B"
[bcyan]="%F{cyan}%B"
[bwhite]="%F{white}%B"
[iblack]="%F{black}"
[ired]="%F{red}"
[igreen]="%F{green}"
[iyellow]="%F{yellow}"
[iblue]="%F{blue}"
[ipurple]="%F{magenta}"
[icyan]="%F{cyan}"
[iwhite]="%F{white}"
[biblack]="%F{black}%B"
[bired]="%F{red}%B"
[bigreen]="%F{green}%B"
[biyellow]="%F{yellow}%B"
[biblue]="%F{blue}%B"
[bipurple]="%F{magenta}%B"
[bicyan]="%F{cyan}%B"
[biwhite]="%F{white}%B"
[reset]="%f%b"
)
fi
download_file_from_github () {
local GITHUB_TOKEN=""
local REPO_OWNER=""
local REPO_NAME=""
local FILE_PATH=""
local BRANCH="main"
local OUTPUT_FILE=""
local TIMEOUT=600
local PRIVATE=false
local DRY_RUN=false
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
if [[ -z "$REPO_OWNER" || -z "$REPO_NAME" || -z "$FILE_PATH" ]]; then
echo "Usage: download_file_from_github --repo_owner <OWNER> --repo_name <REPO> --file_path <PATH> [--branch <BRANCH>] [--output_file <OUTPUT_FILE>] [--timeout <SECONDS>] [--private] [--dry-run]"
return 1
fi
OUTPUT_FILE="${OUTPUT_FILE:-$(basename "$FILE_PATH")}"
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
if [[ "$DRY_RUN" == true ]]; then
echo "Dry-run: ${curl_cmd[@]}"
return 0
fi
if "${curl_cmd[@]}"; then
echo "File downloaded successfully to $OUTPUT_FILE."
return 0
else
echo "[ERROR] Failed to download the file."
return 1
fi
}
download_directory_from_github() {
local github_token=""
local repo_owner=""
local repo_name=""
local dir_path=""
local branch="main"
local output_dir=""
local private=false
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
if [[ -z "$repo_owner" || -z "$repo_name" || -z "$dir_path" ]]; then
echo "Error: Missing required parameters."
echo "Usage: download_directory_from_github --repo_owner <owner> --repo_name <name> --dir_path <directory> [--branch <branch>] [--output_dir <directory>] [--private]"
return 1
fi
output_dir="${output_dir:-$dir_path}"
local api_url="https://api.github.com/repos/$repo_owner/$repo_name/contents/$dir_path?ref=$branch"
local curl_cmd="curl -L"
if $private; then
if [[ -z "$github_token" ]]; then
echo "Error: GitHub token is required for private repositories."
return 1
fi
curl_cmd+=" -H \"Authorization: token $github_token\""
fi
curl_cmd+=" -H \"Accept: application/vnd.github.v3.raw\" \"$api_url\""
mkdir -p "$output_dir" || { echo "Failed to create output directory $output_dir"; return 1; }
eval "$curl_cmd" -o "$output_dir/$dir_path.zip"
if [[ $? -eq 0 ]]; then
echo "Directory downloaded successfully to $output_dir."
return 0
else
echo "Failed to download the directory."
return 1
fi
}
git_clone_or_pull() {
local repo_url=""
local target_dir=""
local add_to_gitignore="false"
local clean="false"
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
if [[ -z "$repo_url" ]]; then
echo "Error: --repo_url is required"
return 1
fi
local org_repo_name
org_repo_name=$(basename "$repo_url" .git)
local repo_dir="${target_dir:-$org_repo_name}"
if [ -d "$repo_dir" ]; then
echo "Repository '$org_repo_name' already exists."
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
if [ "$add_to_gitignore" == "true" ]; then
[ -f .gitignore ] && grep -q "^${repo_dir}$" .gitignore || echo "$repo_dir" >> .gitignore
fi
return 0
}
get_url() {
local url=""
local dest=""
local overwrite=false
local usage="Usage: get_url -u <url> -d <destination_file> [-o] [-h]
-h                : Show this help message
-u <url>          : URL to fetch the file from
-d <destination_file>: Local file to save the downloaded content
-o                : Prompt for overwrite if the file has changed"
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
if [[ -z "$url" || -z "$dest" ]]; then
echo "Both URL and destination file are required."
echo "$usage"
return 1
fi
echo "Fetching $url..."
temp_file=$(mktemp)
if curl -fsSL "$url" -o "$temp_file"; then
if [[ -f "$dest" ]]; then
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
lineinfile() {
local file line action disable_idempotency="false" output_file position="end"
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
if [[ -z "$file" || -z "$line" ]]; then
echo "Usage: lineinfile -f <file> -l <line> [-a | -r] [-p <beginning|end>] [-d] [-o <output_file>]" >&2
return 1
fi
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
remove_line() {
if grep -qF -- "$line" "$file"; then
sed -i "/^$(echo "$line" | sed 's/[\/&]/\\&/g')$/d" "$file"
log_debug "Line removed: $line"
else
log_debug "Line not found: $line"
fi
}
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
_echo_colored() {
local COLOR=${1}
local COLORED_CONTENT=${2}
local NONCOLORED_CONTENT=${3:-""} # non-colored content goes in here
if [ -n "$BASH_VERSION" ]; then
echo -e "${bash_colors[${COLOR}]}${COLORED_CONTENT}\e[0m ${NONCOLORED_CONTENT}"
elif [ -n "$ZSH_VERSION" ]; then
print -P "${zsh_colors[${COLOR}]}${COLORED_CONTENT}%f ${NONCOLORED_CONTENT}"
fi
}
_debug_colored() {
local COLOR=${1}
local LEVEL=${2}
local NOW=$(date +"%Y-%m-%d %H:%M:%S.%3N")
local CALLER_SCRIPT=""
shift 2
if [[ -z "$PS1"  && -n "$DEBUG" ]]; then
CALLER_SCRIPT="$(basename "$(caller 1)") "
fi
_echo_colored ${COLOR} "[${NOW}] [${LEVEL}]" "${CALLER_SCRIPT}$@"
}
get_log_level_num() {
case "$1" in
DEBUG) echo 1 ;;
INFO) echo 2 ;;
WARN) echo 3 ;;
ERROR) echo 4 ;;
FATAL) echo 5 ;;
*) echo 0 ;;
esac
}
should_log() {
local message_level="$1"
local current_level="${BASH_LOGLEVEL:-INFO}"  # Default to INFO if BASH_LOGLEVEL is not set
local message_level_num
local current_level_num
message_level_num=$(get_log_level_num "$message_level")
current_level_num=$(get_log_level_num "$current_level")
if [ "$message_level_num" -ge "$current_level_num" ]; then
return 0
else
return 1
fi
}
log_info(){
should_log INFO && _echo_colored green [INFO] "$@" >&2 || true
}
log_info2(){
should_log INFO && _echo_colored cyan [INFO] "$@" >&2 || true
}
log_debug(){
should_log DEBUG && _echo_colored icyan [DEBUG] "$@" >&2 || true
}
log_warn(){
should_log WARN && _echo_colored biyellow [WARN] "$@" >&2 || true
}
log_error(){
should_log ERROR && _echo_colored bired [ERROR] "$@" >&2 || true
}
log_abort(){
should_log ABORT && _echo_colored bipurple [ABORT] "$@" >&2 || true
exit 1
}
log_info_stdout(){
should_log INFO && _echo_colored green [INFO] "$@" || true
}
log_debug_stout(){
should_log DEBUG && _echo_colored icyan [DEBUG] "$@" || true
}
log_warn_stdout(){
should_log WARN && _echo_colored biyellow [WARN] "$@" || true
}
log_error_stdout(){
should_log ERROR && _echo_colored bired [ERROR] "$@" || true
}
log_abort_stdout(){
should_log ABORT && _echo_colored bipurple [ABORT] "$@" || true
exit 1
}
log_ts_info(){
should_log INFO && _debug_colored green INFO "$@" >&2 || true
}
log_ts_info2(){
should_log INFO && _debug_colored cyan INFO "$@" >&2 || true
}
log_ts_debug(){
should_log DEBUG && _debug_colored icyan DEBUG "$@" >&2 || true
}
log_ts_warn(){
should_log WARN &&  _debug_colored biyellow WARN "$@" >&2 || true
}
log_ts_error(){
should_log ERROR && _debug_colored bired ERROR "$@" >&2 || true
}
log_ts_abort(){
should_log ABORT && _debug_colored bipurple ABORT "$@" >&2 || true
exit 1
}
parse_yaml() {
local parse_string="$1"
local input_file="$2"
local output_mode="${3:-stdout}"
local outfile_path="$4"
if [[ -z "$parse_string" || -z "$input_file" ]]; then
echo "Usage: parse_yaml <parse_string> <input_file> [output_mode] [outfile_path]" >&2
return 1
fi
local parsed_output
parsed_output=$(yq -r "$parse_string" <(grep -v '^#' "$input_file") 2>/dev/null)
if [[ $? -ne 0 ]]; then
log_error "Failed to parse YAML file."
return 1
fi
case "$output_mode" in
inline)
echo "$parsed_output" > "$input_file"
;;
outfile)
if [[ -n "$outfile_path" ]]; then
echo "$parsed_output" > "$outfile_path"
else
log_error "Error: Outfile path not specified."
return 1
fi
;;
stdout|*)
echo "$parsed_output"
;;
esac
return 0
}
function pcurl_wrapper {
local url="$1"
shift
local additional_params="$@"
local curl_cmd="curl"
local proxy_cmd=""
local cert_cmd=""
if [ "${USE_PROXY,,}" == "true" ]; then
if test_env_variable_defined CERT_BASE64_STRING; then
TEMP_CERT_FILE=$(create_temp_file)
echo "${CERT_BASE64_STRING}" | base64 -d > "${TEMP_CERT_FILE}"
cert_cmd="--cacert ${TEMP_CERT_FILE}"
fi
proxy_cmd="--proxy ${HTTPS_PROXY}"
fi
${curl_cmd} ${proxy_cmd} ${cert_cmd} ${additional_params} "${url}"
if [ -n "${TEMP_CERT_FILE}" ]; then
rm "${TEMP_CERT_FILE}"
fi
}
function ppip_wrapper {
local command="$1"
shift
local additional_params="$@"
local pip_cmd="pip"
local proxy_cmd=""
local cert_cmd=""
local index_url_cmd=""
local repo_url_cmd=""
local trusted_host_cmd=""
if [ "${USE_PROXY,,}" == "true" ]; then
if test_env_variable_defined CERT_BASE64_STRING; then
TEMP_CERT_FILE=$(create_temp_file)
echo "${CERT_BASE64_STRING}" | base64 -d > "${TEMP_CERT_FILE}"
cert_cmd="--cert ${TEMP_CERT_FILE}"
fi
proxy_cmd="--proxy ${HTTPS_PROXY}"
fi
if test_env_variable_defined PYTHON_INDEX_URL; then
index_url_cmd="--index ${PYTHON_INDEX_URL}"
fi
if test_env_variable_defined PYTHON_REPO_URL; then
repo_url_cmd="--index-url ${PYTHON_REPO_URL}"
fi
if test_env_variable_defined PYTHON_TRUSTED_HOST; then
trusted_host_cmd="--trusted-host ${PYTHON_TRUSTED_HOST}"
fi
${pip_cmd} ${proxy_cmd} ${cert_cmd} ${index_url_cmd} ${repo_url_command} ${trusted_host_cmd} ${command} ${additional_params}
if [ -n "${TEMP_CERT_FILE}" ]; then
rm "${TEMP_CERT_FILE}"
fi
}
function pwget_wrapper {
local url="$1"
shift
local additional_params="$@"
local wget_cmd="wget"
local proxy_cmd=""
local cert_cmd=""
if [ "${USE_PROXY,,}" == "true" ]; then
if test_env_variable_defined CERT_BASE64_STRING; then
TEMP_CERT_FILE=$(create_temp_file)
echo "${CERT_BASE64_STRING}" | base64 -d > "${TEMP_CERT_FILE}"
cert_cmd="--ca-certificate=${TEMP_CERT_FILE}"
fi
proxy_cmd="--proxy=${HTTPS_PROXY}"
fi
${wget_cmd} ${proxy_cmd} ${cert_cmd} ${additional_params} "${url}"
if [ -n "${TEMP_CERT_FILE}" ]; then
rm "${TEMP_CERT_FILE}"
fi
}
function pgit_wrapper {
local git_command="$1"
shift
local args="$@"
local git_cmd="git"
local proxy_cmd=""
local cert_cmd=""
local ssh_cmd=""
if [ "${USE_PROXY,,}" == "true" ]; then
if test_env_variable_defined CERT_BASE64_STRING; then
TEMP_CERT_FILE=$(create_temp_file)
echo "${CERT_BASE64_STRING}" | base64 -d > "${TEMP_CERT_FILE}"
cert_cmd="http.sslCAInfo=${TEMP_CERT_FILE}"
fi
proxy_cmd="http.proxy=${HTTPS_PROXY}"
fi
if test_env_variable_defined SSH_PRIVATE_KEY_PATH; then
ssh_cmd="GIT_SSH_COMMAND='ssh -i ${SSH_PRIVATE_KEY_PATH}'"
fi
${git_cmd} config --global ${proxy_cmd}
${git_cmd} config --global ${cert_cmd}
if [ -n "${ssh_cmd}" ]; then
eval "${ssh_cmd} ${git_cmd} ${git_command} ${args}"
else
${git_cmd} ${git_command} ${args}
fi
if [ -n "${TEMP_CERT_FILE}" ]; then
rm "${TEMP_CERT_FILE}"
fi
}
vault() {
local action=""
local file=""
local password_file=""
local output_file=""
local usage="Usage: vault {-e|-d} -f <file|directory> [-p <password_file>] [-o <output_file>] [-h]
-e                : Encrypt the file or directory
-d                : Decrypt the file or directory
-f <file|directory>: Specify the file or directory to encrypt/decrypt
-p <password_file>: Optional file containing the password
-o <output_file>  : Optional output file for the result
-h                : Show this help message"
while getopts ":edf:p:o:h" opt; do
case $opt in
e) action="encrypt" ;;
d) action="decrypt" ;;
f) file="$OPTARG" ;;
p) password_file="$OPTARG" ;;
o) output_file="$OPTARG" ;;
h) echo "$usage"; return 0 ;;
\?) echo "Invalid option: -$OPTARG" >&2; echo "$usage"; return 1 ;;
:) echo "Option -$OPTARG requires an argument." >&2; echo "$usage"; return 1 ;;
esac
done
if [[ -z "$action" ]]; then
echo "You must specify either -e (encrypt) or -d (decrypt)."
echo "$usage"
return 1
fi
if [[ -z "$file" ]]; then
echo "File or directory is required."
echo "$usage"
return 1
fi
local password=""
if [[ -n "$password_file" ]]; then
password=$(<"$password_file")
else
read -sp "Enter password: " password
echo
fi
encrypt() {
local output_file_final="${output_file:-${file}.enc}"
if [[ -d "$file" ]]; then
tar -czf "${file}.tar.gz" -C "$(dirname "$file")" "$(basename "$file")"
openssl enc -aes-256-cbc -salt -pbkdf2 -in "${file}.tar.gz" -out "$output_file_final" -pass pass:"$password"
rm "${file}.tar.gz"
else
openssl enc -aes-256-cbc -salt -pbkdf2 -in "$file" -out "$output_file_final" -pass pass:"$password"
fi
if [[ $? -eq 0 ]]; then
echo "File/Directory encrypted successfully: $output_file_final"
else
echo "Encryption failed!"
fi
}
decrypt() {
local output_file_final="${output_file:-${file%.enc}}"
if [[ "$file" == *.enc && -d "$file" ]]; then
openssl enc -d -aes-256-cbc -pbkdf2 -in "$file" -out "${output_file_final}.tar.gz" -pass pass:"$password"
tar -xzf "${output_file_final}.tar.gz" -C "$(dirname "$output_file_final")"
rm "${output_file_final}.tar.gz"
else
openssl enc -d -aes-256-cbc -pbkdf2 -in "$file" -out "$output_file_final" -pass pass:"$password"
fi
if [[ $? -eq 0 ]]; then
echo "File/Directory decrypted successfully: $output_file_final"
else
echo "Decryption failed!"
fi
}
if [[ "$action" == "encrypt" ]]; then
encrypt
elif [[ "$action" == "decrypt" ]]; then
decrypt
else
echo "Invalid action. Use '-e' for encrypt or '-d' for decrypt."
return 1
fi
}
