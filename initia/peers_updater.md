
### Conditions in the Script Explained

The script checks the synchronization status of the local blockchain node compared to a reference node and performs specific actions based on the block height difference and the catching-up status of the local node.

#### Conditions and Actions:

1. **If the local node is not catching up (`OUR_CATCHING_UP = "false"`):**
   - **Condition:** `if [ $CURRENT_DIFF -gt 50 ]; then`
     - **Action:** If the block height difference (`CURRENT_DIFF`) is greater than 50, the script updates the peers list by collecting peers from multiple URLs and restarts the `initiad` service.
     - **Else:** If the block height difference is not greater than 50, no action is taken, and a message is logged indicating the current block difference.

2. **If the local node is catching up (`OUR_CATCHING_UP = "true"`):**
   - **Condition:** `if [ $CURRENT_DIFF -gt $((PREVIOUS_DIFF + (PREVIOUS_DIFF / 25))) ]; then`
     - **Action:** If the block height difference has increased by more than 25% compared to the previous difference (`PREVIOUS_DIFF`), the script updates the peers list and restarts the `initiad` service.
   - **Else If:** `elif [ $CURRENT_DIFF -lt $PREVIOUS_DIFF ]; then`
     - **Action:** If the block height difference has decreased, the script logs a message indicating that the difference has decreased and by how much, along with the remaining difference.
   - **Else:** If there is no significant change in the block difference, no action is taken, and a message is logged indicating the current block difference.

These conditions ensure that the local node's peers are updated and the node service is restarted only when necessary, either due to a significant increase in the block height difference or when the local node is significantly behind the reference node.

#### Create Directory for Scripts
```bash
sudo mkdir -p $HOME/_peers_updater/
```
#### Create and Edit the Peer Updater Script
```bash
sudo nano $HOME/_peers_updater/initia_persistent_peers_check.sh
```
### Peer Updater Script
```bash
#!/bin/bash

# Variables for URLs
INITIA_URL="https://rpc.initiation-1.initia.xyz/status"
PEER_URLS=(
    "https://initia-testnet-rpc.f5nodes.com/net_info"
    "https://initia-rpc.stake2earn.com/net_info"
    "https://initia-testnet.rpc.kjnodes.com/net_info"
    "https://initia-testnet-rpc.blacknodes.net/net_info"
    "https://initia-testnet-rpc.go2pro.xyz/net_info"
)

# Function to get latest_block_height and catching_up values
get_block_info() {
    local url=$1
    local response=$(curl -s $url)
    local latest_block_height=$(echo $response | jq -r '.result.sync_info.latest_block_height')
    local catching_up=$(echo $response | jq -r '.result.sync_info.catching_up')
    echo "$latest_block_height $catching_up"
}

# Function to get latest_block_height and catching_up values from our server
get_our_block_info() {
    local status=$($HOME/go/bin/initiad status | jq -r '.sync_info')
    local latest_block_height=$(echo $status | jq -r '.latest_block_height')
    local catching_up=$(echo $status | jq -r '.catching_up')
    echo "$latest_block_height $catching_up"
}

# Receiving data from INITIA server
read INITIA_LATEST_BLOCK_HEIGHT _ <<< $(get_block_info $INITIA_URL)

# Retrieving data from our server
read OUR_LATEST_BLOCK_HEIGHT OUR_CATCHING_UP <<< $(get_our_block_info)

# Reading the previous block difference from a file
DIFF_FILE="$HOME/_peers_updater/block_diff.txt"
if [ -f $DIFF_FILE ]; then
    PREVIOUS_DIFF=$(cat $DIFF_FILE)
else
    PREVIOUS_DIFF=0
fi

# Calculating the current difference
CURRENT_DIFF=$((INITIA_LATEST_BLOCK_HEIGHT - OUR_LATEST_BLOCK_HEIGHT))

# Function for collecting peers from multiple URLs
collect_peers() {
    local urls=("$@")
    local all_peers=()

    for url in "${urls[@]}"; do
        local response=$(curl -s $url)
        local peers=$(echo $response | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):" + (.node_info.listen_addr | capture("(?<ip>.+):(?<port>[0-9]+)$").port)')
        all_peers+=($peers)
    done

    # Removing duplicates
    echo "${all_peers[@]}" | tr ' ' '\n' | sort -u | tr '\n' ','
}

# Checking conditions
if [ "$OUR_CATCHING_UP" = "false" ]; then
#	echo "Our server is not catching up. Checking block difference..."
	if [ $CURRENT_DIFF -gt 50 ]; then
		echo "Updating peers list as the block difference is greater than 50"
		PEERS=$(collect_peers "${PEER_URLS[@]}")
		echo "PEERS=\"$PEERS\""
		sed -i 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.initia/config/config.toml
		sudo systemctl restart initiad
	else
		echo "Block difference ($CURRENT_DIFF) is not greater than 50. No action taken."
	fi
elif [ "$OUR_CATCHING_UP" = "true" ]; then
#	echo "Our server is catching up. Checking block difference changes..."
	if [ $CURRENT_DIFF -gt $((PREVIOUS_DIFF + (PREVIOUS_DIFF / 25))) ]; then
		# Collection of peers when the difference increases by 25%
		PEERS=$(collect_peers "${PEER_URLS[@]}")
		echo "Updating peers list as the block difference increased by more than 25%"
		echo "PEERS=\"$PEERS\""
		sed -i 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.initia/config/config.toml
		sudo systemctl restart initiad
	elif [ $CURRENT_DIFF -lt $PREVIOUS_DIFF ]; then
		# When shortening the distance
		local reduction=$((PREVIOUS_DIFF - CURRENT_DIFF))
		echo "Block difference has decreased by $reduction. Remaining difference is $CURRENT_DIFF."
	else
		echo "Block difference ($CURRENT_DIFF) has not significantly changed. No action taken."
	fi
fi

# Writing the current difference to a file
echo $CURRENT_DIFF > $DIFF_FILE

```
#### Make Script Executable
```bash
sudo chmod +x $HOME/_peers_updater/initia_persistent_peers_check.sh
```

### Cron
#### Enable Cron Service
```bash
sudo systemctl enable cron
```
#### Edit Cron Jobs
```bash
sudo crontab -e
```
#### Add Cron Job
```bash
*/5 * * * * $HOME/_peers_updater/initia_persistent_peers_check.sh >> $HOME/_peers_updater/initia_check.log 2>&1
```
#### Restart Cron Service
```bash
systemctl restart cron
```
#### List all current cron jobs.
```bash
crontab -l
```
#### Check Cron Service Status
```bash
systemctl status cron
```
