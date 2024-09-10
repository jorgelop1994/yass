#!/bin/bash

# Function to display an error message and exit
error_exit() {
    echo "$1" >&2
    exit 1
}

# Check if the script is running as root or with sudo
if [[ "$(id -u)" -ne 0 ]]; then
    error_exit "This script must be run as root or with sudo."
fi

# Update and install required dependencies
echo "Updating package information and installing dependencies..."
apt update && apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    gnupg-agent || error_exit "Failed to install dependencies."

# Add Docker’s official GPG key
echo "Adding Docker’s official GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg || error_exit "Failed to add Docker GPG key."

# Set up the stable Docker repository
echo "Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || error_exit "Failed to add Docker repository."

# Update the package index
echo "Updating package index..."
apt update || error_exit "Failed to update package index."

# Install Docker Engine, CLI, and Containerd
echo "Installing Docker Engine, Docker CLI, and containerd..."
apt install -y docker-ce docker-ce-cli containerd.io || error_exit "Failed to install Docker."

# Enable Docker to start on boot and start Docker
echo "Enabling Docker to start on boot..."
systemctl enable docker || error_exit "Failed to enable Docker."
echo "Starting Docker service..."
systemctl start docker || error_exit "Failed to start Docker service."

# Add the current user to the Docker group to avoid using 'sudo' for Docker commands
echo "Adding the current user to the Docker group..."
if id -nG "$SUDO_USER" | grep -qw "docker"; then
    echo "User '$SUDO_USER' is already in the Docker group."
else
    usermod -aG docker "$SUDO_USER" || error_exit "Failed to add user '$SUDO_USER' to the Docker group."
    echo "User '$SUDO_USER' has been added to the Docker group. Please log out and log back in to apply the changes."
fi

# Verify Docker installation
echo "Verifying Docker installation..."
docker --version || error_exit "Docker installation verification failed."

echo "Docker has been successfully installed and configured."

# Additional security recommendations
echo "Applying additional Docker security configurations..."

# Disable legacy iptables chains for Docker
echo "Disabling legacy iptables chains for Docker..."
echo '{"iptables": false}' | tee /etc/docker/daemon.json > /dev/null || error_exit "Failed to configure Docker to use modern iptables."

# Restart Docker to apply security changes
echo "Restarting Docker service..."
systemctl restart docker || error_exit "Failed to restart Docker service."

echo "Docker installation and security configuration completed successfully."
