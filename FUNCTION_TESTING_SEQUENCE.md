# 🔄 LIN Protocol Function Testing Sequence

**Contract Address**: `0x5047983EC64EF766B6a524FA2b6E1C3f766B84D6`  
**Network**: FlowEVM Testnet  

Follow this sequence to test all contract functionality step by step.

## 📋 Phase 1: Initial Contract State

### 1.1 Check Contract Constants
```solidity
// View the protocol configuration
totalUsers()                    // Should return 0 initially
totalTransactions()             // Should return 0 initially  
totalFlowDeposited()           // Should return 0 initially
MINIMUM_FLOW_DEPOSIT()         // Should return 10 ether
BASE_TRANSACTION_FEE()         // Should return 0.001 ether
MAX_BATCH_SIZE()               // Should return 100
```

**Expected Results:**
- Total users: `0`
- Total transactions: `0`
- Total deposited: `0 FLOW`
- Minimum deposit: `10 FLOW`
- Base fee: `0.001 FLOW`
- Max batch size: `100`

## 📋 Phase 2: Account Management

### 2.1 Initialize User Accounts
```solidity
// Initialize first user account (requires 10+ FLOW)
initializeAccount() payable     // Send 15 FLOW with this call

// Check if account was created successfully
isUserActive(userAddress)       // Should return true
getUserAccount(userAddress)     // Returns full account details
getBalance(userAddress)         // Should return 0 FLOW (balance)
getDepositBalance(userAddress)  // Should return 15 FLOW (deposit)
getUserNonce(userAddress)       // Should return 0
```

### 2.2 Initialize Additional Users
```solidity
// Initialize second user (from different address)
initializeAccount() payable     // Send 15 FLOW

// Initialize third user (from different address)  
initializeAccount() payable     // Send 15 FLOW

// Verify total users increased
totalUsers()                    // Should return 3
totalFlowDeposited()           // Should return 45 FLOW
```

## 📋 Phase 3: Deposit Management

### 3.1 Add Flow Deposits
```solidity
// Add additional deposit to first user
addFlowDeposit() payable        // Send 5 FLOW

// Check updated deposit balance
getDepositBalance(userAddress)  // Should return 20 FLOW
totalFlowDeposited()           // Should return 50 FLOW
```

### 3.2 Test Deposit Withdrawal
```solidity
// Withdraw some deposit
withdrawFlowDeposit(5 ether)    // Withdraw 5 FLOW

// Verify withdrawal
getDepositBalance(userAddress)  // Should return 15 FLOW
totalFlowDeposited()           // Should return 45 FLOW
```

## 📋 Phase 4: Balance Management (Admin Only)

### 4.1 Set User Balances
```solidity
// Give users some balance to transact (owner only)
updateBalance(user1Address, 100 ether)  // Set to 100 FLOW
updateBalance(user2Address, 100 ether)  // Set to 100 FLOW
updateBalance(user3Address, 100 ether)  // Set to 100 FLOW

// Verify balances
getBalance(user1Address)        // Should return 100 FLOW
getBalance(user2Address)        // Should return 100 FLOW
getBalance(user3Address)        // Should return 100 FLOW
```

## 📋 Phase 5: Transaction Validation Functions

### 5.1 Test Nonce Validation
```solidity
// Test valid nonces
validateNonce(userAddress, 1)   // Should return true (next nonce)
validateNonce(userAddress, 0)   // Should return false (current nonce)
validateNonce(userAddress, 12)  // Should return false (too high)

// Check current nonce
getUserNonce(userAddress)       // Should return 0
```

### 5.2 Test Replay Protection
```solidity
// Test if transaction can be processed
preventReplay("test-tx-123")    // Should return true (not processed)
isTransactionProcessed("test-tx-123")  // Should return false
```

### 5.3 Test Transaction Expiry
```solidity
// Test with current timestamp
isTransactionExpired(currentTimestamp)     // Should return false
// Test with old timestamp (1 day + 1 second ago)
isTransactionExpired(currentTimestamp - 86401)  // Should return true
```

## 📋 Phase 6: Utility Functions

### 6.1 Generate Transaction IDs
```solidity
// Generate unique transaction ID
generateTransactionId(
    user1Address,
    user2Address, 
    1,                          // nonce
    currentTimestamp
)
// Should return unique string like "0x123...-0x456...-1-1234567890"
```

## 📋 Phase 7: Account State Management

### 7.1 Test Account Deactivation/Reactivation
```solidity
// Deactivate account
deactivateAccount()             // Call from user1

// Check status
isUserActive(user1Address)      // Should return false

// Reactivate account
reactivateAccount()             // Call from user1

// Check status again
isUserActive(user1Address)      // Should return true
```

## 📋 Phase 8: Offline Transaction Creation & Validation

