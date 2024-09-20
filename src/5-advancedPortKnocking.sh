#!/bin/bash

# Configuration
CLEANUP_INTERVAL_MINUTES=1  # Interval in minutes for automatic cleanup
PORTS_TO_ALLOW=(2222 80)       # Array of ports to allow access dynamically
KNOCK_SEQUENCES_OPEN=("7000,8000,9000" "6000,7000,8000")  # Different knock sequences for opening each port
KNOCK_SEQUENCES_CLOSE=("9000,8000,7000" "8000,7000,6000") # Different knock sequences for closing each port
SEQ_TIMEOUTS=(3 3)         # Array of seq_timeout values (in seconds) for each port
PORT_LIFESPAN=(300 3600)      # Array of lifespan values (in seconds) for each port
LOG_FILE="/var/log/port_knocking.log"  # Log file for events
TIMESTAMP_DIR="/var/run/port_knock"  # Directory to store timestamp files

# Enable strict error handling
set -euo pipefail

# Function to install necessary packages
install_packages() {
    echo "Installing ufw and knockd..."
    sudo apt-get update
    sudo apt-get install -y ufw knockd
}

# Function to configure UFW (Uncomplicated Firewall)
configure_ufw() {
    echo "Configuring UFW..."
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Remove any existing UFW rules for the specified ports
    for port in "${PORTS_TO_ALLOW[@]}"; do
        sudo ufw delete allow ${port} || true  # Allow the command to fail silently if the rule does not exist
        sudo ufw delete deny ${port} || true   # Allow the command to fail silently if the rule does not exist
    done

    echo "y" | sudo ufw enable  # Automatically confirm enabling UFW
}

# Function to configure knockd for port knocking with multiple ports, sequences, and timeouts
configure_knockd() {
    echo "Configuring knockd..."
    sudo mkdir -p ${TIMESTAMP_DIR}  # Create directory for timestamp files
    sudo chown root:root ${TIMESTAMP_DIR}  # Set correct ownership
    sudo chmod 755 ${TIMESTAMP_DIR}  # Ensure the directory is writable

    sudo bash -c "cat > /etc/knockd.conf" <<EOL
[options]
    UseSyslog
EOL

    # Add configurations for each port with its specific knock sequences, timeouts, and lifespan
    for i in "${!PORTS_TO_ALLOW[@]}"; do
        PORT="${PORTS_TO_ALLOW[i]}"
        KNOCK_OPEN="${KNOCK_SEQUENCES_OPEN[i]}"
        KNOCK_CLOSE="${KNOCK_SEQUENCES_CLOSE[i]}"
        TIMEOUT="${SEQ_TIMEOUTS[i]}"
        LIFESPAN="${PORT_LIFESPAN[i]}"
        
        sudo bash -c "cat >> /etc/knockd.conf" <<EOL

[openPort${PORT}]
    sequence = ${KNOCK_OPEN}
    seq_timeout = ${TIMEOUT}
    command = ufw allow from %IP% to any port ${PORT} proto tcp && echo "\$(date): Port ${PORT} opened for %IP%" >> ${LOG_FILE} && touch ${TIMESTAMP_DIR}/port_${PORT}_%IP%.ts
    tcpflags = syn

[refreshPort${PORT}]
    sequence = ${KNOCK_OPEN}
    seq_timeout = ${TIMEOUT}
    command = ufw allow from %IP% to any port ${PORT} proto tcp && echo "\$(date): Port ${PORT} refreshed for %IP%" >> ${LOG_FILE} && touch ${TIMESTAMP_DIR}/port_${PORT}_%IP%.ts
    tcpflags = syn

[closePort${PORT}]
    sequence = ${KNOCK_CLOSE}
    seq_timeout = ${TIMEOUT}
    command = ufw delete allow from %IP% to any port ${PORT} proto tcp && echo "\$(date): Port ${PORT} closed for %IP%" >> ${LOG_FILE} && rm -f ${TIMESTAMP_DIR}/port_${PORT}_%IP%.ts
    tcpflags = syn
EOL
    done

    echo "Restarting knockd..."
    sudo systemctl enable knockd
    sudo systemctl restart knockd
}

# Function to create the cleanup script
create_cleanup_script() {
    echo "Creating automatic cleanup script..."
    CLEANUP_SCRIPT_PATH="/usr/local/bin/clean_ufw_rules.sh"
    sudo bash -c "cat > ${CLEANUP_SCRIPT_PATH}" <<EOF
#!/bin/bash

# Automatic cleanup script for UFW rules on ports: ${PORTS_TO_ALLOW[*]}

EOF

    # Add rules cleanup for each port
    for i in "${!PORTS_TO_ALLOW[@]}"; do
        PORT="${PORTS_TO_ALLOW[i]}"
        LIFESPAN="${PORT_LIFESPAN[i]}"
        
        sudo bash -c "cat >> ${CLEANUP_SCRIPT_PATH}" <<EOF
for TIMESTAMP_FILE in ${TIMESTAMP_DIR}/port_${PORT}_*.ts; do
  if [ -f "\${TIMESTAMP_FILE}" ]; then
    LAST_KNOCK_TIME=\$(stat -c %Y "\${TIMESTAMP_FILE}")
    CURRENT_TIME=\$(date +%s)
    TIME_DIFF=\$((CURRENT_TIME - LAST_KNOCK_TIME))

    if [ "\$TIME_DIFF" -ge "${LIFESPAN}" ]; then
      IP=\$(basename "\${TIMESTAMP_FILE}" | cut -d'_' -f3 | sed 's/.ts//')
      ufw delete allow from \${IP} to any port ${PORT} proto tcp
      echo "\$(date): Port ${PORT} closed for IP \${IP} by cleanup script" >> ${LOG_FILE}
      rm -f "\${TIMESTAMP_FILE}"
    else
      echo "Port ${PORT} for IP \${IP} is still within lifespan."
    fi
  fi
done

EOF
    done

    sudo chmod +x "${CLEANUP_SCRIPT_PATH}"
}

# Function to set up cron for automatic cleanup using system-wide crontab
setup_cron_cleanup() {
    echo "Setting up cron for automatic cleanup in /etc/crontab..."
    CRON_JOB="*/${CLEANUP_INTERVAL_MINUTES} * * * * root /usr/local/bin/clean_ufw_rules.sh"
    if ! sudo grep -Fxq "$CRON_JOB" /etc/crontab; then
        echo "$CRON_JOB" | sudo tee -a /etc/crontab > /dev/null
        echo "Cron job added to /etc/crontab."
    else
        echo "Cron job already exists in /etc/crontab."
    fi
}

# Function to set up log file
setup_log_file() {
    echo "Setting up log file..."
    sudo touch ${LOG_FILE}
    sudo chmod 644 ${LOG_FILE}
    sudo chown root:root ${LOG_FILE}
}

# Main execution
main() {
    install_packages
    configure_ufw
    configure_knockd
    create_cleanup_script
    setup_log_file
    setup_cron_cleanup
    echo "Installation and configuration completed. Ports ${PORTS_TO_ALLOW[*]} are now protected with port knocking, each with its own sequence, timeout, and lifespan, and automatic cleanup is scheduled every ${CLEANUP_INTERVAL_MINUTES} minutes."
}

# Run the main function
main
