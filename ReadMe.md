# OffGridPay Smart Contract

**Offline Payment System for React Native Applications**  
**Platform:** FlowEVM (Flow's EVM-compatible blockchain)  
**Framework:** Solidity Smart Contracts  
**Status:** 🚀 **READY FOR INTEGRATION**

**Multi-Token Contract Address (FLOW + PYUSD):**
0x198DD9d62c751937f0DF86c0e451F753858358f3

**FlowScan URL:**
https://evm-testnet.flowscan.org/address/0x198DD9d62c751937f0DF86c0e451F753858358f3

**Legacy Contract (FLOW only):**
0xdA3Db417CEF41d8289df2db62d4752801D1dcb42

## 📱 React Native Integration Ready

OffGridPay enables secure offline payments in mobile applications with seamless blockchain synchronization. Perfect for React Native apps that need to work in areas with poor connectivity.

### Key Features
✅ **Offline Transaction Processing**: Create and store transactions without internet  
✅ **Batch Synchronization**: Sync multiple transactions when connection is restored  
✅ **Secure Wallet Integration**: Built-in deposit and withdrawal management  
✅ **Cryptographic Security**: ECDSA signature validation for all transactions  
✅ **Anti-Fraud Protection**: Replay attack prevention and nonce-based security  
✅ **Mobile Optimized**: Designed specifically for React Native applications  

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

### Compilation

```bash
# Compile contracts
npm run compile
```

### Testing

```bash
# Run tests
npm test
```

### Deployment

```bash
# Deploy to FlowEVM Testnet
npm run deploy:testnet

# Deploy to FlowEVM Mainnet
npm run deploy:mainnet
```

## 🌐 FlowEVM Network Information

### Testnet
- **RPC URL**: `https://testnet.evm.nodes.onflow.org`
- **Chain ID**: `545`
- **Explorer**: https://evm-testnet.flowscan.org
- **Faucet**: https://testnet-faucet.onflow.org/fund-account

### Mainnet
- **RPC URL**: `https://mainnet.evm.nodes.onflow.org`
- **Chain ID**: `747`
- **Explorer**: https://evm.flowscan.org

## 📋 Contract Interface

### Core Functions

#### Account Management
```solidity
// Initialize account with FLOW deposit
function initializeAccount() external payable

// Add more FLOW deposit
function addFlowDeposit() external payable

// Withdraw FLOW deposit
function withdrawFlowDeposit(uint256 amount) external

// Deactivate/reactivate account
function deactivateAccount() external
function reactivateAccount() external
```

#### Transaction Processing
```solidity
// Process batch of offline transactions
function syncOfflineTransactions(TransactionBatch memory batch) external returns (bool)

// Validate transaction signature
function validateSignature(OfflineTransaction memory tx) public view returns (bool)

// Check for replay attacks
function preventReplay(string memory txId) public view returns (bool)
```

#### View Functions
```solidity
function getBalance(address user) external view returns (uint256)
function getDepositBalance(address user) external view returns (uint256)
function getUserNonce(address user) external view returns (uint256)
function isUserActive(address user) external view returns (bool)
function getUserAccount(address user) external view returns (UserAccount memory)
```

### Data Structures

```solidity
struct OfflineTransaction {
    string id;
    address from;
    address to;
    uint256 amount;
    uint256 timestamp;
    uint256 nonce;
    bytes signature;
    TransactionStatus status;
}

struct TransactionBatch {
    string batchId;
    address submitter;
    OfflineTransaction[] transactions;
    uint256 timestamp;
    uint256 flowUsed;
}

struct UserAccount {
    uint256 balance;
    uint256 flowDeposit;
    uint256 nonce;
    uint256 lastSyncTime;
    bool isActive;
    address publicKeyAddress;
}
```

## 🔧 React Native Integration Guide

### Installation

Add these dependencies to your React Native project:

```bash
npm install ethers @react-native-async-storage/async-storage react-native-keychain
# For iOS
cd ios && pod install
```

### Basic Setup

```javascript
import { ethers } from 'ethers';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as Keychain from 'react-native-keychain';

// Contract configuration
const CONTRACT_ADDRESS = "YOUR_DEPLOYED_CONTRACT_ADDRESS";
const CONTRACT_ABI = [...]; // From artifacts/contracts/OffGridPayEVM.sol/OffGridPayEVM.json

// Initialize provider and contract
const provider = new ethers.JsonRpcProvider('https://testnet.evm.nodes.onflow.org');
const contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, provider);
```

### Wallet Integration

```javascript
// Initialize user wallet
export const initializeWallet = async (privateKey) => {
  const wallet = new ethers.Wallet(privateKey, provider);
  const contractWithSigner = contract.connect(wallet);
  
  // Initialize account with deposit
  const tx = await contractWithSigner.initializeAccount({ 
    value: ethers.parseEther("10") 
  });
  await tx.wait();
  
  return wallet.address;
};

// Get user balance
export const getUserBalance = async (userAddress) => {
  return await contract.getBalance(userAddress);
};
```

### Offline Transaction Management

```javascript
// Store offline transaction locally
export const storeOfflineTransaction = async (transaction) => {
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
export const createOfflineTransaction = async (fromAddress, toAddress, amount, privateKey) => {
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
export const syncOfflineTransactions = async (privateKey) => {
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

## 🔒 Security Features

- **ECDSA Signature Verification**: All transactions must be cryptographically signed
- **Replay Attack Prevention**: Each transaction ID can only be processed once
- **Nonce-based Ordering**: Prevents transaction reordering attacks
- **Time-based Expiry**: Transactions expire after 24 hours
- **Secure Key Storage**: Use React Native Keychain for private key storage
- **Local Data Encryption**: AsyncStorage data should be encrypted
- **Reentrancy Protection**: All state-changing functions are protected

## 📱 React Native Best Practices

### Secure Key Management
```javascript
import * as Keychain from 'react-native-keychain';

// Store private key securely
export const storePrivateKey = async (privateKey) => {
  await Keychain.setInternetCredentials(
    'OffGridPay',
    'wallet',
    privateKey
  );
};

// Retrieve private key
export const getPrivateKey = async () => {
  const credentials = await Keychain.getInternetCredentials('OffGridPay');
  return credentials ? credentials.password : null;
};
```

### Network Status Handling
```javascript
import NetInfo from '@react-native-netinfo';

// Check connectivity and sync when online
export const handleConnectivityChange = (isConnected) => {
  if (isConnected) {
    syncOfflineTransactions();
  }
};

// Subscribe to network changes
NetInfo.addEventListener(state => {
  handleConnectivityChange(state.isConnected);
});
```

## 🧪 Testing Your Integration

Test your React Native integration:
1. **Offline Mode**: Disable network and create transactions
2. **Sync Testing**: Re-enable network and verify sync works
3. **Security Testing**: Test with invalid signatures
4. **Edge Cases**: Test with insufficient balance, expired transactions

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
