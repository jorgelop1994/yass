🚀 Welcome to YASS!

YASS (Yet Another Security Scripts Project) is your one-stop solution to simplify and automate the security configuration of your Virtual Private Server (VPS). 🔒 Our mission is to provide you with the tools and scripts needed to safeguard your data, ensuring privacy from unauthorized access – even from the service provider itself. 🙅‍♂️📂

🛠️ What is YASS?

YASS is a set of automation scripts designed to help you configure your server following the best security practices. From creating new users securely to setting up two-factor authentication, YASS makes server security a breeze! 🌬️

🚩 Key Features

	•	Easy Setup: Set up a secure server in minutes using our scripts.
	•	Best Security Practices: Follow industry standards with Docker, reverse proxies, web servers, and more.
	•	Automated Security Measures: Protect your server automatically with our comprehensive security configurations.
	•	Peace of Mind: Eliminate worries about snooping and unauthorized access.

📜 Scripts Overview

1-createUser

This script creates a new user on your VPS with secure practices:

	•	Verifies that it is run with root or sudo privileges.
	•	Prompts for a new username and validates its uniqueness.
	•	Sets a secure password for the new user.
	•	Adds the new user to the sudo group for administrative privileges.

2-setupSecurity

Automates the configuration of essential security measures:

	•	System Updates: Automatically updates the system and configures automatic security updates.
	•	Firewall Configuration: Installs and configures UFW (Uncomplicated Firewall) to block unauthorized access.
	•	SSH Security: Disables SSH access for the root user, changes the default SSH port, and disables password-based authentication.
	•	Intrusion Prevention: Installs and configures Fail2Ban to protect against brute-force attacks.
	•	Rootkit Detection: Installs rkhunter and chkrootkit for rootkit detection.
	•	Kernel Hardening: Applies kernel parameter hardening to protect against network attacks.

3-googleAuthenticator

Sets up Google Authenticator for Two-Factor Authentication (2FA):

	•	Installs the Google Authenticator PAM module.
	•	Configures SSH to use Google Authenticator for an additional layer of security.
	•	Guides the user through the setup process for Google Authenticator.

4-dockerInstallation

Installs and configures Docker securely:

	•	Installs Docker Engine, CLI, and Containerd.
	•	Configures Docker to start on boot and adds the current user to the Docker group.
	•	Applies security recommendations, such as disabling legacy iptables chains.

5-advancedPortKnocking

Implements advanced port knocking techniques to secure your server:

	•	Installs necessary packages (ufw and knockd).
	•	Configures multiple port knocking sequences for dynamic port access control.
	•	Sets up automatic cleanup scripts for expired port rules to maintain security.
	•	Schedules regular cleanup via cron.

📥 How to Use

	1.	Clone the Repository: Clone this repository to your local machine.
	2.	Review Scripts: Review the scripts to ensure they meet your specific needs and adjust configurations if necessary.
	3.	Run the Scripts: Execute the scripts in the recommended order to set up a fully secured server environment.
	4.	Enjoy Peace of Mind: Relax, knowing that your VPS is secured with best practices!

🙌 Join Us!

YASS is an open-source project, and we welcome contributions! If you have ideas for improvements or new features, feel free to open an issue or submit a pull request. Let’s make server security easy and accessible for everyone! 🌍

Feel free to adjust this content as needed, especially if you make any changes to the scripts or add new ones!
