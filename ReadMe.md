# LIN Protocol - Smart Contracts

**LIN (Ledger Integrated Notes) Protocol v2.0**  
**Platform:** Flow Blockchain  
**Framework:** Cadence Smart Contracts  
**Status:** ✅ **DEPLOYED ON FLOW TESTNET**

## 🚀 Deployment Information

**Contract Address:** `0x5495134c932c7e8a`  
**Network:** Flow Testnet  
**Deployment Date:** January 27, 2025  
**Status:** Active and Verified ✅

## Overview

LIN Protocol enables offline cryptocurrency transactions through Bluetooth peer-to-peer communication, with automatic blockchain synchronization when users come online. The system maintains transaction integrity through cryptographic signatures and manages gas costs via FLOW token deposits.

## Project Structure

```
├── contracts/                 # Cadence smart contracts
│   ├── LINProtocol.cdc       # Main protocol contract
│   ├── OfflineTransactionValidator.cdc  # Transaction validation
│   └── FlowDepositManager.cdc # FLOW deposit management
├── scripts/                   # Read-only blockchain queries
├── transactions/              # Blockchain state-changing operations
├── tests/                     # Contract unit tests
├── flow.json                  # Flow project configuration
└── SmartContract.md          # Detailed technical specifications
```

## Core Features

- **Offline Transactions**: Create and transfer transactions via Bluetooth
- **Batch Synchronization**: Efficient blockchain sync when online
- **FLOW Deposit Management**: Pre-funded gas for seamless processing
- **Cryptographic Security**: Signature-based transaction validation
- **Replay Protection**: Nonce-based security mechanisms

## 🔧 Backend Integration Guide

### Contract Information
- **Contract Name:** `LINProtocolComplete`
- **Contract Address:** `0x5495134c932c7e8a`
- **Network:** Flow Testnet
- **FlowToken Address:** `0x7e60df042a9c0868`

### Required Dependencies
```javascript
// Flow SDK for JavaScript/Node.js
npm install @onflow/fcl @onflow/types

// Flow configuration
import * as fcl from "@onflow/fcl"

fcl.config({
  "accessNode.api": "https://rest-testnet.onflow.org", // Flow Testnet
  "discovery.wallet": "https://fcl-discovery.onflow.org/testnet/authn"
})
```

### 📋 Contract Functions Reference

#### 1. User Account Management

**Initialize User Account** (Transaction)
- Function: `initializeAccount(user: Address, flowDeposit: @FlowToken.Vault)`
- Parameters:
  - `user`: User's wallet address
  - `flowDeposit`: FLOW tokens for fees (minimum 10.0 FLOW)
- Returns: `@UserAccount` resource

**Register Public Key** (Transaction)
- Function: `registerPublicKey(user: Address, publicKey: String)`
- Parameters:
  - `user`: User's wallet address
  - `publicKey`: User's public key for signature verification (64-256 chars)

**Deposit FLOW Tokens** (Transaction)
- Function: `depositFlow(user: Address, vault: @FlowToken.Vault)`
- Parameters:
  - `user`: User's wallet address
  - `vault`: FLOW tokens to deposit

**Withdraw FLOW Tokens** (Transaction)
- Function: `withdrawFlow(user: Address, amount: UFix64)`
- Parameters:
  - `user`: User's wallet address
  - `amount`: Amount to withdraw
- Returns: `@FlowToken.Vault`

#### 2. Offline Transaction Processing

**Sync Offline Transaction Batch** (Transaction)
- Function: `syncOfflineTransactions(batch: TransactionBatch)`
- Parameters:
  - `batch`: TransactionBatch struct containing:
    - `batchId`: Unique batch identifier
    - `submitter`: Address submitting the batch
    - `transactions`: Array of OfflineTransaction structs
- Returns: `Bool` (success/failure)

**OfflineTransaction Structure**
```javascript
{
  id: "unique-tx-id",           // String
  from: "0x...",                // Address
  to: "0x...",                  // Address  
  amount: "10.50000000",        // UFix64 (8 decimals)
  timestamp: 1640995200,        // UFix64 (Unix timestamp)
  nonce: 1,                     // UInt64
  signature: "crypto-sig...",   // String (64-256 chars)
  status: 0                     // TransactionStatus enum
}
```

#### 3. Query Functions (Scripts)

**Get User Balance**
- Function: `getBalance(user: Address)`
- Parameters: `user` - User's wallet address
- Returns: `UFix64` - Current balance

**Get User Deposit Balance**
- Function: `getDepositBalance(user: Address)`
- Parameters: `user` - User's wallet address
- Returns: `UFix64` - Available FLOW deposit

**Get User Nonce**
- Function: `getUserNonce(user: Address)`
- Parameters: `user` - User's wallet address
- Returns: `UInt64` - Current transaction nonce

