
# CrossFi Chain Wallet Transition Guide

Follow these steps to import, and export your wallet on the CrossFi chain.

#### Step 1: Download mineplex-chaind v0.1.1

Use the specified version of the Mineplex chain daemon.
```bash
wget https://github.com/crossfichain/crossfi-node/releases/download/v0.1.1/mineplex-2-node._v0.1.1_linux_amd64.tar.gz
```

#### Step 1.1: Import Your Wallet

Use the following command to import your wallet using your seed phrase:

```bash
mineplex-chaind --home /root/.mineplex-chain/ keys add CrossFiWalletName --recover
```
- Enter Keyring Passphrase

#### Step 1.2: Export Your Wallet

Export your wallet with this command:

```bash
mineplex-chaind --home /root/.mineplex-chain/ keys export CrossFiWalletName
```

- Enter Passphrase to Encrypt the Exported Key

During this step, use a simple one-word passphrase like `mineplex`.

- Enter Keyring Passphrase

This passphrase is for the recovered wallet. Ensure it is secure and memorable.

- Copy the Output

Copy the output that begins and ends with the markers for a Tendermint private key:

```
-----BEGIN TENDERMINT PRIVATE KEY-----
kdf: bcrypt
salt: 58CAF85791C7E739AD0F85791C7E7389
type: secp256k1

E4dJ594876NNS2YV6jWX+A0+CGP4nWhMOrtGHab5+JsoK9oG2b76NNS2YV6jW0OW
2A/ijItUd63X8CljQx5VEltUd63X8CljQTkNzww=
=Dwx9
-----END TENDERMINT PRIVATE KEY-----
```
- Create a New File and Paste Output

Use the nano editor to create a new file and paste the private key:

```bash
nano /root/.mineplex-chain/CrossFiWalletName.key
```

## Step 2: Import Wallet using new binaries v0.3.0

Finally, import the wallet using the following command:

```bash
crossfid --home /root/.crossfid/ keys import CrossFiWalletName /root/.mineplex-chain/CrossFiWalletName.key
```
