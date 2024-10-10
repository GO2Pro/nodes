Story v0.11.0 binaries were released on October 04, 2024, UTC, in preparation for the scheduled upgrade at block height 1,325,860, expected to take place on October 10, 2024, UTC. As a reminder, all nodes need to upgrade to this latest stable version at the upgrade block height, but not before, to continue running smoothly on the `iliad` network.

#### Node Operator Action Required:

All node operators must upgrade to client version v0.11.0 at 1,325,860 block height. Nodes running older versions will become incompatible and halted after the block height, estimated to arrive on October 10, 2024, UTC.

## scheduled_upgrade.sh

```bash
#!/bin/bash

# Target block to stop the node
TARGET_BLOCK=1325860

# Binary executable file path and other variables
OLD_BIN_PATH="$HOME/story-linux-amd64-0.11.0-aac4bfe/story"
NEW_BIN_PATH="$HOME/go/bin/story"
PORT=26657


# Function to get the current block number
get_current_block() {
    echo $(curl -s localhost:$PORT/status | jq -r .result.sync_info.latest_block_height)
}

# Function for stopping services
stop_services() {
    sudo systemctl stop story
    sudo systemctl stop geth
    echo -e "Services stopped."
}

# Function for moving a file
move_file() {
    sudo mv $OLD_BIN_PATH $NEW_BIN_PATH
    echo "File moved."
}

# Function to start services
start_services() {
    sudo systemctl start story
    sudo systemctl start geth
    echo "Services started."
}


# Main script cycle
main() {
    while true; do
        current_block=$(get_current_block)
        
        if [[ "$current_block" -ge "$TARGET_BLOCK" ]]; then
            echo -e "Target block reached or exceeded: $current_block"
            stop_services
            move_file
            start_services
            break
        fi

        echo -ne "\\rCurrent block number: $current_block, Remaining blocks: $((TARGET_BLOCK - current_block)), Target block: $TARGET_BLOCK"

    done
    echo "Script completed."
}

# Start the main function
main
```
