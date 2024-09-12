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

# Prompt for the new user's name
read -rp "Enter the new user's name: " USERNAME

# Validate the username is not empty
[[ -z "$USERNAME" ]] && error_exit "The username cannot be empty."

# Check if the user already exists
if id "$USERNAME" &>/dev/null; then
    error_exit "The user '$USERNAME' already exists."
fi

# Prompt for the new user's password twice and validate
while true; do
    read -srp "Enter the password for the new user: " PASSWORD
    echo
    read -srp "Confirm the password: " PASSWORD_CONFIRM
    echo

    # Validate the password is not empty
    [[ -z "$PASSWORD" ]] && { echo "The password cannot be empty."; continue; }

    # Ensure both passwords match
    if [[ "$PASSWORD" != "$PASSWORD_CONFIRM" ]]; then
        echo "Passwords do not match. Please try again."
    else
        break
    fi
done

# Create the new user and verify the operation
echo "Creating the user '$USERNAME'..."
if ! useradd -m -s /bin/bash "$USERNAME"; then
    error_exit "An error occurred while creating the user."
fi

# Set the password for the new user securely
if ! echo "$USERNAME:$PASSWORD" | chpasswd; then
    error_exit "Failed to set the password for the user."
fi

# Add the user to the sudo group
if usermod -aG sudo "$USERNAME"; then
    echo "The user '$USERNAME' has been created with sudo privileges."
else
    error_exit "Failed to grant sudo privileges to the user."
fi
