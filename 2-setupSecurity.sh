#!/bin/bash

# Check if the script is running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root or with sudo."
    exit 1
fi

# 1. Regular system updates
echo "Updating the system..."
apt update && apt upgrade -y

# Enable automatic security updates
echo "Enabling automatic security updates..."
apt install unattended-upgrades -y
dpkg-reconfigure --priority=low unattended-upgrades

# 2. Configure a Firewall (UFW)
echo "Configuring the firewall with UFW..."
apt install ufw -y
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw enable

# 3. Disable SSH access for root
echo "Disabling SSH access for root..."
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart sshd

# 4. Change the default SSH port
echo "Changing the SSH port..."
NEW_SSH_PORT=2222  # Change this value to the desired port
sed -i "s/#Port 22/Port $NEW_SSH_PORT/" /etc/ssh/sshd_config
ufw allow "$NEW_SSH_PORT/tcp"
ufw delete allow ssh
systemctl restart sshd

# Disable password authentication for SSH
echo "Disabling password authentication for SSH..."
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# 5. Install and configure Fail2Ban
echo "Installing Fail2Ban..."
apt install fail2ban -y

echo "Configuring Fail2Ban..."
# Create a backup of the original configuration file
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Recommended configuration for SSH
cat <<EOL | tee -a /etc/fail2ban/jail.local > /dev/null

[sshd]
enabled = true
port = $NEW_SSH_PORT
filter = sshd
logpath = /var/log/auth.log
maxretry = 5           # Maximum number of failed attempts before banning
bantime = 3600         # Ban time in seconds (1 hour)
findtime = 600         # Time window in seconds to count failed attempts (10 minutes)
ignoreip = 127.0.0.1   # IPs to be ignored; add other trusted IPs as needed

EOL

# Restart Fail2Ban to apply the configuration
echo "Restarting Fail2Ban..."
systemctl restart fail2ban

# Install rkhunter and chkrootkit
echo "Installing rkhunter and chkrootkit..."
apt install rkhunter chkrootkit -y
rkhunter --update
rkhunter --propupd

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

sysctl -p

echo "Security measures successfully applied."
