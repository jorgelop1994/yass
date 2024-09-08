#!/bin/bash

# Check if the script is running as root or with sudo
if [ "$(id -u)" -eq 0 ]; then
  echo "This script should not be run as root or with sudo. Please run it as a regular user."
  exit 1
fi

# Install and configure Google Authenticator for 2FA
echo "Installing Google Authenticator..."
sudo apt install libpam-google-authenticator -y

echo "Configuring SSH to use Google Authenticator..."
# Modify PAM to use Google Authenticator
sudo tee -a /etc/pam.d/sshd > /dev/null <<EOL

# Google Authenticator Authentication
auth required pam_google_authenticator.so

EOL

# Configure SSH to require 2FA in addition to a password
sudo sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/#AuthenticationMethods/AuthenticationMethods/' /etc/ssh/sshd_config
sudo sed -i '/AuthenticationMethods/c\AuthenticationMethods publickey,keyboard-interactive' /etc/ssh/sshd_config

echo "Restarting SSH to apply changes... Remember, your new SSH port is 2222"
sudo systemctl restart sshd

# Run google-authenticator for the current user
echo "Setting up Google Authenticator for the current user..."
google-authenticator

echo "Google Authenticator has been successfully configured for the current user."
