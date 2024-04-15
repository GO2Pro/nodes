# API Proxies

## RPC

```bash
https://crossfi-testnet-rpc.smartmove.guru/
```

## API
```bash
https://crossfi-testnet-api.smartmove.guru/
```

## Snapshot

```bash
# Install dependencies, if needed
sudo apt update
sudo apt install lz4 -y
```
```bash
sudo systemctl stop crossfid

cp $HOME/.mineplex-chain/data/priv_validator_state.json $HOME/.mineplex-chain/priv_validator_state.json.backup

crossfid tendermint unsafe-reset-all --home $HOME/.mineplex-chain --keep-addr-book
curl https://crossfi-testnet-node.smartmove.guru/crossfi-testnet/crossfi-testnet_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.mineplex-chain

mv $HOME/.mineplex-chain/priv_validator_state.json.backup $HOME/.mineplex-chain/data/priv_validator_state.json

sudo systemctl restart crossfid
sudo journalctl -u crossfid -f --no-hostname -o cat
```

## Address Book

```bash
curl -s https://crossfi-testnet-node.smartmove.guru/crossfi-testnet/addrbook.json > $HOME/.mineplex-chain/config/addrbook.json

sudo systemctl restart crossfid
sudo journalctl -u crossfid -f --no-hostname -o cat
```

## Genesis

```bash
curl -s https://crossfi-testnet-node.smartmove.guru/crossfi-testnet/genesis.json > $HOME/.mineplex-chain/config/genesis.json

sudo systemctl restart crossfid
sudo journalctl -u crossfid -f --no-hostname -o cat
```
