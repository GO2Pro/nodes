
### Install s5cmd
```bash
sudo wget https://github.com/peak/s5cmd/releases/download/v2.2.2/s5cmd_2.2.2_Linux-64bit.tar.gz -P /root/
sudo mkdir /root/s5cmd_release
sudo tar -zxvf /root/s5cmd_2.2.2_Linux-64bit.tar.gz -C /root/s5cmd_release
sudo rm /root/s5cmd_2.2.2_Linux-64bit.tar.gz
sudo chmod +x /root/s5cmd_release/s5cmd
sudo mv /root/s5cmd_release/s5cmd /usr/local/bin/
sudo rm -r /root/s5cmd_release
```

### Stop your node
```bash
sudo systemctl stop neard
```
### Prepare
#### Clear a directory if need
```bash
sudo rm -rf /root/.near/data/*
```

#### Get the date
```bash
aws s3 --no-sign-request cp s3://near-protocol-public/backups/statelessnet/rpc/latest /root/.near/
```
#### Check the date
```bash
LATEST=$(cat /root/.near/latest)
echo $LATEST
```

### Sync Options:

#### Sync with s5cmd (Asynchronous, fast.)
```bash
s5cmd --no-sign-request sync "s3://near-protocol-public/backups/statelessnet/rpc/${LATEST:?}/*" /root/.near/data/
```
#### Sync with aws (Single-thread, slow.)
```bash
aws s3 --no-sign-request cp s3://near-protocol-public/backups/statelessnet/rpc/latest /root/.near/
```
### Start your node
```bash
sudo systemctl start neard && journalctl -n 100 -f -u neard | ccze -A
```
