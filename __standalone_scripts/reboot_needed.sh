#!/usr/bin/env bash

# import common.sh
s=${BASH_SOURCE:-${(%):-%x}} d=$(cd "$(dirname "$s")" && pwd) && source $d/common.sh

# Function to check if a reboot is needed on Debian/Ubuntu
check_reboot_needed_debian() {
    if [ -f /var/run/reboot-required ]; then
	fc_log_info "[Debian/Ubuntu] Reboot is required.$"
        return 0
    fi
    fc_log_info2 "[Debian/Ubuntu] No reboot required."
    return 1
}

# Function to check if a reboot is needed on RHEL/Fedora
check_reboot_needed_rhel() {
    if command -v needs-restarting &>/dev/null; then
        # Use needs-restarting to check if reboot is required
        if needs-restarting -r &>/dev/null; then
            fc_log_info "[RHEL/Fedora] Reboot is required."
            return 0
        fi
    else
        fc_log_warn "[RHEL/Fedora] needs-restarting tool not found, cannot check."
        fc_log_warn "[RHEL/Fedora] please install needs-restarting manually"
    fi
    fc_log_info2 "[RHEL/Fedora] No reboot required."
    return 1
}

# Function to check if a reboot is needed on Arch-based systems
check_reboot_needed_arch() {
    # Check if kernel, glibc, or systemd has been updated
    local reboot_needed=1

    # Check kernel
    running_kernel=$(uname -r)
    installed_kernel=$(pacman -Q linux | awk '{print $2}')
    if vercmp "$installed_kernel" "$running_kernel" != 0; then
        fc_log_info "[Arch] Kernel version changed, reboot is required."
        reboot_needed=0
    fi

    # Check glibc (libc)
    libc_installed_version=$(pacman -Q glibc | awk '{print $2}')
    libc_running_version=$(ldd --version | head -n 1 | awk '{print $NF}')
    if [[ "$libc_installed_version" != "$libc_running_version" ]]; then
        fc_log_info "[Arch] glibc has been updated, reboot is required."
        reboot_needed=0
    fi

    # Check systemd
    systemd_installed_version=$(pacman -Q systemd | awk '{print $2}')
    systemd_running_version=$(systemctl --version | head -n 1 | awk '{print $2}')
    if [[ "$systemd_installed_version" != "$systemd_running_version" ]]; then
        fc_log_info "[Arch] systemd has been updated, reboot is required."
        reboot_needed=0
    fi

    if [ $reboot_needed -eq 0 ]; then
        return 0
    fi

    fc_log_info2 "[Arch] No reboot required."
    return 1
}

# Main logic to detect OS and check for reboot requirements
main() {
    # Detect OS
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        case "$ID" in
            debian|ubuntu)
                check_reboot_needed_debian
                exit $?
                ;;
            rhel|centos|fedora)
                check_reboot_needed_rhel
                exit $?
                ;;
            arch|manjaro)
                check_reboot_needed_arch
                exit $?
                ;;
            *)
                fc_log_error "[ERROR] Unsupported OS: $ID"
                exit 2
                ;;
        esac
    else
        fc_log_error "[ERROR] Unable to determine OS. /etc/os-release is missing."
        exit 2
    fi
}

# Run the main function
main
