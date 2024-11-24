#!/usr/bin/env bash


# Script to connect to Wi-Fi using iwd (typical arch tool)
# Usage:
# ./connect_wifi.sh "SSID" "/path/to/password_file"
# 
# or with env var:
#
# WIFI_PASSWORD=xxxx
# ./connect_wifi.sh "SSID" "" "WIFI_PASSWORD"

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Please run with sudo or as root user"
   exit 1
fi

# Check for sufficient arguments
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <SSID> [password_file] [password_env_var]"
  exit 1
fi

SSID="$1"              # Wi-Fi network name (SSID)
PASSWORD_FILE="$2"      # Optional: Path to the password file
PASSWORD_ENV="$3"       # Optional: Environment variable with the password
DEVICE_NAME=wlan0


# Determine the password
if [[ -n "$PASSWORD_ENV" ]]; then
  PASSWORD="${!PASSWORD_ENV}"
elif [[ -f "$PASSWORD_FILE" ]]; then
  PASSWORD=$(<"$PASSWORD_FILE")
else
  echo "Error: Provide a password file or set an environment variable for the password."
  exit 1
fi

# Enable iwd's DHCP client
echo "Configuring iwd for DHCP..."
mkdir -p /etc/iwd
cat <<EOL > /etc/iwd/main.conf
[General]
EnableNetworkConfiguration=true
EOL

# Restart iwd to apply changes
echo "Restarting iwd service to apply DHCP configuration..."
systemctl restart iwd || { echo "Failed to restart iwd."; exit 1; }

sleep 2

# Start iwd service if not already running
if ! systemctl is-active --quiet iwd; then
  echo "Starting iwd service..."
  systemctl start iwd || { echo "Failed to start iwd."; exit 1; }
fi

sleep 2
# Connect to the Wi-Fi network
echo "Connecting to Wi-Fi network: $SSID..."
iwctl --passphrase "$PASSWORD" station "$DEVICE_NAME" connect "$SSID" || {
  echo "Failed to connect to Wi-Fi network $SSID."
  exit 1
}

sleep 2

# Configure DNS (set to Google DNS in /etc/resolv.conf)
echo "Configuring DNS resolution..."
echo "nameserver 8.8.8.8" > /etc/resolv.conf || {
  echo "Failed to configure DNS."
  exit 1
}
sleep 2

ping -c 2 thevaluable.dev

echo "Successfully connected to Wi-Fi network: $SSID"
exit 0
