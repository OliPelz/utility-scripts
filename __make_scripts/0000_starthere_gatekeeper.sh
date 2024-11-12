#!/usr/bin/env bash
#
# the whole thing starts here
# this script acts as a gatekeeper to test and check VERY mandantory definitions
# before anything else can be started
#
# after running this script we can be assured that all mandantory stuff is defined
# and we dont need to do those checks in all later scripts for it anymore :)
#
# some helper functions


#########################################################################################################
## importing section
#########################################################################################################

temp_test_env_variable_defined() {
        ARG=$1
        CMD='test -z ${'$ARG'+x}'
        if eval $CMD;
        then
                return 1 # variable is not defined or empty string
        else
                return 0  # variable is set
        fi
}
has_errors=false
# first check before sourcing
if ! temp_test_env_variable_defined DOTFILES_REPO_FULL_PATH; then
    abort_color="\033[1;95m" # same as in my colored.sh file for ABORT log event
    echo -e "${abort_color}[ABORT]\033[0m check failed, mandantory environment variable DOTFILES_REPO_FULL_PATH is not defined, bailing out"
    has_error=true
fi
# now source some external functions
source ${DOTFILES_REPO_FULL_PATH}/src/0001_common.sh
source ${DOTFILES_REPO_FULL_PATH}/src/0002_colored.sh
source ${DOTFILES_REPO_FULL_PATH}/src/0003_logging.sh

#########################################################################################################
## now we can use all my external functions
#########################################################################################################

# TODO: if you need further tests, add them here

if [ "${has_error}" == "true" ]; then
	exit 1
fi

log_info "all tests passed"
exit 0
