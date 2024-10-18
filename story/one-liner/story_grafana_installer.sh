#!/bin/bash

export CUSTOM_PORT_NODE=26660
export CUSTOM_PORT_GRAFANA=9093
export CUSTOM_PORT_PROMETHEUS=9094
export CUSTOM_PORT_EXPORTER=9095
export CUSTOM_PORT_ALERT=9096
export SERVER_IP=$(wget -qO- eth0.me)

# CHECK UPDATE
system_update() {
	echo -e '\n\e[42mUpdating System\e[0m\n' && sleep 1
    sudo apt update -y< "/dev/null"
    
    bash_profile=$HOME/.bash_profile

    if [ -f "$bash_profile" ]; then
        source $HOME/.bash_profile
    fi
	
	mkdir -p /etc/grafana
	mkdir -p /etc/prometheus
	mkdir -p /etc/node-exporter
}

# INSTALL DEPENDENCIES
install_dependencies() {
	echo -e '\n\e[42mInstalling Dependencies\e[0m\n' && sleep 1
    sleep 1
    cd $HOME
    sudo apt update
    sudo apt install -y nano curl git wget aria2 pv htop tmux build-essential jq make lz4 gcc unzip clang pkg-config libssl-dev ncdu bsdmainutils nvme-cli libleveldb-dev tar bc< "/dev/null"
}

