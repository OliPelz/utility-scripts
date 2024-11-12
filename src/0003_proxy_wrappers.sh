#!/bin/bash

function pcurl_wrapper {
    : '
    Curl Proxy Wrapper

    ShortDesc: A wrapper for the curl command that supports optional proxy and SSL certificate usage.

    Description:
    This function provides a convenient way to execute curl commands with optional proxy settings
    and SSL certificate handling. It takes a URL as the first parameter and any additional curl
    parameters as subsequent arguments. If proxy usage is enabled via the USE_PROXY environment variable,
    it configures curl to use the specified proxy. If a base64-encoded SSL certificate is provided,
    it decodes it to a temporary file for use with curl.

    Parameters:
    - url: The URL to be requested with curl.
    - additional_params: Additional parameters to pass to the curl command (optional).

    Environment Variables:
    - USE_PROXY: Set to "true" to enable proxy usage.
    - HTTPS_PROXY: The proxy URL to use if USE_PROXY is true.
    - CERT_BASE64_STRING: Base64-encoded SSL certificate string for verifying proxy connections (optional).

    Returns:
    - 0: Success (curl command executed successfully)
    - 1: Failure (if the curl command fails)

    Example Usage:
    pcurl_wrapper "https://example.com" --verbose --header "User-Agent: CustomAgent"
    '
    local url="$1"
    shift
    local additional_params="$@"

    local curl_cmd="curl"
    local proxy_cmd=""
    local cert_cmd=""

    if [ "${USE_PROXY,,}" == "true" ]; then
        if test_env_variable_defined CERT_BASE64_STRING; then
            # Create a temporary file for the cert
            TEMP_CERT_FILE=$(create_temp_file)
            echo "${CERT_BASE64_STRING}" | base64 -d > "${TEMP_CERT_FILE}"
            cert_cmd="--cacert ${TEMP_CERT_FILE}"
        fi
        proxy_cmd="--proxy ${HTTPS_PROXY}"
    fi

    # Execute curl with the appropriate options
    ${curl_cmd} ${proxy_cmd} ${cert_cmd} ${additional_params} "${url}"

    # Clean up temporary cert file if created
    if [ -n "${TEMP_CERT_FILE}" ]; then
        rm "${TEMP_CERT_FILE}"
    fi
}

# additionally lets you define alternative pypi repository address and trusted hosts
# using other env variables: PYTHON_INDEX_URL, PYTHON_REPO_URL and PYTHON_TRUSTED_HOST


function ppip_wrapper {
  : '
    Pip Proxy Wrapper

    ShortDesc: A wrapper for the pip command that supports optional proxy and SSL certificate usage.

    Description:
    This function provides a way to execute pip commands with optional proxy settings, SSL certificate handling, 
    and custom Python package index configurations. It takes the pip command as the first parameter followed 
    by any additional parameters needed for pip. If proxy usage is enabled via the USE_PROXY environment variable, 
    it configures pip to use the specified proxy. If a base64-encoded SSL certificate is provided, it decodes 
    it to a temporary file for use with pip. The function also allows specifying a custom index URL, repository URL, 
    and trusted host.

    Parameters:
    - command: The pip command to be executed (e.g., install, uninstall).
    - additional_params: Additional parameters to pass to the pip command (optional).

    Environment Variables:
    - USE_PROXY: Set to "true" to enable proxy usage.
    - HTTPS_PROXY: The proxy URL to use if USE_PROXY is true.
    - CERT_BASE64_STRING: Base64-encoded SSL certificate string for verifying proxy connections (optional).
    - PYTHON_INDEX_URL: Custom Python package index URL (optional).
    - PYTHON_REPO_URL: Custom repository URL (optional).
    - PYTHON_TRUSTED_HOST: Trusted host for pip operations (optional).

    Returns:
    - 0: Success (pip command executed successfully)
    - 1: Failure (if the pip command fails)

    Example Usage:
    ppip_wrapper "install" "requests" --upgrade
    '
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
            # Create a temporary file for the cert
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

    # Execute pip with the appropriate options
    ${pip_cmd} ${proxy_cmd} ${cert_cmd} ${index_url_cmd} ${repo_url_command} ${trusted_host_cmd} ${command} ${additional_params}

    # Clean up temporary cert file if created
    if [ -n "${TEMP_CERT_FILE}" ]; then
        rm "${TEMP_CERT_FILE}"
    fi
}

