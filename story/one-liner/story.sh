#!/bin/bash

export _binaries_aws_geth="https://story-geth-binaries.s3.us-west-1.amazonaws.com/geth-public/geth-linux-amd64-0.9.3-b224fdf.tar.gz"
export _binaries_aws_story="https://story-geth-binaries.s3.us-west-1.amazonaws.com/story-public/story-linux-amd64-0.11.0-aac4bfe.tar.gz"
export GO_VERSION="1.23.2"

# CHECK UPDATE
system_update() {
    sudo apt update && sudo apt upgrade -y < "/dev/null"
    
    bash_profile=$HOME/.bash_profile

    if [ -f "$bash_profile" ]; then
        source $HOME/.bash_profile
    fi
}

# SYSTEM CHECK
system_check_ubuntu() {
    # Get the Ubuntu version
    version=$(lsb_release -r | awk '{print $2}')

    # Convert the version to a number for comparison
    version_number=$(echo $version | sed 's/\.//')

    # Set the minimum supported version
    min_version_number=2204

    # Compare the versions
    if [ "$version_number" -lt "$min_version_number" ]; then
        echo -e "${RED}Current Ubuntu Version: "$version".${RESET}"
        echo "" && sleep 1
        echo -e "${RED}Required Ubuntu Version: 22.04.${RESET}"
        echo "" && sleep 1
        echo -e "${RED}Please use Ubuntu version 22.04 or higher.${RESET}"
        exit 1
    fi
}

# EXPORT VARIABLES
export_variables() {
    echo "export _PORT="37"" >> $HOME/.bash_profile
    echo 'export NODE_PATH="$HOME/.story"' >> $HOME/.bash_profile
    echo "export CHAIN_ID="iliad"" >> $HOME/.bash_profile
  
  	echo -e '\n\e[42mValidator Moniker\e[0m\n' && sleep 1
    if [ ! $MONIKER ]; then
        read -p "Enter validator name (moniker): " MONIKER
        echo 'export MONIKER='\"${MONIKER}\" >> $HOME/.bash_profile
    fi

    echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
    source $HOME/.bash_profile
}

# INSTALL GO
install_go() {
    echo -e '\n\e[42mInstall Go\e[0m\n' && sleep 1
    cd $HOME
  
    wget -O go_.tar.gz "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go && tar -C /usr/local -xzf go_.tar.gz && rm go_.tar.gz
    echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile && source $HOME/.bash_profile
    mkdir -p $HOME/go/bin
    go version
}

# INSTALL DEPENDENCIES
install_dependencies() {
    sleep 1
    cd $HOME
    sudo apt update
    sudo apt install -y nano curl git wget aria2 pv htop tmux build-essential jq make lz4 gcc unzip clang pkg-config libssl-dev ncdu bsdmainutils nvme-cli libleveldb-dev tar bc< "/dev/null"
}

# DOWNLOAD BINARIES
node_download_binaries() {
    echo -e '\n\e[42mBinaries\e[0m\n' && sleep 1
  
    file_geth=geth-linux-amd64
    file_story=story-linux-amd64
  
    # Download GETH
    cd $HOME
    echo -e '\n\e[42mDownload GETH\e[0m\n' && sleep 1
    wget -q --show-progress -O $file_geth.tar.gz $_binaries_aws_story
    root_folder_geth=$(tar -tzf $file_geth.tar.gz | grep -o '^[^/]\+' | uniq)
    tar -xzvf $file_geth.tar.gz && sudo chmod +x $HOME/$root_folder_geth/ && sudo mv $HOME/$root_folder_geth/geth $HOME/go/bin && sudo rm -rf $file_geth.tar.gz && sudo rm -rf $HOME/$root_folder_geth
    geth version
  
    # Download STORY
    echo -e '\n\e[42mDownload STORY\e[0m\n' && sleep 1
    wget -q --show-progress -O $file_story.tar.gz $_binaries_aws_geth
    root_folder_story=$(tar -tzf $file_story.tar.gz | grep -o '^[^/]\+' | uniq)
    tar -xzvf $file_story.tar.gz && sudo chmod +x $HOME/$root_folder_story/ && sudo mv $HOME/$root_folder_story/story $HOME/go/bin && sudo rm -rf $file_story.tar.gz && sudo rm -rf $HOME/$root_folder_story
    story version
}

# INIT
node_init() {
  	rm -rf $HOME/.story/
  	echo -e '\n\e[42mInit\e[0m\n' && sleep 1
  	story init --network $CHAIN_ID --moniker $MONIKER
    sleep 1
}

