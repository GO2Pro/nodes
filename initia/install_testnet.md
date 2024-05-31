[Documentation Running Initia Node](https://docs.initia.xyz/run-initia-node/running-initia-node/boot-an-initia-node)

## Hardware requirements
```py
- CPU: 16 cores
- Memory: 16GB RAM
- Disk: 2 TB SSD Storage with Write Throughput > 1000 MiBps
- Bandwidth: 100 Mbps
- Linux amd64 arm64 (Ubuntu LTS release)
```
## 1. Installation guide

### 1.1. Install required package
```bash
sudo apt update -y
```

### 1.2. Install dependencies
```bash
sudo apt install -y nano curl git wget aria2 htop tmux build-essential jq make lz4 gcc unzip clang pkg-config libssl-dev ncdu bsdmainutils nvme-cli libleveldb-dev tar cron nginx certbot python3-certbot-nginx
```

### 1.3. Install Go
```bash
ver="1.22.3"
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
mkdir -p $HOME/go/bin
go version
```

## 2. Variables

### 2.1. Node Path
```bash
echo 'export NODE_PATH="$HOME/.initia"' >> $HOME/.bash_profile
```

### 2.2. Config Path
```bash
echo 'export APP_TOML_PATH="$NODE_PATH/config/app.toml"' >> $HOME/.bash_profile
echo 'export CONFIG_TOML_PATH="$NODE_PATH/config/config.toml"' >> $HOME/.bash_profile
```
### 2.3. Node
```bash
echo "export WALLET="<...>"" >> $HOME/.bash_profile
echo "export MONIKER="<...>"" >> $HOME/.bash_profile
echo "export _CHAIN_ID="initiation-1"" >> $HOME/.bash_profile
source $HOME/.bash_profile
```

## 3. Install `initia` binary

### 3.1. Download Binary
```bash
cd $HOME
rm -rf initia
git clone https://github.com/initia-labs/initia.git
cd initia
git checkout v0.2.15
```

### 3.2. Build Binaries
```bash
make build
```

### 3.3. Move Binary
```bash
chmod +x $HOME/initia/build/
mv $HOME/initia/build/initiad $HOME/go/bin
```

### 3.4. Setup Configuration
```bash
initiad config set client chain-id $_CHAIN_ID
initiad config set client keyring-backend test
initiad config set client node tcp://localhost:26657
```

### 3.5. Init Node
```bash
initiad init $MONIKER --chain-id $_CHAIN_ID
```

### 3.6. Download Genesis
```bash
wget https://initia.s3.ap-southeast-1.amazonaws.com/initiation-1/genesis.json -O $HOME/.initia/config/genesis.json
```

### 3.7. Download Addrbook
```bash
wget -O $HOME/.initia/config/addrbook.json https://initia.s3.ap-southeast-1.amazonaws.com/initiation-1/addrbook.json
```

## 4. Configure app.toml

### 4.1. Set pruning
```bash
pruning="custom"
pruning_keep_recent="100"
pruning_interval="10"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $APP_TOML_PATH
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $APP_TOML_PATH
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $APP_TOML_PATH
```

### 4.2. Snapshots on/off
```bash
snapshot_interval=5000
sed -i -e "s/^snapshot-interval *=.*/snapshot-interval = \"$snapshot_interval\"/" $APP_TOML_PATH
```

### 4.3. Set minimum gas price
```bash
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.15uinit,0.01uusdc\"|" $APP_TOML_PATH
```

### 4.4. API
```bash
sed -i -e '/\[api\]/,/\[/{s|enable = false|enable = true|}' $APP_TOML_PATH
sed -i -e '/\[api\]/,/\[/{s|swagger = false|swagger = true|}' $APP_TOML_PATH
sed -i -e '/\[api\]/,/\[/{s|address = "tcp://localhost:1317"|address = "tcp://0.0.0.0:1317"|}' $APP_TOML_PATH
```

### 4.5. GRPC
```bash
sed -i -e '/\[grpc\]/,/\[/{s|enable = false|enable = true|}' $APP_TOML_PATH
sed -i -e '/\[grpc\]/,/\[/{s|address = "localhost:9090"|address = "0.0.0.0:9090"|}' $APP_TOML_PATH
```

### 4.6. Oracle
```bash
sed -i -e '/\[oracle\]/,/\[/{s|enabled = "false"|enabled = true|}' $APP_TOML_PATH
sed -i -e '/\[oracle\]/,/\[/{s|oracle_address = ""|oracle_address = "127.0.0.1:8080"|}' $APP_TOML_PATH
sed -i -e '/\[oracle\]/,/\[/{s|client_timeout = "2s"|client_timeout = "500ms"|}' $APP_TOML_PATH
sed -i -e '/\[oracle\]/,/\[/{s|metrics_enabled = true|metrics_enabled = false|}' $APP_TOML_PATH
```

### 4.7.  GRPC-WEB
```bash
nano $APP_TOML_PATH
```

#### 4.7.1.  Add to section:
```bash
# Address defines the gRPC-web server address to bind to.
address = "0.0.0.0:9091"
```

## 5. Configure config.toml

### 5.1. External Address
```bash
external_address=$(wget -qO- eth0.me)
sed -i -e "s/^external_address *=.*/external_address = \"$external_address:26656\"/" $CONFIG_TOML_PATH
```

### 5.2. Increase the number of inbound and outbound peers for the connection, except for persistent peers in config.toml
```bash
sed -i 's/max_num_inbound_peers =.*/max_num_inbound_peers = 300/g' $CONFIG_TOML_PATH
sed -i 's/max_num_outbound_peers =.*/max_num_outbound_peers = 300/g' $CONFIG_TOML_PATH
```

### 5.3. Turn off indexing
```bash
indexer="null"
sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $CONFIG_TOML_PATH
```

### 5.4. Enable RPC
```bash
sed -i -e '/\[rpc\]/,/laddr =/{s/laddr = "tcp:\/\/127.0.0.1:\([0-9]*\)"/laddr = "tcp:\/\/0.0.0.0:\1"/}' $CONFIG_TOML_PATH
```

### 5.5. Add Seeds
```bash
SEEDS="2eaa272622d1ba6796100ab39f58c75d458b9dbc@34.142.181.82:26656,c28827cb96c14c905b127b92065a3fb4cd77d7f6@testnet-seeds.whispernode.com:25756"
sed -i -e "s/^seeds =.*/seeds = \"$SEEDS\"/" $CONFIG_TOML_PATH
```

### 5.6. Add Peers
```bash
PEERS="093e1b89a498b6a8760ad2188fbda30a05e4f300@35.240.207.217:26656,2c729d33d22d8cdae6658bed97b3097241ca586c@195.14.6.129:26019"
sed -i -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $CONFIG_TOML_PATH
```

## 6. Service
### 6.1. Create a service file
```bash
sudo tee /etc/systemd/system/initiad.service > /dev/null <<EOF
[Unit]
Description=Initia Node Servicec
After=network-online.target

[Service]
User=$USER
ExecStart=$(which initiad) start --home $HOME/.initia
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
Environment="DAEMON_HOME=$HOME/.initia"
Environment="DAEMON_NAME=initiad"

[Install]
WantedBy=multi-user.target
EOF
```
### 6.2. Start the node
```bash
systemctl daemon-reload
systemctl enable initiad
systemctl restart initiad && journalctl -u initiad -f -o cat
```

### 6.3. Check the synchronization status
```bash
initiad status | jq -r .sync_info
```

## 7. Wallet

### 7.1. Create a wallet for your validator
```bash
initiad keys add $WALLET
# DO NOT FORGET TO SAVE THE SEED PHRASE
```

### 7.2. Or Recover from seed phrase
```bash
initiad keys add $WALLET --recover
```
### 7.3. Export Variables
```bash
WALLET_ADDRESS=$(initiad keys show $WALLET -a)
VALOPER_ADDRESS=$(initiad keys show $WALLET --bech val -a)
echo "export WALLET_ADDRESS="$WALLET_ADDRESS >> $HOME/.bash_profile
echo "export VALOPER_ADDRESS="$VALOPER_ADDRESS >> $HOME/.bash_profile
source $HOME/.bash_profile
```
### 7.4. Check Addresses
```bash
echo $WALLET_ADDRESS
echo $VALOPER_ADDRESS
```
### 7.5. Request tokens from the faucet
-> <a href="https://faucet.testnet.initia.xyz/"><font size="4"><b><u>FAUCET</u></b></font></a> <-

### 7.6. Check wallet balance
```bash
initiad q bank balances $(initiad keys show $WALLET -a)
```

## 8. Download latest snapshot from endpoint

### 8.1. Delete Old Snapshotes
```bash
rm $HOME/latest_snapshot.tar*.lz4*
```
### 8.2. Download latest snapshot from kjnodes
```bash
aria2c -x5 -s4 -d $HOME -o latest_snapshot.tar.lz4 https://snapshots.kjnodes.com/initia-testnet/snapshot_latest.tar.lz4
```
### 8.3. Stop Initia Node
```bash
sudo systemctl stop initiad
```
### 8.4. Backup priv_validator_state.json
```bash
cp $HOME/.initia/data/priv_validator_state.json $HOME/.initia/priv_validator_state.json.backup
```
### 8.5. Reset DB
```bash
initiad tendermint unsafe-reset-all --home $HOME/.initia --keep-addr-book
```
### 8.6. Extract files from the arvhive
```bash
lz4 -d -c $HOME/latest_snapshot.tar.lz4 | tar -xf - -C $HOME/.initia/
```
### 8.7. Move priv_validator_state.json back
```bash
mv $HOME/.initia/priv_validator_state.json.backup $HOME/.initia/data/priv_validator_state.json
```
### 8.8. Restart
```bash
systemctl restart initiad && journalctl -u initiad -f -o cat
```
### 8.9. Check the synchronization status
```bash
initiad status | jq -r .sync_info
```

## 9. Create Validator

### 9.1. Check balance
```bash
initiad query bank balances $WALLET
```
### 9.2. Create a validator
```bash
initiad tx mstaking create-validator \
--amount=1000000uinit \
--pubkey=$(initiad tendermint show-validator) \
--moniker=$MONIKER \
--identity=<...> \
--details="<...>" \
--website="<...>" \
--security-contact="<...>" \
--chain-id=$_CHAIN_ID \
--commission-rate=0.10 \
--commission-max-rate=0.20 \
--commission-max-change-rate=0.01 \
--min-self-delegation="1" \
--from=$WALLET \
--gas-prices=0.15uinit \
--gas-adjustment=1.5 \
--gas=auto \
-y
```

### 9.3. Delegate 1000 MPX
```bash
initiad tx mstaking delegate $(initiad keys show $MONIKER --bech val -a) 1000000uinit --from $WALLET --chain-id $_CHAIN_ID --gas-prices 0.15uinit --gas-adjustment 1.4 --gas auto -y
```

## 10. Set up Oracle

[Official documentation](https://docs.initia.xyz/run-initia-node/running-initia-node/oracle)

### 10.1. Download Binary
```bash
cd $HOME
rm -rf slinky
git clone https://github.com/skip-mev/slinky.git
cd slinky
git checkout v0.4.3
```
### 10.2. Build Binaries
```bash
make build
```
### 10.3. Move Binary
```bash
chmod +x $HOME/slinky/build/slinky
mv $HOME/slinky/build/slinky $HOME/go/bin
```

### 10.4. CREATE SYSTEMD SERVICE
```bash
sudo tee /etc/systemd/system/slinky.service > /dev/null <<EOF
[Unit]
Description=Initia Slinky Oracle
After=network-online.target

[Service]
User=$USER
ExecStart=$(which slinky) --oracle-config-path $HOME/slinky/config/core/oracle.json --market-map-endpoint 0.0.0.0:9090
Restart=on-failure
RestartSec=30
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
```
### 10.5. Start the Oracle
```bash
sudo systemctl daemon-reload
sudo systemctl enable slinky
sudo systemctl start slinky
```
### 10.6. Check logs
```bash
journalctl -u slinky -f -o cat
```