function pwget_wrapper {
   : '
    Wget Proxy Wrapper

    ShortDesc: A wrapper for the wget command that supports optional proxy and SSL certificate usage.

    Description:
    This function provides a convenient way to execute wget commands with optional proxy settings 
    and SSL certificate handling. It takes a URL as the first parameter and any additional wget 
    parameters as subsequent arguments. If proxy usage is enabled via the USE_PROXY environment variable, 
    it configures wget to use the specified proxy. If a base64-encoded SSL certificate is provided, 
    it decodes it to a temporary file for use with wget.

    Parameters:
    - url: The URL to be retrieved with wget.
    - additional_params: Additional parameters to pass to the wget command (optional).

    Environment Variables:
    - USE_PROXY: Set to "true" to enable proxy usage.
    - HTTPS_PROXY: The proxy URL to use if USE_PROXY is true.
    - CERT_BASE64_STRING: Base64-encoded SSL certificate string for verifying proxy connections (optional).

    Returns:
    - 0: Success (wget command executed successfully)
    - 1: Failure (if the wget command fails)

    Example Usage:
    pwget_wrapper "https://example.com/file.zip" --output-document=myfile.zip
    '

    local url="$1"
    shift
    local additional_params="$@"

    local wget_cmd="wget"
    local proxy_cmd=""
    local cert_cmd=""

    if [ "${USE_PROXY,,}" == "true" ]; then
        if test_env_variable_defined CERT_BASE64_STRING; then
            # Create a temporary file for the cert
            TEMP_CERT_FILE=$(create_temp_file)
            echo "${CERT_BASE64_STRING}" | base64 -d > "${TEMP_CERT_FILE}"
            cert_cmd="--ca-certificate=${TEMP_CERT_FILE}"
        fi
        proxy_cmd="--proxy=${HTTPS_PROXY}"
    fi

    # Execute wget with the appropriate options
    ${wget_cmd} ${proxy_cmd} ${cert_cmd} ${additional_params} "${url}"

    # Clean up temporary cert file if created
    if [ -n "${TEMP_CERT_FILE}" ]; then
        rm "${TEMP_CERT_FILE}"
    fi
}

function pgit_wrapper {
    : '
    Git Proxy Wrapper

    ShortDesc: A wrapper for git commands that supports optional proxy, SSL certificate, and SSH private key usage.

    Description:
    This function wraps git commands to enable operations behind a proxy with SSL certificate handling and SSH
    private key support. It accepts the git command and arguments, checks for proxy settings, SSL certificates,
    and an SSH private key, and then configures git accordingly.

    Parameters:
    - git_command: The git command to be executed (e.g., clone, pull, push).
    - args: Additional arguments for the git command.

    Environment Variables:
    - USE_PROXY: Set to "true" to enable proxy usage.
    - HTTPS_PROXY: The proxy URL to use if USE_PROXY is true.
    - CERT_BASE64_STRING: Base64-encoded SSL certificate string for verifying proxy connections (optional).
    - SSH_PRIVATE_KEY_PATH: Path to the SSH private key for secure access (optional).

    Returns:
    - 0: Success (git command executed successfully)
    - 1: Failure (if the git command fails)

    Example Usage:
    pgit_wrapper "clone" "https://github.com/example/repo.git"
    pgit_wrapper "pull" "origin main"
    '

    local git_command="$1"
    shift
    local args="$@"

    local git_cmd="git"
    local proxy_cmd=""
    local cert_cmd=""
    local ssh_cmd=""

    # Set up proxy if needed
    if [ "${USE_PROXY,,}" == "true" ]; then
        if test_env_variable_defined CERT_BASE64_STRING; then
            # Create a temporary file for the cert
            TEMP_CERT_FILE=$(create_temp_file)
            echo "${CERT_BASE64_STRING}" | base64 -d > "${TEMP_CERT_FILE}"
            cert_cmd="http.sslCAInfo=${TEMP_CERT_FILE}"
        fi
        proxy_cmd="http.proxy=${HTTPS_PROXY}"
    fi

    # Set up SSH key if provided
    if test_env_variable_defined SSH_PRIVATE_KEY_PATH; then
        ssh_cmd="GIT_SSH_COMMAND='ssh -i ${SSH_PRIVATE_KEY_PATH}'"
    fi

    # Configure git with proxy and certificate settings
    ${git_cmd} config --global ${proxy_cmd}
    ${git_cmd} config --global ${cert_cmd}

    # Execute git command with SSH command if necessary
    if [ -n "${ssh_cmd}" ]; then
        eval "${ssh_cmd} ${git_cmd} ${git_command} ${args}"
    else
        ${git_cmd} ${git_command} ${args}
    fi

    # Clean up temporary cert file if created
    if [ -n "${TEMP_CERT_FILE}" ]; then
        rm "${TEMP_CERT_FILE}"
    fi
}
