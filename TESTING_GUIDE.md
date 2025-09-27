# 🧪 LIN Protocol Testing Guide

Complete testing suite for your deployed LIN Protocol contract on FlowEVM testnet.

## 📍 Contract Information

- **Contract Address**: `0x5047983EC64EF766B6a524FA2b6E1C3f766B84D6`
- **Network**: FlowEVM Testnet (Chain ID: 545)
- **Status**: ✅ Deployed and Verified
- **Explorer**: https://evm-testnet.flowscan.io/address/0x5047983EC64EF766B6a524FA2b6E1C3f766B84D6

## 🎯 Available Testing Scripts

### 1. Unit Tests (Local)
```bash
npm test
```
**Purpose**: Run comprehensive unit tests (20 tests)  
**Duration**: ~30 seconds  
**Coverage**: All contract functions, edge cases, security features

### 2. Contract Integration Test
```bash
npm run test:contract
```
**Purpose**: Test all functions on the deployed contract  
**Duration**: ~2-3 minutes  
**Features Tested**:
- ✅ Account initialization and management
- ✅ Flow deposit operations
- ✅ Balance management
- ✅ Transaction validation (signatures, nonces, replay protection)
- ✅ Utility functions
- ✅ Emergency functions
- ✅ View functions

### 3. Interactive Testing
```bash
npm run test:interactive
```
**Purpose**: Manual testing with interactive menu  
**Duration**: User-controlled  
**Features**:
- 🎮 Interactive menu system
- 👤 Test with multiple accounts
- 🔧 Test individual functions
- 📊 Real-time results

### 4. Batch Transaction Testing
```bash
npm run test:batch
```
**Purpose**: Test offline transaction batch processing  
**Duration**: ~1-2 minutes  
**Features Tested**:
- 📱 Offline transaction creation
- 🔐 Signature generation and validation
- 🔄 Batch synchronization
- 💰 Balance updates
- 🔢 Nonce management
- 🚫 Replay protection

### 5. Performance Testing
```bash
npm run test:performance
```
**Purpose**: Measure contract performance and gas usage  
**Duration**: ~3-5 minutes  
**Metrics**:
- ⚡ Mass account initialization
- 📊 Batch size optimization
- 🔄 Concurrent operations
- 👀 View function performance
- 💡 Performance recommendations

### 6. Complete Test Suite
```bash
npm run test:all
```
**Purpose**: Run all tests sequentially  
**Duration**: ~8-12 minutes  
**Includes**: Unit tests + Integration + Batch + Performance

## 🚀 Quick Start Testing

### Prerequisites
1. Ensure your `.env` file is configured with your private key
2. Have FlowEVM testnet FLOW tokens in your wallet
3. Contract should be deployed and verified

### Basic Testing Flow
```bash
# 1. Run unit tests first
npm test

# 2. Test the deployed contract
npm run test:contract

# 3. Test batch transactions
npm run test:batch

# 4. Optional: Run performance tests
npm run test:performance
```

## 📋 Test Scenarios Covered

### Account Management
- ✅ Initialize accounts with FLOW deposits
- ✅ Add/withdraw FLOW deposits
- ✅ Activate/deactivate accounts
- ✅ Update account balances (admin)
- ✅ View account details

### Transaction Processing
- ✅ Create offline transactions
- ✅ Generate transaction IDs
- ✅ Validate ECDSA signatures
- ✅ Check nonce sequences
- ✅ Prevent replay attacks
- ✅ Handle transaction expiry
- ✅ Process transaction batches

### Security Features
- ✅ Signature validation
- ✅ Replay attack prevention
- ✅ Nonce-based ordering
- ✅ Time-based expiry
- ✅ Access control (owner functions)
- ✅ Reentrancy protection

### Gas Optimization
- ✅ Batch processing efficiency
- ✅ Optimal batch sizes
- ✅ Gas usage per transaction
- ✅ Concurrent operation handling

## 🎮 Interactive Testing Menu

When you run `npm run test:interactive`, you'll see:

