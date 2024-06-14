### Install near-api-js

```bash
npm install near-api-js
```

### Create the `verify-keys.js` file:
```bash
nano /root/verify-keys.js
```

```bash
const fs = require('fs');
const { utils, keyStores, KeyPair } = require('near-api-js');

async function verifyKeys(filePath) {
    const data = JSON.parse(fs.readFileSync(filePath, 'utf-8'));

    const privateKey = data.secret_key;
    const publicKey = data.public_key;

    const keyPair = KeyPair.fromString(privateKey);
    const derivedPublicKey = keyPair.getPublicKey().toString();

    if (derivedPublicKey === publicKey) {
        console.log("The private key matches the public key.");
    } else {
        console.log("The private key does not match the public key.");
    }
}

const filePath = '/root/.near/validator_key.json';
verifyKeys(filePath);
```

### Run the script:
```bash
node /root/verify-keys.js
```
