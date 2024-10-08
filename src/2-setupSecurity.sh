#!/bin/bash

# Function to display an error message and exit
error_exit() {
    echo "$1" >&2
    exit 1
}

# Check if the script is running as root
if [[ "$(id -u)" -ne 0 ]]; then
    error_exit "This script must be run as root or with sudo."
fi

# 1. Regular system updates
echo "Updating the system..."
apt update && apt upgrade -y || error_exit "Failed to update the system."

# Enable automatic security updates
echo "Enabling automatic security updates..."
apt install unattended-upgrades -y || error_exit "Failed to install unattended-upgrades."
dpkg-reconfigure --priority=low unattended-upgrades || error_exit "Failed to configure unattended-upgrades."

# 2. Configure a Firewall (UFW)
echo "Configuring the firewall with UFW..."
apt install ufw -y || error_exit "Failed to install UFW."
ufw default deny incoming || error_exit "Failed to set default deny incoming policy."
ufw default allow outgoing || error_exit "Failed to set default allow outgoing policy."
ufw allow ssh || error_exit "Failed to allow SSH in UFW."
ufw --force enable || error_exit "Failed to enable UFW."

# Ensure UFW is enabled on boot
echo "Enabling UFW to start on boot..."
systemctl enable ufw || error_exit "Failed to enable UFW on boot."

# 3. Disable SSH access for root
echo "Disabling SSH access for root..."
sed -i 's/^#\?PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config || error_exit "Failed to disable root SSH access."
systemctl restart sshd || error_exit "Failed to restart SSH service."

# 4. Change the default SSH port
NEW_SSH_PORT=2222  # Change this value to the desired port
echo "Changing the SSH port to $NEW_SSH_PORT..."
sed -i "s/^#\?Port .*/Port $NEW_SSH_PORT/" /etc/ssh/sshd_config || error_exit "Failed to change SSH port."
ufw allow "$NEW_SSH_PORT/tcp" || error_exit "Failed to allow new SSH port in UFW."
ufw delete allow ssh || error_exit "Failed to remove default SSH port allowance."
systemctl restart sshd || error_exit "Failed to restart SSH service."

# Disable password authentication for SSH
echo "Disabling password authentication for SSH..."
sed -i 's/^#\?PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config || error_exit "Failed to disable SSH password authentication."
systemctl restart sshd || error_exit "Failed to restart SSH service."

# 5. Install and configure Fail2Ban
echo "Installing Fail2Ban..."
apt install fail2ban -y || error_exit "Failed to install Fail2Ban."

echo "Configuring Fail2Ban..."

# Check if the [sshd] section already exists in /etc/fail2ban/jail.local
if grep -q "^\[sshd\]" /etc/fail2ban/jail.local; then
    echo "Updating existing [sshd] section in Fail2Ban config..."
    sed -i "s/^port = .*/port = $NEW_SSH_PORT/" /etc/fail2ban/jail.local || error_exit "Failed to update SSH port in Fail2Ban config."
else
    echo "Adding [sshd] section to Fail2Ban config..."
    cat <<EOL | tee -a /etc/fail2ban/jail.local > /dev/null
[sshd]
enabled = true
port = $NEW_SSH_PORT
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime = 3600
findtime = 600
ignoreip = 127.0.0.1
EOL
fi

# Restart Fail2Ban to apply the configuration
echo "Restarting Fail2Ban..."
systemctl restart fail2ban || error_exit "Failed to restart Fail2Ban."

# Enable Fail2Ban to start on boot
echo "Enabling Fail2Ban to start on boot..."
systemctl enable fail2ban || error_exit "Failed to enable Fail2Ban on boot."

# Install rkhunter and chkrootkit
echo "Installing rkhunter and chkrootkit..."
apt install rkhunter chkrootkit -y || error_exit "Failed to install rkhunter and chkrootkit."
rkhunter --update || error_exit "Failed to update rkhunter."
rkhunter --propupd || error_exit "Failed to perform rkhunter property update."

# Hardening kernel parameters
echo "Hardening kernel parameters..."
cat <<EOL >> /etc/sysctl.conf
# IP Spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP broadcast requests
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Enable TCP SYN cookies
net.ipv4.tcp_syncookies = 1

# Log Martians
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
EOL

sysctl -p || error_exit "Failed to apply kernel parameter changes."

echo "Security measures successfully applied."
