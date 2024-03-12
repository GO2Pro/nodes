### Manual Installation

[Official Documentation](https://docs.crossfi.org/crossfi-chain/technical-information/validators)

Recommended Hardware: 6 Cores, 8GB RAM, 400GB of storage (NVME)

#### Install dependencies

```bash
sudo apt update
```

```bash
sudo apt install -y curl git wget htop tmux build-essential jq make lz4 gcc unzip
```

#### Install Go

```bash
sudo rm -rf /usr/local/go
curl -L https://go.dev/dl/go1.21.6.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
source .bash_profile
```


#### Download binary

```bash
cd $HOME && mkdir -p $HOME/go/bin
curl -L https://github.com/crossfichain/crossfi-node/releases/download/v0.3.0-prebuild3/crossfi-node_0.3.0-prebuild3_linux_amd64.tar.gz > crossfi-node_0.3.0-prebuild3_linux_amd64.tar.gz
tar -xvzf crossfi-node_0.3.0-prebuild3_linux_amd64.tar.gz
chmod +x $HOME/bin/crossfid
mv $HOME/bin/crossfid $HOME/go/bin
rm -rf crossfi-node_0.3.0-prebuild3_linux_amd64.tar.gz readme.md $HOME/bin
```

Check Version
```bash
crossfid version --long | grep -e version -e commit -e build
```

#### Set node CLI configuration
```bash
crossfid config chain-id crossfi-evm-testnet-1
crossfid config keyring-backend test
crossfid config node tcp://localhost:26057
```

```bash
MONIKER=YourMoniker
echo "export MONIKER="$MONIKER >> $HOME/.bash_profile
source $HOME/.bash_profile
```

#### Initialize the node
```bash
crossfid init $MONIKER --chain-id crossfi-evm-testnet-1
```

#### Download genesis

```bash
wget -O $HOME/.mineplex-chain/config/genesis.json "https://raw.githubusercontent.com/crossfichain/testnet/master/config/genesis.json"
```

#### Download addrbook
```bash
curl -L https://crossfi-testnet-node.smartmove.guru/crossfi-testnet/genesis.json > $HOME/.mineplex-chain/config/genesis.json
curl -L https://crossfi-testnet-node.smartmove.guru/crossfi-testnet/addrbook.json > $HOME/.mineplex-chain/config/addrbook.json
```

#### Set seeds
```bash
sed -i -e 's|^seeds *=.*|seeds = "89752fa7945a06e972d7d860222a5eeaeab5c357@128.140.70.97:26656,dd83e3c7c4e783f8a46dbb010ec8853135d29df0@crossfi-testnet-seed.itrocket.net:36656"|' $HOME/.mineplex-chain/config/config.toml
```

#### Set minimum gas price
```bash
sed -i -e 's|^minimum-gas-prices *=.*|minimum-gas-prices = "5000000000mpx"|' $HOME/.mineplex-chain/config/app.toml
```

#### Set pruning
```bash
sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "17"|' \
  $HOME/.mineplex-chain/config/app.toml
```

#### Change ports
```bash
sed -i -e "s%:1317%:26017%; s%:8080%:26080%; s%:9090%:26090%; s%:9091%:26091%; s%:8545%:26045%; s%:8546%:26046%; s%:6065%:26065%" $HOME/.mineplex-chain/config/app.toml
sed -i -e "s%:26658%:26058%; s%:26657%:26057%; s%:6060%:26060%; s%:26656%:26056%; s%:26660%:26061%" $HOME/.mineplex-chain/config/config.toml
```

#### Create a service
```bash
sudo tee /etc/systemd/system/crossfid.service > /dev/null << EOF
[Unit]
Description=CrossFi node service
After=network-online.target
[Service]
User=$USER
ExecStart=$(which crossfid) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
```

#### Start the service and check the logs
```bash
sudo systemctl daemon-reload
sudo systemctl enable crossfid
sudo systemctl restart crossfid && sudo journalctl -u crossfid -f -o cat
```


### Create wallet

```bash
# to create a new wallet, use the following command. don’t forget to save the mnemonic
crossfid keys add $WALLET

# to restore exexuting wallet, use the following command
crossfid keys add $WALLET --recover

# save wallet and validator address
WALLET_ADDRESS=$(crossfid keys show $WALLET -a)
VALOPER_ADDRESS=$(crossfid keys show $WALLET --bech val -a)
echo "export WALLET_ADDRESS="$WALLET_ADDRESS >> $HOME/.bash_profile
echo "export VALOPER_ADDRESS="$VALOPER_ADDRESS >> $HOME/.bash_profile
source $HOME/.bash_profile

# check sync status, once your node is fully synced, the output from above will print "false"
crossfid status 2>&1 | jq .SyncInfo

# before creating a validator, you need to fund your wallet and check balance
crossfid query bank balances $WALLET_ADDRESS
```

### Create validator

```bash
crossfid tx staking create-validator \
--amount 1000000mpx \
--from $WALLET \
--commission-rate 0.1 \
--commission-max-rate 0.2 \
--commission-max-change-rate 0.01 \
--min-self-delegation 1 \
--pubkey $(crossfid tendermint show-validator) \
--moniker $MONIKER \
--identity "" \
--details "I love CrossFi ❤️" \
--chain-id crossfi-evm-testnet-1 \
--gas auto --gas-adjustment 1.5 --gas-prices 10000000000000mpx \
-y
```
