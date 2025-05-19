

https://docs.aztec.network/the_aztec_network/guides/run_nodes/how_to_run_sequencer


### 1. Setup Docker + Docker Compose

```bash
wget -q -O install_docker.sh https://raw.githubusercontent.com/GO2Pro/nodes/refs/heads/main/_ubuntu/install_docker.sh && sudo chmod +x install_docker.sh && ./install_docker.sh
```

### 2. Setup RPC

##### Directories
```bash
mkdir -p /root/sepolia_rpc/geth-data /root/sepolia_rpc/lighthouse-data
```
##### Generate JWT
```bash
openssl rand -hex 32 > /root/sepolia_rpc/jwt.hex
```
##### Docker Compose YML
```bash
nano /root/sepolia_rpc/dc-sepolia-rpc.yml
```

###### Docker Compose Files for GETH + Beacon [Lighthouse]
```yaml
services:
  geth:
    image: ethereum/client-go
    container_name: geth-sepolia
    restart: unless-stopped
    volumes:
      - ./geth-data:/root/.ethereum
      - ./jwt.hex:/jwt.hex:ro
    ports:
      - "8545:8545"
      - "30303:30303"
      - "8551:8551"
    command:
      [
        "--sepolia",
        "--http",
        "--http.addr=0.0.0.0",
        "--http.api=eth,net,web3",
        "--http.corsdomain=*",
        "--http.vhosts=*",
        "--ws",
        "--ws.addr=0.0.0.0",
        "--ws.api=eth,net,web3",
        "--syncmode=snap",
        "--authrpc.addr=0.0.0.0",
        "--authrpc.port=8551",
        "--authrpc.vhosts=*",
        "--authrpc.jwtsecret=/jwt.hex"
      ]

  lighthouse:
    image: sigp/lighthouse
    container_name: lighthouse-sepolia
    restart: unless-stopped
    depends_on:
      - geth
    volumes:
      - ./lighthouse-data:/root/.lighthouse
      - ./jwt.hex:/jwt.hex:ro
    ports:
      - "5052:5052"
    command:
      [
        "lighthouse",
        "bn",
        "--network", "sepolia",
        "--http",
        "--http-address=0.0.0.0",
        "--execution-endpoint", "http://geth:8551",
        "--execution-jwt", "/jwt.hex",
        "--checkpoint-sync-url", "https://sepolia.checkpoint-sync.ethpandaops.io"
      ]
```
##### Starting Docker
```bash
docker compose -f /root/sepolia_rpc/dc-sepolia-rpc.yml up -d
```

#### Additional Commands
##### Docker Compose Down
```bash
docker compose -f /root/sepolia_rpc/dc-sepolia-rpc.yml down -v
```
##### Logs Lighthouse
```bash
docker logs --tail 100 -f lighthouse-sepolia
```
##### Logs GETH
```bash
docker logs --tail 100 -f geth-sepolia
```
##### Sync status GETH
```bash
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}'
```

Once synchronized `{"jsonrpc":"2.0","id":1,"result":false}`

##### Sync status Lighthouse
```bash
curl http://localhost:5052/eth/v1/node/syncing
```


Once synchronized `{"data":{"is_syncing":false,"is_optimistic":false,"el_offline":false,"head_slot":"7657789","sync_distance":"0"}}`


### 3. AZTEC

#### Ports
```bash
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 40400/tcp
sudo ufw allow 40400/udp
sudo ufw allow 8080/tcp
sudo ufw enable
```

```bash
mkdir -p "$HOME/aztec-sequencer/data"
```




#### Variables
- dc Sepolia RPC url: `http://localhost:8545`
- dc Beacon Sepolia RPC url: `http://localhost:5052`
```
read -p "RPC Sepolia URL: " RPC_URL
read -p "Beacon Sepolia URL: " CONS_URL
read -p "Wallet address: " WALLET_ADDR
read -p "Your private key: " PRIV_KEY

SERVER_IP=$(curl -s https://api.ipify.org)
    cat > $HOME/aztec-sequencer/.env <<EOF
ETHEREUM_HOSTS=$RPC_URL
L1_CONSENSUS_HOST_URLS=$CONS_URL
VALIDATOR_PRIVATE_KEY=$PRIV_KEY
P2P_IP=$SERVER_IP
WALLET=$WALLET_ADDR
EOF
```

```bash
source /root/aztec-sequencer/.env
```

#### Check Latest Aztec Docker Version
```bash
LATEST=$(curl -s "https://registry.hub.docker.com/v2/repositories/aztecprotocol/aztec/tags?page_size=100" \
      | jq -r '.results[].name' \
      | grep -E '^0\..*-alpha-testnet\.[0-9]+$' \
      | grep -v 'arm64' \
      | sort -V | tail -1)

LATEST=${LATEST:-alpha-testnet}

echo $LATEST
```
#### Run Latest Aztec Docker Version
```bash
docker run --platform linux/amd64 -d \
--name aztec_ut \
--network host \
--env-file "/root/aztec-sequencer/.env" \
-e DATA_DIRECTORY=/data \
-e LOG_LEVEL=debug \
-v "/rooty/aztec-sequencer/data":/data \
aztecprotocol/aztec:"$LATEST" \
sh -c 'node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js start --network alpha-testnet --node --archiver --sequencer'
```
##### Check logs
```bash
docker logs --tail 100 -f aztec_ut
```

#### Get Proof
```bash
TIP=$(curl -s -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"node_getL2Tips","params":[],"id":1}' http://localhost:8080)

BLK=$(echo "$TIP" | jq -r '.result.proven.number')

PROOF=$(curl -s -X POST -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"node_getArchiveSiblingPath\",\"params\":[${BLK},${BLK}],\"id\":1}" http://localhost:8080 | jq -r '.result')

echo -e "Block: $BLK"
echo -e "Proof: $PROOF"
```

#### Register Validator
```bash
source /root/aztec-sequencer/.env
```

```bash
docker exec -e ETHEREUM_HOSTS="$ETHEREUM_HOSTS" \
            -e VALIDATOR_PRIVATE_KEY="$VALIDATOR_PRIVATE_KEY" \
            -e WALLET="$WALLET" \
  -i aztec_ut \
  sh -c 'node /usr/src/yarn-project/aztec/dest/bin/index.js add-l1-validator \
    --l1-rpc-urls "$ETHEREUM_HOSTS" \
    --private-key "$VALIDATOR_PRIVATE_KEY" \
    --attester "$WALLET" \
    --proposer-eoa "$WALLET" \
    --staking-asset-handler 0xF739D03e98e23A7B65940848aBA8921fF3bAc4b2 \
    --l1-chain-id 11155111'
```
