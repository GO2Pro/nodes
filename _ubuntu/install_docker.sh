# CHECK UPDATE
system_update() {
	echo -e '\n\e[42mUpdating System\e[0m\n' && sleep 1
    sudo apt update -y< "/dev/null"
    
    bash_profile=$HOME/.bash_profile

    if [ -f "$bash_profile" ]; then
        source $HOME/.bash_profile
    fi
}

# INSTALL DEPENDENCIES
install_dependencies() {
	echo -e '\n\e[42mInstalling Dependencies\e[0m\n' && sleep 1
    sleep 1
    cd $HOME
    sudo apt update
    sudo apt install -y nano curl git wget aria2 pv htop tmux build-essential jq make lz4 gcc unzip clang pkg-config libssl-dev ncdu bsdmainutils nvme-cli libleveldb-dev tar bc< "/dev/null"
}

# INSTALL DOCKER
install_docker() {
	echo -e '\n\e[42mInstalling Docker\e[0m\n' && sleep 1
	# Add Docker's official GPG key:
	sudo apt-get -y install ca-certificates curl
	sudo install -m 0755 -d /etc/apt/keyrings
	sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
	sudo chmod a+r /etc/apt/keyrings/docker.asc
	
	# Add the repository to Apt sources:
	echo \
	  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
	  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
	  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	sudo apt-get update -y
	
	sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
	
	# Download Docker-Compose Binaries
	echo -e '\n\e[42mDownloading Docker-Compose\e[0m\n' && sleep 1
	LATEST_RELEASE=$(curl -s "https://api.github.com/repos/docker/compose/releases/latest" | grep '"tag_name":' | awk -F '"' {'print $4'})
	echo $LATEST_RELEASE
	curl -SL https://github.com/docker/compose/releases/download/$LATEST_RELEASE/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
	sudo chmod +x /usr/local/bin/docker-compose
	
	# Check Versions
	DOCKER_VERSION=$(docker --version)
	DOCKER_COMPOSE_VERSION=$(docker-compose --version)
	
	echo -e "\e[7m$DOCKER_VERSION\e[0m"
	echo -e "\e[7m$DOCKER_COMPOSE_VERSION\e[0m"
}

setup_docker() {
	system_update
	install_dependencies
	install_docker
}

setup_docker
