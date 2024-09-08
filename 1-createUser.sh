#!/bin/bash

# Check if the script is running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root or with sudo."
    exit 1
fi

# Prompt for the new user's namex
read -p "Enter the new user's name: " USERNAME

# Check if the username is empty
if [ -z "$USERNAME" ]; then
    echo "The username cannot be empty."
    exit 1
fi

# Check if the user already exists
if id "$USERNAME" &>/dev/null; then
    echo "The user '$USERNAME' already exists."
    exit 1
fi

# Prompt for the new user's password
read -s -p "Enter the password for the new user: " PASSWORD
echo

# Check if the password is empty
if [ -z "$PASSWORD" ]; then
    echo "The password cannot be empty."
    exit 1
fi

# Create the new user
echo "Creating the user '$USERNAME'..."
useradd -m -s /bin/bash "$USERNAME"

# Verify if the user creation was successful
if [ $? -ne 0 ]; then
    echo "An error occurred while creating the user."
    exit 1
fi

# Set the password for the new user
echo "$USERNAME:$PASSWORD" | chpasswd

# Add the user to the sudo group
echo "Granting sudo privileges to the user '$USERNAME'..."
usermod -aG sudo "$USERNAME"

echo "The user '$USERNAME' has been created with sudo privileges."
