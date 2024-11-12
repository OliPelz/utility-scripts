############################################################################
#
# now define all functions which need to access those colored functions
#
############################################################################


# private function, not to be exposed on the cli
_echo_colored() {
    local COLOR=${1}
    local COLORED_CONTENT=${2}
    local NONCOLORED_CONTENT=${3:-""} # non-colored content goes in here


	if [ -n "$BASH_VERSION" ]; then
		# bash coloring prompt, \e[0m is COLOROFF
		echo -e "${bash_colors[${COLOR}]}${COLORED_CONTENT}\e[0m ${NONCOLORED_CONTENT}"
	elif [ -n "$ZSH_VERSION" ]; then
		# zsh coloring prompt
		# %f is COLOROFF
		print -P "${zsh_colors[${COLOR}]}${COLORED_CONTENT}%f ${NONCOLORED_CONTENT}"
	fi
}

# private function, not to be exposed on the cli
_debug_colored() {
    local COLOR=${1}
    local LEVEL=${2}
    local NOW=$(date +"%Y-%m-%d %H:%M:%S.%3N")
    local CALLER_SCRIPT=""
    shift 2

    # [2016-01-28 18:06:40.946] [INFO] upd-init - ein fehler ist aufgetreten

    # ignore caller on interactive shell
    if [[ -z "$PS1"  && -n "$DEBUG" ]]; then
        CALLER_SCRIPT="$(basename "$(caller 1)") "
    fi

	_echo_colored ${COLOR} "[${NOW}] [${LEVEL}]" "${CALLER_SCRIPT}$@"
}

# Get numeric log level based on string value
# so we can do math operations like "greater than"
get_log_level_num() {
    case "$1" in
        DEBUG) echo 1 ;;
        INFO) echo 2 ;;
        WARN) echo 3 ;;
        ERROR) echo 4 ;;
        FATAL) echo 5 ;;
        *) echo 0 ;;  # Unknown log level
    esac
}

# Check if the current message level should be printed
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

: '
Bash Logger System

ShortDesc: A logging system for Bash scripts with configurable log levels using an environment variable.

Description:
This logging system provides functions for different log levels (DEBUG, INFO, WARN, ERROR, FATAL), 
which can be controlled using the `BASH_LOGLEVEL` environment variable. If a log level is set, 
the corresponding log messages will be printed.

Log Levels: (from less to more severe)
- DEBUG: Detailed information, typically for diagnosing problems.
- INFO: Informational messages that highlight the progress of the script.
- WARN: Potentially harmful situations.
- ERROR: Error events that might still allow the script to continue.
- FATAL: Severe errors that will likely cause the script to abort.

Precedence is:
FATAL: will only print FATAL log level messages
ERROR: will print FATAL and error messages
WARN: will print FATAL, ERROR and WARN
...
DEBUG will print all log levels

Environment Variable:
- BASH_LOGLEVEL: Controls which log levels are printed. Supported values: DEBUG, INFO, WARN, ERROR, FATAL.
  Messages of levels equal to or more severe than the current level will be printed.

Example Usage:
BASH_LOGLEVEL="DEBUG"
print_debug "This is a debug message."
print_info "Informational message."
print_warn "Warning message."
print_error "Error message."
print_fatal "Fatal error message."
'

############################################################################
#
# log_XXX - print log messages based on BASH_LOGLEVEL (like log4j)
#           to stderr
#
############################################################################

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

############################################################################
#
# log_XXX - print log messages based on BASH_LOGLEVEL (like log4j)
#           to stdout
#
############################################################################

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

############################################################################
#
# log_ts_XXX - as log_XXX but also printing out timestamp
#              to stderr
#
############################################################################

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
