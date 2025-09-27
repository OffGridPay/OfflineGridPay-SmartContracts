# PYUSD Integration Guide for OffGridPay

## Overview
Your OffGridPay contract now supports both **FLOW tokens** and **PYUSD tokens** on FlowEVM! This guide explains how to use the new multi-token functionality.

## Token Addresses
- **FLOW**: Native token (ETH/FLOW on FlowEVM)
- **PYUSD**: `0x2aaBea2058b5aC2D339b163C6Ab6f2b6d53aabED` (FlowEVM)

## Setup Instructions

### 1. Set PYUSD Token Address (One-time setup)
```bash
npx hardhat run scripts/set-pyusd-token.js --network flowTestnet
```

### 2. Account Initialization Options

#### Initialize with FLOW only (existing functionality)
```javascript
// Minimum: 10 FLOW
await contract.initializeAccount({ value: ethers.parseEther("10") });
```

#### Initialize with PYUSD only (new)
```javascript
// First approve PYUSD spending (minimum: 10 PYUSD = 10,000,000 units)
const pyusdContract = new ethers.Contract(PYUSD_ADDRESS, ERC20_ABI, signer);
await pyusdContract.approve(CONTRACT_ADDRESS, 10000000);

// Then initialize account
await contract.initializeAccountWithPyusd(10000000); // 10 PYUSD
```

#### Initialize with both tokens (new)
```javascript
// Approve PYUSD first
await pyusdContract.approve(CONTRACT_ADDRESS, 10000000);

// Initialize with both (10 FLOW + 10 PYUSD)
await contract.initializeAccountWithBoth(10000000, { 
  value: ethers.parseEther("10") 
});
```

## Managing Deposits

### FLOW Deposits
```javascript
// Add FLOW deposit
await contract.addFlowDeposit({ value: ethers.parseEther("5") });

// Withdraw FLOW deposit
await contract.withdrawFlowDeposit(ethers.parseEther("5"));

// Move FLOW from deposit to transaction balance
await contract.depositFlowToBalance(ethers.parseEther("2"));
```

### PYUSD Deposits
```javascript
// Add PYUSD deposit (after approval)
await pyusdContract.approve(CONTRACT_ADDRESS, 5000000);
await contract.addPyusdDeposit(5000000); // 5 PYUSD

// Withdraw PYUSD deposit
await contract.withdrawPyusdDeposit(5000000);

// Move PYUSD from deposit to transaction balance
await contract.depositPyusdToBalance(2000000); // 2 PYUSD
```

## Creating Transactions

### FLOW Transaction
```javascript
const flowTransaction = {
  id: "unique-tx-id",
  from: senderAddress,
  to: recipientAddress,
  amount: ethers.parseEther("1"), // 1 FLOW
  timestamp: Math.floor(Date.now() / 1000),
  nonce: userNonce + 1,
  signature: "0x...", // ECDSA signature
  status: 0, // Pending
  tokenType: 0 // FLOW
};
```

### PYUSD Transaction
```javascript
const pyusdTransaction = {
  id: "unique-tx-id",
  from: senderAddress,
  to: recipientAddress,
  amount: 1000000, // 1 PYUSD (6 decimals)
  timestamp: Math.floor(Date.now() / 1000),
  nonce: userNonce + 1,
  signature: "0x...", // ECDSA signature
  status: 0, // Pending
  tokenType: 1 // PYUSD
};
```

## View Functions

### Check Balances
```javascript
// Transaction balances
const flowBalance = await contract.getFlowBalance(userAddress);
const pyusdBalance = await contract.getPyusdBalance(userAddress);

// Deposit balances
const flowDeposit = await contract.getFlowDepositBalance(userAddress);
const pyusdDeposit = await contract.getPyusdDepositBalance(userAddress);

// Complete account info
const account = await contract.getUserAccount(userAddress);
console.log({
  flowBalance: account.flowBalance,
  pyusdBalance: account.pyusdBalance,
  flowDeposit: account.flowDeposit,
  pyusdDeposit: account.pyusdDeposit,
  isActive: account.isActive
});
```

## Important Constants
```javascript
const MINIMUM_FLOW_DEPOSIT = ethers.parseEther("10"); // 10 FLOW
const MINIMUM_PYUSD_DEPOSIT = 10000000; // 10 PYUSD (6 decimals)
const PYUSD_DECIMALS = 6; // PYUSD uses 6 decimal places
```

## Frontend Integration Tips

### 1. Token Selection UI
```javascript
const TokenType = {
  FLOW: 0,
  PYUSD: 1
};

// Let users choose token type for transactions
const [selectedToken, setSelectedToken] = useState(TokenType.FLOW);
```

### 2. Amount Formatting
```javascript
// Format FLOW amounts (18 decimals)
const formatFlow = (amount) => ethers.formatEther(amount);

// Format PYUSD amounts (6 decimals)
const formatPyusd = (amount) => (amount / 1000000).toFixed(6);
```

### 3. Balance Display
```javascript
const displayBalances = async (userAddress) => {
  const flowBalance = await contract.getFlowBalance(userAddress);
  const pyusdBalance = await contract.getPyusdBalance(userAddress);
  
  return {
    flow: `${formatFlow(flowBalance)} FLOW`,
    pyusd: `${formatPyusd(pyusdBalance)} PYUSD`
  };
};
```

## Security Considerations

1. **Always approve PYUSD transfers** before calling deposit functions
2. **Validate token types** in your frontend before creating transactions
3. **Check sufficient balances** for the selected token type
4. **Handle both token types** in your offline transaction storage
5. **Test with small amounts** before production use

## Error Handling

Common errors and solutions:
- `"PYUSD token not set"` → Run the setup script first
- `"ERC20: insufficient allowance"` → Approve more PYUSD tokens
- `"Insufficient balance"` → Check the correct token balance
- `"Cannot withdraw deposit with pending balance"` → Move balance back to deposit first

## Testing

Run the comprehensive test suite:
```bash
npx hardhat test test/offgridpay-multi-token.test.js
```

This will verify all FLOW and PYUSD functionality is working correctly.

---

🎉 **Your OffGridPay contract now supports both FLOW and PYUSD tokens!** Users can choose their preferred token or use both simultaneously for maximum flexibility.
