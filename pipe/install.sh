#!/bin/bash

# Prompt the user for necessary variables
prompt_for_variables() {
    echo "Enter the amount of RAM in gigabytes for the node:"
    read ram

    echo "Enter your Solana wallet public key (address):"
    read pubKey

    echo "Enter the maximum amount of disk space in gigabytes:"
    read maxDisk
}

# Update the system and install necessary packages
update_and_install() {
    echo "Updating system and installing necessary packages..."
    sudo apt update
    sudo apt install -y ufw
}

# Create necessary directories
create_directories() {
    echo "Creating necessary directories..."
    sudo mkdir -p /root/.pipe
    sudo mkdir -p /root/.pipe/download_cache
}

# Download and setup the PoP executable
setup_pop_executable() {
    echo "Downloading and setting up the PoP executable..."
    curl -L -o /root/.pipe/pop "https://dl.pipecdn.app/v0.2.8/pop"
    chmod +x /root/.pipe/pop
}

# Configure environment and service
configure_environment_and_service() {
    echo "Configuring environment and systemd service..."
    echo 'export PATH=$PATH:/root/.pipe' >> ~/.bashrc
    source ~/.bashrc

    sudo tee /etc/systemd/system/pop.service > /dev/null << EOF
[Unit]
Description=Pipe POP Node Service
After=network.target
Wants=network-online.target

[Service]
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
Restart=always
RestartSec=5
LimitNOFILE=65536
LimitNPROC=4096
StandardOutput=journal
StandardError=journal
SyslogIdentifier=pop-node
WorkingDirectory=/root/.pipe
ExecStart=/root/.pipe/pop \
--ram=$ram \
--pubKey $pubKey \
--max-disk $maxDisk \
--cache-dir /root/.pipe/download_cache \
--signup-by-referral-route 7f4d3dccb16b1b1a \
--no-prompt

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable pop.service
    sudo systemctl start pop.service
}

# Configure the firewall
configure_firewall() {
    echo "Configuring the firewall..."
    echo 'y' | sudo ufw enable
    sudo ufw allow OpenSSH
    sudo ufw allow 8003/tcp
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw reload
    sudo ufw status numbered
	sudo systemctl enable ufw
}

# Main function to control the flow of the script
main() {
    prompt_for_variables
    update_and_install
    create_directories
    setup_pop_executable
    configure_environment_and_service
    configure_firewall
    echo "Installation and configuration of the Pipe Network node are completed!"
}

# Execute the main function
main