### 8.1 Create Offline Transaction Structure
```javascript
// Create offline transaction (off-chain)
const offlineTransaction = {
    id: "generated-tx-id",
    from: user1Address,
    to: user2Address,
    amount: ethers.parseEther("10"),    // 10 FLOW
    timestamp: Math.floor(Date.now() / 1000),
    nonce: 1,
    signature: "0x...",                 // ECDSA signature
    status: 0                           // Pending
};
```

### 8.2 Create Proper Signature
```javascript
// Create message hash
const messageHash = ethers.keccak256(ethers.solidityPacked(
    ["string", "address", "address", "uint256", "uint256", "uint256"],
    [tx.id, tx.from, tx.to, tx.amount, tx.timestamp, tx.nonce]
));

// Sign with user's private key
const signature = await user1.signMessage(ethers.getBytes(messageHash));
offlineTransaction.signature = signature;
```

### 8.3 Validate Signature
```solidity
// Test signature validation
validateSignature(offlineTransaction)  // Should return true if properly signed
```

## 📋 Phase 9: Batch Transaction Processing

### 9.1 Create Transaction Batch
```javascript
// Create batch with multiple transactions
const batch = {
    batchId: "batch-" + Date.now(),
    submitter: user1Address,
    transactions: [
        offlineTransaction1,    // user1 -> user2 (10 FLOW)
        offlineTransaction2,    // user2 -> user3 (15 FLOW)  
        offlineTransaction3     // user3 -> user1 (5 FLOW)
    ],
    timestamp: Math.floor(Date.now() / 1000),
    flowUsed: ethers.parseEther("0.003")  // 3 txs * 0.001 fee
};
```

### 9.2 Process Batch
```solidity
// Process the batch (requires sufficient deposit for fees)
syncOfflineTransactions(batch)  // Should return true if successful

// Check updated balances
getBalance(user1Address)        // Should be 95 FLOW (100 - 10 + 5)
getBalance(user2Address)        // Should be 95 FLOW (100 + 10 - 15)
getBalance(user3Address)        // Should be 110 FLOW (100 + 15 - 5)

// Check updated nonces
getUserNonce(user1Address)      // Should be 1
getUserNonce(user2Address)      // Should be 1
getUserNonce(user3Address)      // Should be 1

// Check total transactions
totalTransactions()             // Should be 3
```

### 9.3 Verify Replay Protection
```solidity
// Try to process same transactions again
isTransactionProcessed(tx1.id)  // Should return true
isTransactionProcessed(tx2.id)  // Should return true
isTransactionProcessed(tx3.id)  // Should return true
```

## 📋 Phase 10: Emergency Functions (Owner Only)

### 10.1 Emergency Withdrawal
```solidity
// Check contract balance
// (contract balance from deposits/fees)

// Emergency withdraw (owner only)
emergencyWithdraw()             // Should transfer all ETH to owner
```

## 📋 Phase 11: Final State Verification

### 11.1 Check Final Contract State
```solidity
// Final statistics
totalUsers()                    // Should show total registered users
totalTransactions()             // Should show total processed transactions
totalFlowDeposited()           // Should show remaining deposits

// Check all user accounts
getUserAccount(user1Address)    // Full account details
getUserAccount(user2Address)    // Full account details  
getUserAccount(user3Address)    // Full account details
```

## 🚀 Quick Test Commands

### Run Automated Tests
```bash
# Complete integration test (follows this sequence)
npm run test:contract

# Interactive testing (manual step-by-step)
npm run test:interactive

# Batch transaction focused test
npm run test:batch
```

### Manual Testing with Hardhat Console
```bash
# Start Hardhat console
npx hardhat console --network flowTestnet

# Then run commands interactively:
const contract = await ethers.getContractAt("LINProtocolEVM", "0x5047983EC64EF766B6a524FA2b6E1C3f766B84D6");
await contract.totalUsers();
```

## ✅ Expected Success Flow

1. **Initialize** 3 user accounts → Total users: 3
2. **Set balances** → Each user has 100 FLOW
3. **Create transactions** → 3 signed offline transactions
4. **Process batch** → All transactions execute successfully
5. **Verify balances** → Balances updated correctly
6. **Check nonces** → All nonces incremented
7. **Test replay** → Previous transactions rejected

## 🎯 Key Functions to Test in Order

```
1. totalUsers() → 0
2. initializeAccount() → Create accounts
3. totalUsers() → 3
4. updateBalance() → Set balances
5. generateTransactionId() → Create IDs
6. validateSignature() → Test signatures
7. syncOfflineTransactions() → Process batch
8. getBalance() → Verify updates
9. getUserNonce() → Check nonces
10. isTransactionProcessed() → Verify replay protection
```

This sequence will test every aspect of your LIN Protocol contract! 🎉
