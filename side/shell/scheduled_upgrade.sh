#!/bin/bash

# Target block to stop the node
TARGET_BLOCK=226600
PORT=37657


# Function to get the current block number
get_current_block() {
    echo $(curl -s localhost:$PORT/status | jq -r .result.sync_info.latest_block_height)
}

# Function to start services
restart_services() {
    sudo systemctl restart sided
    echo "Services started."
}

# Main script cycle
main() {
    while true; do
        current_block=$(get_current_block)
        
        if [[ "$current_block" -ge "$TARGET_BLOCK" ]]; then
            echo -e "Target block reached or exceeded: $current_block"
            restart_services
            break
        fi

        echo -ne "\\rCurrent block number: $current_block, Remaining blocks: $((TARGET_BLOCK - current_block)), Target block: $TARGET_BLOCK"

    done
    echo "Script completed."
}

# Start the main function
main
