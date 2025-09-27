// LINInterfaces.cdc
// Core interfaces and data structures for LIN Protocol

import FlowToken from 0x7e60df042a9c0868

// Transaction status enumeration
access(all) enum TransactionStatus: UInt8 {
    access(all) case Pending
    access(all) case Executed
    access(all) case Failed
    access(all) case Expired
}

// Core offline transaction structure
access(all) struct OfflineTransaction {
    access(all) let id: String              // Unique transaction identifier
    access(all) let from: Address           // Sender address
    access(all) let to: Address             // Recipient address
    access(all) let amount: UFix64          // Transaction amount in FLOW
    access(all) let timestamp: UFix64       // Creation timestamp
    access(all) let nonce: UInt64           // User's transaction nonce
    access(all) let signature: String       // Cryptographic signature
    access(all) var status: TransactionStatus // Current status
    
    init(id: String, from: Address, to: Address, amount: UFix64, 
         timestamp: UFix64, nonce: UInt64, signature: String) {
        self.id = id
        self.from = from
        self.to = to
        self.amount = amount
        self.timestamp = timestamp
        self.nonce = nonce
        self.signature = signature
        self.status = TransactionStatus.Pending
    }
    
    // Update transaction status
    access(all) fun updateStatus(_ newStatus: TransactionStatus) {
        self.status = newStatus
    }
}

// User account resource for managing balances and deposits
access(all) resource UserAccount {
    access(all) var balance: UFix64          // Current FLOW balance
    access(all) var flowDeposit: UFix64      // Available FLOW deposit for fees
    access(all) var nonce: UInt64            // Current nonce
    access(all) var lastSyncTime: UFix64     // Last blockchain sync timestamp
    access(all) var isActive: Bool           // Account status
    
    init(balance: UFix64, flowDeposit: UFix64) {
        self.balance = balance
        self.flowDeposit = flowDeposit
        self.nonce = 0
        self.lastSyncTime = getCurrentBlock().timestamp
        self.isActive = true
    }
    
    // Getter functions
    access(all) fun getBalance(): UFix64 {
        return self.balance
    }
    
    access(all) fun getFlowDeposit(): UFix64 {
        return self.flowDeposit
    }
    
    access(all) fun getNonce(): UInt64 {
        return self.nonce
    }
    
    access(all) fun getLastSyncTime(): UFix64 {
        return self.lastSyncTime
    }
    
    access(all) fun getIsActive(): Bool {
        return self.isActive
    }
    
    // Increment nonce for new transactions
    access(all) fun incrementNonce(): UInt64 {
        self.nonce = self.nonce + 1
        return self.nonce
    }
    
    // Update functions
    access(all) fun updateBalance(newBalance: UFix64) {
        self.balance = newBalance
    }
    
    access(all) fun updateFlowDeposit(newDeposit: UFix64) {
        self.flowDeposit = newDeposit
    }
    
    // Update last sync time
    access(all) fun updateSyncTime() {
        self.lastSyncTime = getCurrentBlock().timestamp
    }
    
    // Deactivate account
    access(all) fun deactivate() {
        self.isActive = false
    }
    
    // Activate account
    access(all) fun activate() {
        self.isActive = true
    }
}

// Transaction batch structure for bulk processing
access(all) struct TransactionBatch {
    access(all) let batchId: String          // Unique batch identifier
    access(all) let submitter: Address       // User submitting the batch
    access(all) let transactions: [OfflineTransaction] // Array of transactions
    access(all) let timestamp: UFix64        // Batch submission time
    access(all) let flowUsed: UFix64         // Total FLOW consumed for fees
    
    init(batchId: String, submitter: Address, transactions: [OfflineTransaction]) {
        self.batchId = batchId
        self.submitter = submitter
        self.transactions = transactions
        self.timestamp = getCurrentBlock().timestamp
        self.flowUsed = 0.001 * UFix64(transactions.length) // Estimate: 0.001 FLOW per transaction
    }
}

// Interface for deposit management
access(all) resource interface IDepositManager {
    access(all) fun depositFlow(user: Address, vault: @FlowToken.Vault)
    access(all) fun withdrawFlow(user: Address, amount: UFix64): @FlowToken.Vault
    access(all) fun getDepositBalance(user: Address): UFix64
    access(all) fun deductFees(user: Address, amount: UFix64): Bool
}

// Interface for transaction validation
access(all) resource interface ITransactionValidator {
    access(all) fun validateSignature(tx: OfflineTransaction): Bool
    access(all) fun validateNonce(user: Address, nonce: UInt64): Bool
    access(all) fun preventReplay(txId: String): Bool
    access(all) fun isTransactionExpired(tx: OfflineTransaction): Bool
}

// Interface for the main protocol
access(all) resource interface ILINProtocol {
    access(all) fun initializeAccount(user: Address, flowDeposit: @FlowToken.Vault): @UserAccount
    access(all) fun syncOfflineTransactions(batch: TransactionBatch): Bool
    access(all) fun getUserAccount(user: Address): &UserAccount?
    access(all) fun getBalance(user: Address): UFix64
}

// Core events for the LIN Protocol
access(all) contract LINEvents {
    
    // Account events
    access(all) event AccountInitialized(user: Address, flowDeposit: UFix64)
    access(all) event AccountDeactivated(user: Address)
    access(all) event AccountReactivated(user: Address)
    
    // Transaction events
    access(all) event OfflineBatchProcessed(batchId: String, transactionCount: Int, submitter: Address)
    access(all) event TransactionExecuted(txId: String, from: Address, to: Address, amount: UFix64)
    access(all) event TransactionFailed(txId: String, from: Address, reason: String)
    
    // Deposit events
    access(all) event FlowDepositUpdated(user: Address, newDeposit: UFix64)
    access(all) event BalanceUpdated(user: Address, newBalance: UFix64)
    access(all) event FlowWithdrawn(user: Address, amount: UFix64)
    
    // Security events
    access(all) event InvalidSignature(txId: String, signer: Address)
    access(all) event ReplayAttackDetected(txId: String, attacker: Address)
    access(all) event NonceValidationFailed(user: Address, expectedNonce: UInt64, providedNonce: UInt64)
    
    // Error events
    access(all) event InsufficientFlowDeposit(user: Address, required: UFix64, available: UFix64)
    access(all) event BatchProcessingFailed(batchId: String, submitter: Address, reason: String)
    access(all) event TransactionExpired(txId: String, expiryTime: UFix64)
    
    init() {}
}
