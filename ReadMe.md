# OffGridPay Smart Contract

**Offline Payment System for React Native Applications**  
**Platform:** FlowEVM (Flow's EVM-compatible blockchain)  
**Framework:** Solidity Smart Contracts  
**Status:** 🚀 **READY FOR INTEGRATION**

## 🚀 Deployment Information

**Contract Address:** `0x5495134c932c7e8a`  
**Network:** FlowEVM Testnet  
**Chain ID:** 545  
**Status:** Ready for Deployment ⚡

## Overview

OffGridPay enables secure offline payments in mobile applications with seamless blockchain synchronization. Perfect for React Native apps that need to work in areas with poor connectivity. The system maintains transaction integrity through cryptographic signatures and manages gas costs via FLOW token deposits.

### Key Features
✅ **Offline Transaction Processing**: Create and store transactions without internet  
✅ **Batch Synchronization**: Sync multiple transactions when connection is restored  
✅ **Secure Wallet Integration**: Built-in deposit and withdrawal management  
✅ **Cryptographic Security**: ECDSA signature validation for all transactions  
✅ **Anti-Fraud Protection**: Replay attack prevention and nonce-based security  
✅ **Mobile Optimized**: Designed specifically for React Native applications

## Project Structure

```
├── contracts/                 # Solidity smart contracts
│   └── OffGridPayEVM.sol     # Main OffGridPay contract
├── scripts/                   # Deployment scripts
├── test/                      # Contract unit tests
├── hardhat.config.js         # Hardhat configuration
├── package.json              # Dependencies
└── README.md                 # Integration guide
```

## 🚀 Quick Start

### Prerequisites
- Node.js v16 or higher
- npm or yarn
- FlowEVM wallet with FLOW tokens

### Installation

```bash
# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Edit .env with your private key
nano .env
```

### Configuration

Edit `.env` file:
```bash
# Your wallet private key (without 0x prefix)
PRIVATE_KEY=your_private_key_here

# Optional: Enable gas reporting
REPORT_GAS=true
```

### Contract Information
- **Contract Name:** `OffGridPayEVM`
- **Network:** FlowEVM Testnet
- **Chain ID:** 545
- **RPC URL:** `https://testnet.evm.nodes.onflow.org`

### 📋 Core Contract Functions

#### Account Management
```javascript
// Initialize user account with FLOW deposit
const initializeAccount = async (depositAmount) => {
  const wallet = new ethers.Wallet(privateKey, provider);
  const contractWithSigner = contract.connect(wallet);
  
  const tx = await contractWithSigner.initializeAccount({ 
    value: ethers.parseEther(depositAmount.toString()) 
  });
  await tx.wait();
  return tx.hash;
};

// Add more FLOW deposit
const addDeposit = async (amount) => {
  const wallet = new ethers.Wallet(privateKey, provider);
  const contractWithSigner = contract.connect(wallet);
  
  const tx = await contractWithSigner.addFlowDeposit({ 
    value: ethers.parseEther(amount.toString()) 
  });
  await tx.wait();
  return tx.hash;
};

// Withdraw FLOW deposit
const withdrawDeposit = async (amount) => {
  const wallet = new ethers.Wallet(privateKey, provider);
  const contractWithSigner = contract.connect(wallet);
  
  const tx = await contractWithSigner.withdrawFlowDeposit(
    ethers.parseEther(amount.toString())
  );
  await tx.wait();
  return tx.hash;
};
```

#### Offline Transaction Management

```javascript
// Store offline transaction locally
const storeOfflineTransaction = async (transaction) => {
  try {
    const existingTxs = await AsyncStorage.getItem('offlineTransactions');
    const transactions = existingTxs ? JSON.parse(existingTxs) : [];
    transactions.push(transaction);
    await AsyncStorage.setItem('offlineTransactions', JSON.stringify(transactions));
  } catch (error) {
    console.error('Error storing offline transaction:', error);
  }
};

// Create offline transaction
const createOfflineTransaction = async (fromAddress, toAddress, amount, privateKey) => {
  const wallet = new ethers.Wallet(privateKey);
  const nonce = await contract.getUserNonce(fromAddress);
  
  const transaction = {
    id: ethers.keccak256(ethers.toUtf8Bytes(`${fromAddress}-${toAddress}-${nonce}-${Date.now()}`)),
    from: fromAddress,
    to: toAddress,
    amount: ethers.parseEther(amount.toString()),
    timestamp: Math.floor(Date.now() / 1000),
    nonce: nonce + 1,
    status: 0 // Pending
  };
  
  // Sign transaction
  const messageHash = ethers.solidityPackedKeccak256(
    ['string', 'address', 'address', 'uint256', 'uint256', 'uint256'],
    [transaction.id, transaction.from, transaction.to, transaction.amount, transaction.timestamp, transaction.nonce]
  );
  transaction.signature = await wallet.signMessage(ethers.getBytes(messageHash));
  
  await storeOfflineTransaction(transaction);
  return transaction;
};

// Sync offline transactions when online
const syncOfflineTransactions = async (privateKey) => {
  try {
    const storedTxs = await AsyncStorage.getItem('offlineTransactions');
    if (!storedTxs) return;
    
    const transactions = JSON.parse(storedTxs);
    const pendingTxs = transactions.filter(tx => tx.status === 0);
    
    if (pendingTxs.length === 0) return;
    
    const wallet = new ethers.Wallet(privateKey, provider);
    const contractWithSigner = contract.connect(wallet);
    
    const batch = {
      batchId: `batch-${Date.now()}`,
      submitter: wallet.address,
      transactions: pendingTxs,
      timestamp: Math.floor(Date.now() / 1000),
      flowUsed: ethers.parseEther("0.1")
    };
    
    const tx = await contractWithSigner.syncOfflineTransactions(batch);
    await tx.wait();
    
    // Update local storage
    const updatedTxs = transactions.map(tx => 
      pendingTxs.find(pending => pending.id === tx.id) 
        ? { ...tx, status: 1 } // Completed
        : tx
    );
    await AsyncStorage.setItem('offlineTransactions', JSON.stringify(updatedTxs));
    
  } catch (error) {
    console.error('Error syncing transactions:', error);
  }
};
```

#### Query Functions

```javascript
// Get user balance
const getUserBalance = async (userAddress) => {
  return await contract.getBalance(userAddress);
};

// Get user deposit balance
const getDepositBalance = async (userAddress) => {
  return await contract.getDepositBalance(userAddress);
};

// Get user nonce
const getUserNonce = async (userAddress) => {
  return await contract.getUserNonce(userAddress);
};

// Check if user is active
const isUserActive = async (userAddress) => {
  return await contract.isUserActive(userAddress);
};

// Get complete user account info
const getUserAccount = async (userAddress) => {
  return await contract.getUserAccount(userAddress);
};
```

### 🔒 Security Features

- **ECDSA Signature Verification**: All transactions must be cryptographically signed
- **Replay Attack Prevention**: Each transaction ID can only be processed once
- **Nonce-based Ordering**: Prevents transaction reordering attacks
- **Time-based Expiry**: Transactions expire after 24 hours
- **Secure Key Storage**: Use React Native Keychain for private key storage
- **Local Data Encryption**: AsyncStorage data should be encrypted
- **Reentrancy Protection**: All state-changing functions are protected

```bash
# Run smart contract tests
npm test

# Deploy to FlowEVM testnet
npm run deploy:testnet
```

## 🚀 React Native App Setup

### 1. Install Dependencies
```bash
npm install ethers @react-native-async-storage/async-storage react-native-keychain @react-native-netinfo/netinfo
```

### 2. Configure Metro (metro.config.js)
```javascript
const { getDefaultConfig } = require('metro-config');

module.exports = (async () => {
  const {
    resolver: { sourceExts, assetExts },
  } = await getDefaultConfig();
  return {
    resolver: {
      assetExts: assetExts.filter(ext => ext !== 'svg'),
      sourceExts: [...sourceExts, 'svg'],
    },
  };
})();
```

### 3. Add Contract Address
After deploying your contract, update your React Native app with the contract address:

```javascript
// config/contract.js
export const CONTRACT_CONFIG = {
  address: 'YOUR_DEPLOYED_CONTRACT_ADDRESS',
  network: 'flowTestnet', // or 'flowMainnet'
  rpcUrl: 'https://testnet.evm.nodes.onflow.org'
};
```

## 📞 Support & Resources

### React Native Integration Help
- **Ethers.js Documentation**: [https://docs.ethers.org/](https://docs.ethers.org/)
- **React Native AsyncStorage**: [https://react-native-async-storage.github.io/](https://react-native-async-storage.github.io/)
- **React Native Keychain**: [https://github.com/oblador/react-native-keychain](https://github.com/oblador/react-native-keychain)

### FlowEVM Resources
- **FlowEVM Documentation**: [https://developers.flow.com/evm/about](https://developers.flow.com/evm/about)
- **FlowEVM Testnet Faucet**: [https://testnet-faucet.onflow.org/fund-account](https://testnet-faucet.onflow.org/fund-account)
- **FlowScan Explorer**: [https://evm-testnet.flowscan.org](https://evm-testnet.flowscan.org)

### Common Issues
1. **Metro bundler issues**: Clear cache with `npx react-native start --reset-cache`
2. **iOS build issues**: Run `cd ios && pod install`
3. **Android build issues**: Clean with `cd android && ./gradlew clean`

## 📄 License

MIT License - Perfect for commercial React Native applications.
