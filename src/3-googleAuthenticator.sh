#!/bin/bash

# Function to display an error message and exit
error_exit() {
    echo "$1" >&2
    exit 1
}

# Check if the script is running as root or with sudo
if [[ "$(id -u)" -eq 0 ]]; then
    error_exit "This script should not be run as root or with sudo. Please run it as a regular user."
fi

# Install Google Authenticator for 2FA
echo "Installing Google Authenticator..."
sudo apt update && sudo apt install libpam-google-authenticator -y || error_exit "Failed to install Google Authenticator."

# Modify PAM to use Google Authenticator
echo "Configuring SSH to use Google Authenticator..."
if ! sudo tee -a /etc/pam.d/sshd > /dev/null <<EOL

# Google Authenticator Authentication
auth required pam_google_authenticator.so

EOL
then
    error_exit "Failed to configure PAM for Google Authenticator."
fi

# Configure SSH to require 2FA in addition to a password
echo "Configuring SSH for two-factor authentication..."
sudo sed -i 's/^ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config || error_exit "Failed to enable ChallengeResponseAuthentication."
sudo sed -i 's/^#\?AuthenticationMethods.*/AuthenticationMethods publickey,keyboard-interactive/' /etc/ssh/sshd_config || error_exit "Failed to set AuthenticationMethods."

# Restart SSH to apply changes
echo "Restarting SSH to apply changes..."
sudo systemctl restart sshd || error_exit "Failed to restart SSH service."

# Run Google Authenticator setup for the current user
echo "Setting up Google Authenticator for the current user..."
if ! google-authenticator; then
    error_exit "Failed to set up Google Authenticator for the current user."
fi

echo "Google Authenticator has been successfully configured for the current user."