```
🎯 Choose a test to run:
==================================================
1.  📊 View Contract State
2.  🏗️  Initialize Account
3.  💰 Add Flow Deposit
4.  💸 Withdraw Flow Deposit
5.  👤 View Account Details
6.  ⚖️  Update Account Balance (Admin)
7.  🔒 Deactivate Account
8.  🔓 Reactivate Account
9.  🔐 Test Signature Validation
10. 🔢 Test Nonce Validation
11. 🔄 Test Replay Protection
12. ⏰ Test Transaction Expiry
13. 🛠️  Generate Transaction ID
14. 📱 Create Offline Transaction
15. 🚨 Emergency Withdraw (Owner)
16. 📈 View All Account Balances
0.  ❌ Exit
```

## 📊 Expected Test Results

### Unit Tests
```
✔ Should deploy with correct initial values
✔ Should set the correct owner
✔ Should initialize account with sufficient deposit
✔ Should reject initialization with insufficient deposit
... (20 total tests)

20 passing (398ms)
```

### Integration Tests
```
📊 TEST 1: Initial Contract State ✅
🏗️  TEST 2: Account Initialization ✅
💳 TEST 3: Flow Deposit Management ✅
⚖️  TEST 4: Balance Management ✅
🔐 TEST 5: Transaction Validation ✅
🛠️  TEST 6: Utility Functions ✅
👤 TEST 7: Account Management ✅
📱 TEST 8: Offline Transaction Creation ✅
📊 TEST 9: Final Account States ✅
🚨 TEST 10: Emergency Functions ✅
```

### Batch Processing
```
🏗️  Step 1: Setting up test accounts ✅
📱 Step 2: Creating offline transactions ✅
📊 Step 3: Balances before batch processing ✅
🔄 Step 4: Processing transaction batch ✅
📊 Step 5: Balances after batch processing ✅
💳 Step 6: Deposit balances after processing ✅
🔢 Step 7: Account nonces after processing ✅
🔄 Step 8: Testing replay protection ✅
📈 Step 9: Final contract statistics ✅
```

## 🔧 Troubleshooting

### Common Issues

**"Insufficient FLOW deposit"**
- Solution: Ensure you have at least 10 FLOW for account initialization

**"Account not initialized"**
- Solution: Run account initialization first before other operations

**"Network request failed"**
- Solution: Check your internet connection and FlowEVM RPC endpoint

**"Transaction reverted"**
- Solution: Check account balances and deposit amounts

**"Signature validation failed"**
- Solution: Ensure proper message signing format

### Getting Help

1. **Check Contract State**: Run `npm run test:interactive` → Option 1
2. **View Account Details**: Run `npm run test:interactive` → Option 5
3. **Check Logs**: Look for detailed error messages in test output
4. **Verify Contract**: Visit FlowScan explorer link above

## 📈 Performance Benchmarks

Expected performance metrics:

- **Account Initialization**: ~2-3 seconds per account
- **Batch Processing (10 txs)**: ~5-8 seconds
- **View Functions**: <100ms each
- **Gas per Transaction**: ~50,000-80,000 gas
- **Optimal Batch Size**: 10-25 transactions

## 🎉 Success Indicators

Your contract is working correctly if:

✅ All unit tests pass (20/20)  
✅ Integration tests complete without errors  
✅ Batch transactions process successfully  
✅ Account balances update correctly  
✅ Nonces increment properly  
✅ Replay protection works  
✅ Signatures validate correctly  
✅ Gas usage is reasonable  

## 🔗 Next Steps

After successful testing:

1. **Frontend Integration**: Use contract address in your app
2. **Mobile App Testing**: Test with real Bluetooth transactions
3. **Mainnet Deployment**: When ready for production
4. **Monitoring**: Set up transaction monitoring
5. **Documentation**: Update your app documentation

## 📞 Support

- **Contract Explorer**: https://evm-testnet.flowscan.io/address/0x5047983EC64EF766B6a524FA2b6E1C3f766B84D6
- **FlowEVM Docs**: https://developers.flow.com/evm/about
- **Test Files**: Check `test/` and `scripts/` directories for examples