# ENABLE PROMETHEUS
enable_prometheus_config() {
    local config_file="$HOME/.story/story/config/config.toml"
    
    echo -e "\n\e[42mChecking Prometheus configuration in Story Config\e[0m\n" && sleep 1
    
    # Check if the configuration file exists
    if [[ -f "$config_file" ]]; then
        # Check the current value of the Prometheus parameter
        if grep -q "prometheus = false" "$config_file"; then
            echo "Enabling Prometheus..."
            # Change the parameter from false to true
            sed -i -e "s/prometheus = false/prometheus = true/" "$config_file"
            # Restart the service if the parameter was changed
            echo "Configuration changed. Restarting the Story service..."
            sudo systemctl restart story
        else
            echo "Prometheus is already enabled or not set to false."
        fi
    else
        echo -e "\e[41m\e[97mConfiguration file not found: $config_file\e[0m"
    fi
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

# INSTALL GRAFANA
install_grafana() {
	echo -e '\n\e[42mInstalling Grafana\e[0m\n' && sleep 1
	
	# Create Docker Compose Configuration for Grafana: docker-compose-grafana.yml
	sudo tee /etc/grafana/docker-compose-grafana.yml > /dev/null <<EOF
services:
  grafana:
    image: grafana/grafana
    container_name: grafana
    restart: unless-stopped
    ports:
     - '$CUSTOM_PORT_GRAFANA:3000'
    volumes:
      - grafana-storage:/var/lib/grafana
volumes:
  grafana-storage: {}
EOF
	
	docker-compose -f /etc/grafana/docker-compose-grafana.yml up -d
}

# INSTALL PROMETHEUS
install_prometheus() {
	echo -e '\n\e[42mInstalling Prometheus\e[0m\n' && sleep 1
	
	# Create Docker Compose Configuration for Prometheus: docker-compose-prometheus.yml
	sudo tee /etc/prometheus/docker-compose-prometheus.yml > /dev/null <<EOF
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prom
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
    ports:
      - $CUSTOM_PORT_PROMETHEUS:9090
    restart: unless-stopped
    volumes:
      - /etc/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - /etc/prometheus:/etc/prometheus
      - prom_data:/prometheus
volumes:
  prom_data:
EOF

	# Create Prometheus Configuration File: prometheus.yml
	sudo tee /etc/prometheus/prometheus.yml > /dev/null <<EOF
global:
  scrape_interval: 15s
  scrape_timeout: 10s
  evaluation_interval: 15s
alerting:
  alertmanagers:
    - static_configs:
        - targets: ['$SERVER_IP:$CUSTOM_PORT_ALERT']
      scheme: http
      timeout: 10s
      api_version: v1
scrape_configs:
  - job_name: "prometheus"
    scrape_interval: 5s
    scrape_timeout: 5s
    static_configs:
      - targets: ['$SERVER_IP:$CUSTOM_PORT_PROMETHEUS']
  - job_name: "story"
    static_configs:
      - targets: ['$SERVER_IP:$CUSTOM_PORT_NODE']
  - job_name: "exporter"
    static_configs:
      - targets: ['$SERVER_IP:$CUSTOM_PORT_EXPORTER']
EOF
	
	docker-compose -f /etc/prometheus/docker-compose-prometheus.yml up -d
}

# INSTALL PROMETHEUS NODE EXPORTER
install_node_exporter() {
	echo -e '\n\e[42mInstall Node Exporter\e[0m\n' && sleep 1

	# Create Docker Compose Configuration for Node Exporter: docker-compose-node-exporter.yml
	sudo tee /etc/node-exporter/docker-compose-node-exporter.yml > /dev/null <<EOF
services:
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
      #- '--web.listen-address=$SERVER_IP:$CUSTOM_PORT_EXPORTER'
    ports:
      - '$CUSTOM_PORT_EXPORTER:9100'
    restart: unless-stopped
    volumes:
      - '/proc:/host/proc:ro'
      - '/sys:/host/sys:ro'
      - '/:/rootfs:ro'
EOF

	docker-compose -f /etc/node-exporter/docker-compose-node-exporter.yml up -d
}

# GRAFANA SET PROMETHEUS SOURCE
grafana_set_source() {
	GRAFANA_PAYLOAD=$(cat <<EOF
{
    "name": "SP_PROMETHEUS",
    "type": "prometheus",
    "url": "http://$SERVER_IP:$CUSTOM_PORT_PROMETHEUS",
    "access": "proxy",
    "basicAuth": false,
    "isDefault": true
}
EOF
)

	# Set Prometheus as a data source
	curl -s -X POST -H "Content-Type: application/json" -d "$GRAFANA_PAYLOAD" "http://$SERVER_IP:$CUSTOM_PORT_GRAFANA/api/datasources" -u "admin:admin"
}

# GRAFANA SET DASHBOARD
grafana_set_dashboard() {
	# Download dashboard
	curl -s "https://raw.githubusercontent.com/GO2Pro/nodes/refs/heads/main/story/grafana_story_protocol.json" -o $HOME/grafana_story_protocol.json

	GRAFANA_DASHBOARD_PAYLOAD=$(cat <<EOF
{
    "dashboard": $(jq -c . < $HOME/grafana_story_protocol.json),
    "overwrite": true
}
EOF
)

	# Import Dashboard
	RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "$GRAFANA_DASHBOARD_PAYLOAD" "http://$SERVER_IP:$CUSTOM_PORT_GRAFANA/api/dashboards/db" -u "admin:admin")

	DASHBOARD_UID=$(jq -r '.uid' <<< "$RESPONSE")

	if [ "$DASHBOARD_UID" != "null" ]; then
		echo -e "\nYour Grafana Dashboard \e[32minstalled and works\e[39m!"
		echo -e "Dashboard direct link \e[7mhttp://$SERVER_IP:$CUSTOM_PORT_GRAFANA/d/$DASHBOARD_UID/story-protocol\e[0m"
		echo -e "Dashboard Login \e[7madmin\e[0m"
		echo -e "Dashboard Password \e[7madmin\e[0m"
	else
		echo -e "\e[41m\e[97mGrafana Dashboard not imported\e[0m"
	fi
}


setup_metrics() {
	system_update
	install_dependencies
	enable_prometheus_config
	install_docker
	install_grafana
	install_prometheus
	install_node_exporter
	grafana_set_source
	grafana_set_dashboard
}

setup_metrics