**Check User Status**
- Function: `isUserActive(user: Address)`
- Parameters: `user` - User's wallet address
- Returns: `Bool` - Account active status

**Get Protocol Statistics**
- Functions:
  - `getTotalUsers()` → `UInt64`
  - `getTotalTransactions()` → `UInt64`
  - `getTotalFlowDeposited()` → `UFix64`

#### 4. Utility Functions

**Calculate Transaction Fee**
- Function: `calculateTransactionFee(amount: UFix64, isComplexTransaction: Bool)`
- Returns: `UFix64` - Calculated fee

**Calculate Batch Fee**
- Function: `calculateBatchFee(transactionCount: Int)`
- Returns: `UFix64` - Total batch processing fee

**Validate Transaction Amount**
- Function: `isValidTransactionAmount(amount: UFix64)`
- Returns: `Bool` - Amount validity

**Generate Transaction ID**
- Function: `generateTransactionId(from: Address, to: Address, nonce: UInt64, timestamp: UFix64)`
- Returns: `String` - Unique transaction ID

## 📋 Technical Specifications

- **Minimum FLOW Deposit**: 10.0 FLOW per user
- **Max Batch Size**: 100 transactions  
- **Transaction Validity**: 24 hours
- **Base Transaction Fee**: 0.001 FLOW
- **Max Transaction Amount**: 1,000,000 FLOW
- **Signature Length**: 64-256 characters
- **Max Nonce Skip**: 10 transactions
- **Precision**: UFix64 (8 decimal places)

## 🔧 JavaScript Integration Example

```javascript
import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types"

// Configure Flow
fcl.config({
  "accessNode.api": "https://rest-testnet.onflow.org",
  "discovery.wallet": "https://fcl-discovery.onflow.org/testnet/authn"
})

// Initialize user account
const initializeAccount = async (depositAmount) => {
  const txId = await fcl.mutate({
    cadence: `
      import LINProtocolComplete from 0x5495134c932c7e8a
      import FlowToken from 0x7e60df042a9c0868
      
      transaction(depositAmount: UFix64) {
        prepare(signer: AuthAccount) {
          let vaultRef = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!
          let depositVault <- vaultRef.withdraw(amount: depositAmount)
          
          let userAccount <- LINProtocolComplete.initializeAccount(
            user: signer.address,
            flowDeposit: <-depositVault
          )
          
          signer.save(<-userAccount, to: /storage/LINUserAccount)
          signer.link<&LINProtocolComplete.UserAccount>(
            /public/LINUserAccount,
            target: /storage/LINUserAccount
          )
        }
      }
    `,
    args: (arg, t) => [arg(depositAmount, t.UFix64)],
    proposer: fcl.authz,
    payer: fcl.authz,
    authorizations: [fcl.authz],
    limit: 1000
  })
  
  return txId
}

// Get user balance
const getUserBalance = async (userAddress) => {
  const balance = await fcl.query({
    cadence: `
      import LINProtocolComplete from 0x5495134c932c7e8a
      
      access(all) fun main(userAddress: Address): UFix64 {
        return LINProtocolComplete.getBalance(user: userAddress)
      }
    `,
    args: (arg, t) => [arg(userAddress, t.Address)]
  })
  
  return balance
}

// Submit offline transaction batch
const submitBatch = async (batchId, transactions) => {
  const txId = await fcl.mutate({
    cadence: `
      import LINProtocolComplete from 0x5495134c932c7e8a
      
      transaction(batchId: String, transactions: [LINProtocolComplete.OfflineTransaction]) {
        prepare(signer: AuthAccount) {
          let batch = LINProtocolComplete.TransactionBatch(
            batchId: batchId,
            submitter: signer.address,
            transactions: transactions
          )
          
          let success = LINProtocolComplete.syncOfflineTransactions(batch: batch)
          
          if !success {
            panic("Batch processing failed")
          }
        }
      }
    `,
    args: (arg, t) => [
      arg(batchId, t.String),
      arg(transactions, t.Array(t.Struct("LINProtocolComplete.OfflineTransaction")))
    ],
    proposer: fcl.authz,
    payer: fcl.authz,
    authorizations: [fcl.authz],
    limit: 1000
  })
  
  return txId
}
```

## 🚀 Deployment Status

- ✅ **Smart Contract Architecture**: Complete
- ✅ **Core Data Structures**: Implemented
- ✅ **User Account Management**: Deployed
- ✅ **Offline Transaction Processing**: Deployed
- ✅ **Security & Validation**: Deployed
- ✅ **Fee Management**: Deployed
- ✅ **Flow Testnet Deployment**: Live at `0x5495134c932c7e8a`
- ✅ **Contract Verification**: Passed all tests

## Contributing

See `SmartContract.md` for detailed technical requirements and implementation guidelines.

## License

MIT License - see LICENSE file for details.
