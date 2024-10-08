#!/bin/bash

setup_start() {
	# Defining a directory for the script and logs
	export script_dir="/root/.peers/"
	export script_name="pp_checker.sh"

	# Creating a directory if it does not exist
	mkdir -p $script_dir
	
	# Copying the script to the target directory
	setup_peer_updated_sh
	
	# Setting permissions for script execution
	sudo chmod +x $script_dir/$script_name
	
	setup_cron
}

setup_cron() {
	# Adding a task to crontab
	(crontab -l 2>/dev/null; echo "*/5 * * * * $script_dir/$script_name >> $script_dir/output.log 2>> $script_dir/error.log") | crontab -

	# Check the status of the cron service and enable it if it is disabled
	if ! systemctl is-enabled cron; then
		systemctl enable cron
	fi

	# Restarting the cron service to apply changes
	systemctl restart cron

	echo "Installation complete. Script will run every 5 minutes. Cron service is enabled and restarted."
}


setup_peer_updated_sh() {
  wget -q -O $script_dir/$script_name https://raw.githubusercontent.com/GO2Pro/nodes/refs/heads/main/story/peers_checker.sh
}

setup_start
