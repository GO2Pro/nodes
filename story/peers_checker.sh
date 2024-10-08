#!/bin/bash

# Variables for URLs and thresholds
STATUS_URL="https://testnet.storyrpc.io/status"
PEER_URLS=(
    "https://story-testnet-rpc.f5nodes.com/net_info"
    "https://story-testnet-rpc.itrocket.net/net_info"
    "https://rpc-1.testnet.story.nodes.guru/net_info"
    "https://story-testnet.rpc.kjnodes.com/net_info"
    "https://story-testnet-rpc.polkachu.com/net_info"
    "https://story-testnet-rpc.go2pro.xyz/net_info"
)
# The number of blocks betwen your node and master server.
BLOCK_DIFF_THRESHOLD=5
PERCENT_DIFF_THRESHOLD=25
DIFF_FILE="$HOME/.peers/block_diff.txt"

# Function to get the current timestamp in UTC
get_timestamp() {
    echo $(date -u +"%Y-%m-%d %H:%M:%S UTC")
}

# Get the current timestamp
timestamp=$(get_timestamp)

# Function to get latest_block_height and catching_up values
get_block_info() {
    local url=$1
    local response=$(curl -s $url)
    
    # Check if the response is valid JSON
    if echo "$response" | jq empty 2>/dev/null; then
        local latest_block_height=$(echo $response | jq -r '.result.sync_info.latest_block_height')
        local catching_up=$(echo $response | jq -r '.result.sync_info.catching_up')
        echo "$latest_block_height $catching_up"
    else
        echo "Error: Invalid JSON response from $url" >&2
        echo "0 false"  # Default values in case of an error
    fi
}

# Function to get latest_block_height and catching_up values from our server with retry mechanism
get_our_block_info() {
    local status
    local retries=3
    local count=0

    while [ $count -lt $retries ]; do
        # Use curl with the --connect-timeout option to limit the time it tries to connect
		# Check port in [rcp] secition, file: /root/.story/story/config/config.toml
        status=$(curl --connect-timeout 10 -s localhost:26657/status | jq . 2>&1)
        
        # Checking the success of curl
        if [ $? -ne 0 ]; then
            echo "Error: Connection to local story node failed. Attempt $((count + 1)) of $retries." >&2
            count=$((count + 1))
            sleep 5  # Wait before retrying
            continue
        fi
        
        # Check if the status is valid JSON
        if echo "$status" | jq empty 2>/dev/null; then
            local latest_block_height=$(echo "$status" | jq -r '.result.sync_info.latest_block_height')
            local catching_up=$(echo "$status" | jq -r '.result.sync_info.catching_up')
            echo "$latest_block_height $catching_up"
            return 0
        else
            echo "Error: Failed to parse JSON response from story status. Attempt $((count + 1)) of $retries." >&2
            count=$((count + 1))
            sleep 5  # Wait before retrying
        fi
    done

    # If all retries fail, provide default error handling
    echo "Error: Unable to connect to story after $retries attempts. Checking service status." >&2
    sudo systemctl restart story
    echo "0 false"  # Default values in case of an error
}

# Function for collecting peers from multiple URLs
collect_peers() {
    local urls=("$@")
    local all_peers=()

    for url in "${urls[@]}"; do
        local response=$(curl -s $url)
        
        # Check if the response is valid JSON
        if echo "$response" | jq empty 2>/dev/null; then
            local peers=$(echo $response | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):" + (.node_info.listen_addr | capture("(?<ip>.+):(?<port>[0-9]+)$").port)')
            for peer in $peers; do
                local ip=$(echo $peer | cut -d '@' -f 2 | cut -d ':' -f 1)
                # Filter out IPv6 addresses
                if [[ ! "$ip" =~ .*:.* ]]; then
                    all_peers+=($peer)
                fi
            done
        else
            echo "Error: Invalid JSON response from $url" >&2
        fi
    done

    # Removing duplicates
    local peers_list=$(echo "${all_peers[@]}" | tr ' ' '\n' | sort -u | tr '\n' ',')
    echo "${peers_list%,}"
}

# Function to update peers and restart the service
update_peers_and_restart() {
    local reason=$1
    PEERS=$(collect_peers "${PEER_URLS[@]}")
    echo "$timestamp Updating peers list as the $reason"
    # Commenting out the following line will prevent it from being logged but will not affect functionality
    #echo "PEERS=\"$PEERS\""
    sed -i 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.story/story/config/config.toml
    sudo systemctl restart story
}

# Receiving data from STORY server
read LATEST_BLOCK_HEIGHT _ <<< $(get_block_info $STATUS_URL)

# Retrieving data from our server
read OUR_LATEST_BLOCK_HEIGHT OUR_CATCHING_UP <<< $(get_our_block_info)

# Reading the previous block difference from a file

if [ -f $DIFF_FILE ]; then
    PREVIOUS_DIFF=$(cat $DIFF_FILE)
else
    PREVIOUS_DIFF=0
fi

# Calculating the current difference
CURRENT_DIFF=$((LATEST_BLOCK_HEIGHT - OUR_LATEST_BLOCK_HEIGHT))

# Checking conditions
if [ "$OUR_CATCHING_UP" = "false" ]; then
    if [ $CURRENT_DIFF -gt $BLOCK_DIFF_THRESHOLD ]; then
        update_peers_and_restart "$timestamp Block difference [$CURRENT_DIFF] is greater than $BLOCK_DIFF_THRESHOLD"
    else
        echo "$timestamp Block difference [$CURRENT_DIFF] is not greater than $BLOCK_DIFF_THRESHOLD. No action taken."
    fi
elif [ "$OUR_CATCHING_UP" = "true" ]; then
    if [ $CURRENT_DIFF -gt $((PREVIOUS_DIFF + (PREVIOUS_DIFF / PERCENT_DIFF_THRESHOLD))) ]; then
        update_peers_and_restart "$timestamp Block difference [$CURRENT_DIFF] increased by more than $PERCENT_DIFF_THRESHOLD%"
    elif [ $CURRENT_DIFF -lt $PREVIOUS_DIFF ]; then
        reduction=$((PREVIOUS_DIFF - CURRENT_DIFF))
        echo "$timestamp Block difference [$CURRENT_DIFF] has decreased by $reduction. Remaining difference is $CURRENT_DIFF."
    else
        echo "$timestamp Block difference [$CURRENT_DIFF] has not significantly changed. No action taken."
    fi
fi

# Writing the current difference to a file
echo $CURRENT_DIFF > $DIFF_FILE
