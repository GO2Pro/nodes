## Install dependencies

```bash
apt-get update
```

```bash
sudo apt install -y nano cron git curl docker.io
```

### Docker Compose
Download the Docker Compose binary and installs it into the `/usr/local/bin` directory.
```bash
sudo curl -L "https://github.com/docker/compose/releases/download/2.24.7/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
```

Grant the execute permission to the Docker Compose binary file.
```bash
sudo chmod +x /usr/local/bin/docker-compose
```

Check version
```bash
docker --version
docker-compose --version
```

### Install Go

```bash
sudo rm -rf /usr/local/go
curl -L https://go.dev/dl/go1.22.1.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
source .bash_profile
```

Check version
```bash
go version
```

## Install CLI from Source

Clone the EigenLayer repository
```bash
git clone https://github.com/Layr-Labs/eigenlayer-cli
```

```bash
mkdir -p $HOME/eigenlayer-cli/build
cd eigenlayer-cli
```

Compile the Go program located at `cmd/eigenlayer/main.go` and generate an executable binary named `eigenlayer`.
```bash
go build -o build/eigenlayer cmd/eigenlayer/main.go
```

Copy the `eigenlayer` executable binary from the `./build` directory to the `/usr/local/bin/` directory, making it accessible system-wide for execution.
```bash
cp ./build/eigenlayer /usr/local/bin/
```

Start EigenLayer
```bash
eigenlayer
```

## Generate keys

```bash
export KEY_NAME=YourKeyName
```

**ECDSA**
```bash
eigenlayer operator keys create --key-type ecdsa $KEY_NAME
```

**BLS**
```bash
eigenlayer operator keys create --key-type bls $KEY_NAME
```

This process requires you to create a password for generating two types of keys: ECDSA and BLS. It's important to choose a strong password and make sure to save your keys securely.

Check keys
```bash
eigenlayer operator keys list
```

## Prepare Config Files

Creating the required config files (`operator.yaml` and `metadata.json`) for the registration process:

```bash
eigenlayer operator config create
```

*? Would you like to populate the operator config file?*

Type `N`.

### Edit `metadata.json`

```bash
nano $HOME/eigenlayer-cli/metadata.json
```

```json
{
	"name": "<YOUR_OPERATOR_NAME>",
	"website": "<YOUR_WEBSITE>",
	"description": "<RANDOM_DESCRIPTION>",
	"logo": "<URL_OF_YOUR_LOGO>",
	"twitter": "<YOUR_TWITTER>"
}
```

Operator registration only supports `.png` file format.

### Creating GitHub Repository

1. Create a repository on GitHub, which you can name "eigenlayer".
2. In this repository, create a file named `metadata.json`.
3. Fill this file with content similar to how we previously filled the `$HOME/eigenlayer-cli/metadata.json` file for the node.
4. Make sure to commit your changes to save the file.
5. Click on `Raw` and copy the URL of the file.

```json
{
	"name": "<YOUR_OPERATOR_NAME>",
	"website": "<YOUR_WEBSITE>",
	"description": "<RANDOM_DESCRIPTION>",
	"logo": "<URL_OF_YOUR_LOGO>",
	"twitter": "<YOUR_TWITTER>"
}
```

### Edit `operator.yaml`

```bash
nano $HOME/eigenlayer-cli/operator.yaml
```

Example:
```yaml
operator:
    address: <ECDSA_ADRESS>
    earnings_receiver_address: <ECDSA_ADRESS>
    delegation_approver_address: 0x0000000000000000000000000000000000000000
    staker_opt_out_window_blocks: 0
    metadata_url: <RAW_URL>
el_delegation_manager_address: 0x1b7b8F6b258f95Cf9596EabB9aa18B62940Eb0a8
eth_rpc_url: https://rpc.ankr.com/eth_goerli
private_key_store_path: /root/.eigenlayer/operator_keys/<KEY_NAME>.ecdsa.key.json
signer_type: local_keystore
chain_id: 5
```

- `<ECDSA_ADRESS>` : ETH address generated.
- `<RAW_URL>` : URL of your Raw `metadata.json` file from GitHub.
- `<KEY_NAME>` : this your previously defined key name `echo $KEY_NAME`.


## Faucet Top up

You'll require some goerliETH in the wallet you've created.

- [Paradigm Faucet](https://faucet.paradigm.xyz/)
- [Alchemy Faucet](https://www.alchemy.com/faucets/ethereum-goerli)


## Operator Registration

```bash
eigenlayer operator register operator.yaml
```

Confirm with your ECDSA password.

### If you receive an error:
```bash
panic: runtime error: invalid memory address or nil pointer dereference
```
Solution:
```bash
cd /root/eigenlayer-cli/cmd/eigenlayer/
go get github.com/Layr-Labs/eigensdk-go@v0.1.2
go build
```
Then go back to directory `cd /root/eigenlayer-cli/`, and start operator registration again.

Check your operator registration status.
```bash
eigenlayer operator status operator.yaml
```

### Delegate to your operator

```
https://goerli.eigenlayer.xyz/operator
```
