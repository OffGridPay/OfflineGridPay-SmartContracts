// LINProtocolSimple.cdc
// Simplified LIN Protocol for Cadence 1.0 deployment

access(all) contract LINProtocolSimple {
    
    // Storage paths
    access(all) let UserAccountStoragePath: StoragePath
    access(all) let UserAccountPublicPath: PublicPath
    
    // Transaction status enumeration
    access(all) enum TransactionStatus: UInt8 {
        access(all) case Pending
        access(all) case Executed
        access(all) case Failed
        access(all) case Expired
    }
    
    // Core offline transaction structure
    access(all) struct OfflineTransaction {
        access(all) let id: String
        access(all) let from: Address
        access(all) let to: Address
        access(all) let amount: UFix64
        access(all) let timestamp: UFix64
        access(all) let nonce: UInt64
        access(all) let signature: String
        access(all) var status: TransactionStatus
        
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
        
        access(all) fun updateStatus(_ newStatus: TransactionStatus) {
            self.status = newStatus
        }
    }
    
    // User account resource
    access(all) resource UserAccount {
        access(self) var balance: UFix64
        access(self) var flowDeposit: UFix64
        access(self) var nonce: UInt64
        access(self) var lastSyncTime: UFix64
        access(self) var isActive: Bool
        
        init(balance: UFix64, flowDeposit: UFix64) {
            self.balance = balance
            self.flowDeposit = flowDeposit
            self.nonce = 0
            self.lastSyncTime = getCurrentBlock().timestamp
            self.isActive = true
        }
        
        access(all) fun getBalance(): UFix64 {
            return self.balance
        }
        
        access(all) fun getDeposit(): UFix64 {
            return self.flowDeposit
        }
        
        access(all) fun getNonce(): UInt64 {
            return self.nonce
        }
        
        access(all) fun setBalance(_ newBalance: UFix64) {
            self.balance = newBalance
        }
        
        access(all) fun incrementNonce(): UInt64 {
            self.nonce = self.nonce + 1
            return self.nonce
        }
        
        access(all) fun updateSyncTime() {
            self.lastSyncTime = getCurrentBlock().timestamp
        }
    }
    
    // Transaction batch structure
    access(all) struct TransactionBatch {
        access(all) let batchId: String
        access(all) let submitter: Address
        access(all) let transactions: [OfflineTransaction]
        access(all) let timestamp: UFix64
        access(all) let flowUsed: UFix64
        
        init(batchId: String, submitter: Address, transactions: [OfflineTransaction]) {
            self.batchId = batchId
            self.submitter = submitter
            self.transactions = transactions
            self.timestamp = getCurrentBlock().timestamp
            self.flowUsed = 0.001 * UFix64(transactions.length)
        }
    }
    
    // Contract storage
    access(self) var userAccounts: @{Address: UserAccount}
    access(self) var userDeposits: {Address: UFix64}
    access(self) var processedTransactions: {String: Bool}
    access(self) var totalUsers: UInt64
    access(self) var totalTransactionsProcessed: UInt64
    
    // Constants
    access(all) let MINIMUM_FLOW_DEPOSIT: UFix64
    access(all) let BASE_TRANSACTION_FEE: UFix64
    access(all) let MAX_BATCH_SIZE: Int
    
    // Events
    access(all) event AccountInitialized(user: Address, flowDeposit: UFix64)
    access(all) event TransactionExecuted(txId: String, from: Address, to: Address, amount: UFix64)
    access(all) event BatchProcessed(batchId: String, transactionCount: Int, submitter: Address)
    access(all) event DepositReceived(user: Address, amount: UFix64, newBalance: UFix64)
    
    // Initialize user account with deposit
    access(all) fun initializeAccount(user: Address, depositAmount: UFix64): @UserAccount {
        pre {
            depositAmount >= self.MINIMUM_FLOW_DEPOSIT: "Deposit must meet minimum requirement"
            self.userAccounts[user] == nil: "User account already exists"
        }
        
        // Store deposit
        self.userDeposits[user] = (self.userDeposits[user] ?? 0.0) + depositAmount
        
        // Create user account to return
        let userAccount <- create UserAccount(balance: 0.0, flowDeposit: depositAmount)
        
        self.totalUsers = self.totalUsers + 1
        
        emit AccountInitialized(user: user, flowDeposit: depositAmount)
        emit DepositReceived(user: user, amount: depositAmount, newBalance: self.userDeposits[user]!)
        
        return <-userAccount
    }
    
    // Get user balance
    access(all) fun getBalance(user: Address): UFix64 {
        let account = &self.userAccounts[user] as &UserAccount?
        return account?.getBalance() ?? 0.0
    }
    
    // Get user deposit balance
    access(all) fun getDepositBalance(user: Address): UFix64 {
        return self.userDeposits[user] ?? 0.0
    }
    
    // Simple transaction validation
    access(all) fun validateTransaction(tx: OfflineTransaction): Bool {
        // Basic validation
        if tx.amount <= 0.0 || tx.signature.length < 10 {
            return false
        }
        
        // Check if already processed
        if self.processedTransactions[tx.id] == true {
            return false
        }
        
        // Check if expired (24 hours)
        let currentTime = getCurrentBlock().timestamp
        if (currentTime - tx.timestamp) > 86400.0 {
            return false
        }
        
        return true
    }
    
    // Process offline transaction batch
    access(all) fun syncOfflineTransactions(batch: TransactionBatch): Bool {
        pre {
            batch.transactions.length <= self.MAX_BATCH_SIZE: "Batch too large"
            batch.transactions.length > 0: "Batch cannot be empty"
        }
        
        var successCount = 0
        var failureCount = 0
        
        for tx in batch.transactions {
            if self.validateTransaction(tx: tx) {
                // Mark as processed
                self.processedTransactions[tx.id] = true
                
                // Update sender balance (simplified)
                if let senderAccount = &self.userAccounts[tx.from] as &UserAccount? {
                    if senderAccount.getBalance() >= tx.amount {
                        senderAccount.setBalance(senderAccount.getBalance() - tx.amount)
                        senderAccount.incrementNonce()
                        senderAccount.updateSyncTime()
                        
                        // Update recipient balance
                        if self.userAccounts[tx.to] == nil {
                            let newAccount <- create UserAccount(balance: tx.amount, flowDeposit: 0.0)
                            let oldAccount <- self.userAccounts[tx.to] <- newAccount
                            destroy oldAccount
                        } else {
                            let recipientAccount = &self.userAccounts[tx.to] as &UserAccount?
                            recipientAccount!.setBalance(recipientAccount!.getBalance() + tx.amount)
                        }
                        
                        emit TransactionExecuted(txId: tx.id, from: tx.from, to: tx.to, amount: tx.amount)
                        successCount = successCount + 1
                    } else {
                        failureCount = failureCount + 1
                    }
                } else {
                    failureCount = failureCount + 1
                }
            } else {
                failureCount = failureCount + 1
            }
        }
        
        self.totalTransactionsProcessed = self.totalTransactionsProcessed + UInt64(successCount)
        
        emit BatchProcessed(batchId: batch.batchId, transactionCount: successCount, submitter: batch.submitter)
        
        return failureCount == 0
    }
    
    // Get protocol statistics
    access(all) fun getProtocolStats(): {String: UInt64} {
        return {
            "totalUsers": self.totalUsers,
            "totalTransactionsProcessed": self.totalTransactionsProcessed,
            "activeAccounts": UInt64(self.userAccounts.length)
        }
    }
    
    init() {
        self.UserAccountStoragePath = /storage/LINUserAccount
        self.UserAccountPublicPath = /public/LINUserAccount
        
        self.userAccounts <- {}
        self.userDeposits = {}
        self.processedTransactions = {}
        self.totalUsers = 0
        self.totalTransactionsProcessed = 0
        
        // Set constants
        self.MINIMUM_FLOW_DEPOSIT = 10.0
        self.BASE_TRANSACTION_FEE = 0.001
        self.MAX_BATCH_SIZE = 100
    }
}