# EXPORT KEYS
node_export_keys() {
  	echo -e '\n\e[42mExporting Keys\e[0m\n' && sleep 1
  	story validator export --export-evm-key --evm-key-path ~/.story/story/.env
    story validator export --export-evm-key >>$HOME/.story/story/wallet.txt
    cat $HOME/.story/story/.env >> $HOME/.story/story/wallet.txt
}

# Service GETH
node_service_geth() {
    sudo tee /etc/systemd/system/geth.service > /dev/null <<EOF
[Unit]
Description=Geth Worker Node
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=1
User=$USER
ExecStart=$HOME/go/bin/geth --iliad --syncmode full
StandardOutput=journal
StandardError=journal
SyslogIdentifier=node-geth
StartLimitInterval=0
LimitNOFILE=65536
LimitNPROC=65536

[Install]
WantedBy=multi-user.target
EOF
}

# Service STORY
node_service_story() {
    sudo tee /etc/systemd/system/story.service > /dev/null <<EOF
[Unit]
Description=Story Client Node
After=network.target geth.service

[Service]
Type=simple
Restart=always
RestartSec=1
User=$USER
ExecStart=$HOME/go/bin/story run
WorkingDirectory=$HOME/.story/story
StandardOutput=journal
StandardError=journal
SyslogIdentifier=node-story
StartLimitInterval=0
LimitNOFILE=65536
LimitNPROC=65536

[Install]
WantedBy=multi-user.target
EOF
}

#CHECK PORTS
node_check_ports() {
    echo -e '\n\e[42mChecking ports\e[0m\n' && sleep 1
    if ss -tulpen | awk '{print $5}' | grep -q ":26656$" ; then
        echo -e "\e[31mPort 26656 already in use.\e[39m"
        sleep 2
        sed -i -e "s|:26656\"|:${_PORT}656\"|g" $NODE_PATH/story/config/config.toml
        echo -e "\n\e[42mPort 26656 changed to ${PORT}56.\e[0m\n"
        sleep 2
    fi
    if ss -tulpen | awk '{print $5}' | grep -q ":26657$" ; then
        echo -e "\e[31mPort 26657 already in use\e[39m"
        sleep 2
        sed -i -e "s|:26657\"|:${_PORT}657\"|" $NODE_PATH/story/config/config.toml
        echo -e "\n\e[42mPort 26657 changed to ${PORT}57.\e[0m\n"
        sleep 2
    fi
    if ss -tulpen | awk '{print $5}' | grep -q ":26658$" ; then
        echo -e "\e[31mPort 26658 already in use.\e[39m"
        sleep 2
        sed -i -e "s|:26658\"|:${_PORT}658\"|" $NODE_PATH/story/config/config.toml
        echo -e "\n\e[42mPort 26658 changed to ${PORT}58.\e[0m\n"
        sleep 2
    fi
    if ss -tulpen | awk '{print $5}' | grep -q ":1317$" ; then
        echo -e "\e[31mPort 1317 already in use.\e[39m"
        sleep 2
        sed -i -e "s|:1317\"|:${_PORT}617\"|" $NODE_PATH/story/config/story.toml
        echo -e "\n\e[42mPort 1317 changed to ${PORT}17.\e[0m\n"
        sleep 2
    fi
}

# START NODE
node_start() {
    sudo systemctl restart systemd-journald
    sudo systemctl daemon-reload
    echo -e '\n\e[42mStarting GETH Service\e[0m\n' && sleep 1
    sudo systemctl enable geth && sudo systemctl start geth
    sleep 5
    echo -e '\n\e[42mStarting STORY Service\e[0m\n' && sleep 1
    sudo systemctl enable story && sudo systemctl start story
    sleep 5
}

# NODE STATUS
node_status() {
    echo -e '\n\e[42mChecking STORY status\e[0m\n' && sleep 1
    
    if [[ `sudo systemctl status story | grep active` =~ "running" ]]; then
        echo -e "Your STORY node \e[32minstalled and works\e[39m!"
        echo -e "You can check node status by the command \e[7msudo systemctl status story\e[0m"
        echo -e '\n\e[42mCopy from wallet.txt:\e[0m\n' && sleep 1
        cat $HOME/.story/story/wallet.txt
        echo -e '\n\e[42mBackup these files:\e[0m\n' && sleep 1
        echo -e "priv_validator_key.json \e[7m/root/.story/story/config/priv_validator_key.json\e[0m"
        echo -e "node_key.json \e[7m/root/.story/story/config/node_key.json\e[0m"
    else
        echo -e "Your STORY node \e[31mwas not installed correctly\e[39m, please reinstall."
    fi
}


setup_node() {
    export_variables
    system_update
    system_check_ubuntu
    install_go
    install_dependencies
    node_download_binaries
    node_init
    node_export_keys
    node_service_geth
    node_service_story
    node_check_ports
    node_start
    node_status
}

setup_node
