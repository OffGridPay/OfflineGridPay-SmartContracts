// LINProtocol.cdc
// Main contract orchestrating offline transaction lifecycle and user accounts

import FlowToken from 0x1654653399040a61
import LINInterfaces from "./LINInterfaces.cdc"
import LINConstants from "./LINConstants.cdc"
import FlowDepositManager from "./FlowDepositManager.cdc"
import OfflineTransactionValidator from "./OfflineTransactionValidator.cdc"

pub contract LINProtocol: LINInterfaces.ILINProtocol {
    
    // Storage paths
    pub let ProtocolStoragePath: StoragePath
    pub let ProtocolPublicPath: PublicPath
    pub let UserAccountStoragePath: StoragePath
    pub let UserAccountPublicPath: PublicPath
    
    // Contract storage
    access(self) var userAccounts: @{Address: LINInterfaces.UserAccount}
    access(self) var totalUsers: UInt64
    access(self) var totalTransactionsProcessed: UInt64
    
    // Events
    pub event ProtocolInitialized()
    pub event UserAccountCreated(user: Address, initialDeposit: UFix64)
    pub event BatchSyncStarted(batchId: String, submitter: Address, transactionCount: Int)
    pub event BatchSyncCompleted(batchId: String, submitter: Address, successCount: Int, failureCount: Int)
    
    // Initialize user account with FLOW deposit
    pub fun initializeAccount(user: Address, flowDeposit: @FlowToken.Vault): @LINInterfaces.UserAccount {
        pre {
            flowDeposit.balance >= LINConstants.MINIMUM_FLOW_DEPOSIT: "Initial deposit must meet minimum requirement"
            self.userAccounts[user] == nil: "User account already exists"
        }
        
        let depositAmount = flowDeposit.balance
        
        // Initialize deposit in FlowDepositManager
        let depositManager = self.account.borrow<&FlowDepositManager>(from: FlowDepositManager.DepositStoragePath)
            ?? panic("Could not borrow FlowDepositManager")
        
        depositManager.initializeDeposit(user: user, vault: <-flowDeposit)
        
        // Create user account resource
        let userAccount <- create LINInterfaces.UserAccount(balance: 0.0, flowDeposit: depositAmount)
        
        // Register user's public key (placeholder - in real implementation, this would come from user)
        let validator = self.account.borrow<&OfflineTransactionValidator>(from: OfflineTransactionValidator.ValidatorStoragePath)
            ?? panic("Could not borrow OfflineTransactionValidator")
        
        // Store user account
        let oldAccount <- self.userAccounts[user] <- userAccount
        destroy oldAccount
        
        self.totalUsers = self.totalUsers + 1
        
        emit UserAccountCreated(user: user, initialDeposit: depositAmount)
        emit LINInterfaces.LINEvents.AccountInitialized(user: user, flowDeposit: depositAmount)
        
        // Return reference to the stored account
        return <-create LINInterfaces.UserAccount(balance: 0.0, flowDeposit: depositAmount)
    }
    
    // Sync offline transactions in batch
    pub fun syncOfflineTransactions(batch: LINInterfaces.TransactionBatch): Bool {
        pre {
            batch.transactions.length <= LINConstants.MAX_BATCH_SIZE: "Batch size exceeds maximum limit"
            batch.transactions.length > 0: "Batch cannot be empty"
        }
        
        emit BatchSyncStarted(
            batchId: batch.batchId, 
            submitter: batch.submitter, 
            transactionCount: batch.transactions.length
        )
        
        let validator = self.account.borrow<&OfflineTransactionValidator>(from: OfflineTransactionValidator.ValidatorStoragePath)
            ?? panic("Could not borrow OfflineTransactionValidator")
        
        let depositManager = self.account.borrow<&FlowDepositManager>(from: FlowDepositManager.DepositStoragePath)
            ?? panic("Could not borrow FlowDepositManager")
        
        var successCount = 0
        var failureCount = 0
        
        // Process each transaction in the batch
        for tx in batch.transactions {
            let success = self.processOfflineTransaction(tx: tx, validator: validator, depositManager: depositManager)
            if success {
                successCount = successCount + 1
            } else {
                failureCount = failureCount + 1
            }
        }
        
        self.totalTransactionsProcessed = self.totalTransactionsProcessed + UInt64(successCount)
        
        emit BatchSyncCompleted(
            batchId: batch.batchId, 
            submitter: batch.submitter, 
            successCount: successCount, 
            failureCount: failureCount
        )
        
        emit LINInterfaces.LINEvents.OfflineBatchProcessed(
            batchId: batch.batchId, 
            transactionCount: successCount,
            submitter: batch.submitter
        )
        
        return failureCount == 0
    }
    
    // Process individual offline transaction
    access(self) fun processOfflineTransaction(
        tx: LINInterfaces.OfflineTransaction, 
        validator: &OfflineTransactionValidator, 
        depositManager: &FlowDepositManager
    ): Bool {
        // Validate transaction
        if !validator.validateTransaction(tx: tx) {
            emit LINInterfaces.LINEvents.TransactionFailed(txId: tx.id, from: tx.from, reason: "Validation failed")
            return false
        }
        
        // Check sender account exists
        let senderAccount = &self.userAccounts[tx.from] as &LINInterfaces.UserAccount?
        if senderAccount == nil {
            emit LINInterfaces.LINEvents.TransactionFailed(txId: tx.id, from: tx.from, reason: "Sender account not found")
            return false
        }
        
        // Check sender has sufficient balance
        if senderAccount!.balance < tx.amount {
            emit LINInterfaces.LINEvents.TransactionFailed(txId: tx.id, from: tx.from, reason: "Insufficient balance")
            return false
        }
        
        // Calculate and deduct transaction fee
        let transactionFee = LINConstants.calculateTransactionFee(amount: tx.amount, isComplexTransaction: false)
        if !depositManager.deductFees(user: tx.from, amount: transactionFee) {
            emit LINInterfaces.LINEvents.TransactionFailed(txId: tx.id, from: tx.from, reason: "Insufficient deposit for fees")
            return false
        }
        
        // Execute transaction
        senderAccount!.balance = senderAccount!.balance - tx.amount
        senderAccount!.incrementNonce()
        senderAccount!.updateSyncTime()
        
        // Update recipient balance (create account if doesn't exist)
        if self.userAccounts[tx.to] == nil {
            let newAccount <- create LINInterfaces.UserAccount(balance: tx.amount, flowDeposit: 0.0)
            let oldAccount <- self.userAccounts[tx.to] <- newAccount
            destroy oldAccount
        } else {
            let recipientAccount = &self.userAccounts[tx.to] as &LINInterfaces.UserAccount?
            recipientAccount!.balance = recipientAccount!.balance + tx.amount
        }
        
        // Mark transaction as processed
        validator.markTransactionProcessed(txId: tx.id, user: tx.from, nonce: tx.nonce)
        
        emit LINInterfaces.LINEvents.TransactionExecuted(
            txId: tx.id, 
            from: tx.from, 
            to: tx.to, 
            amount: tx.amount
        )
        
        emit LINInterfaces.LINEvents.BalanceUpdated(user: tx.from, newBalance: senderAccount!.balance)
        emit LINInterfaces.LINEvents.BalanceUpdated(user: tx.to, newBalance: self.userAccounts[tx.to]?.balance ?? 0.0)
        
        return true
    }
    
    // Get user account reference
    pub fun getUserAccount(user: Address): &LINInterfaces.UserAccount? {
        return &self.userAccounts[user] as &LINInterfaces.UserAccount?
    }
    
    // Get user balance
    pub fun getBalance(user: Address): UFix64 {
        let account = &self.userAccounts[user] as &LINInterfaces.UserAccount?
        return account?.balance ?? 0.0
    }
    
    // Deposit FLOW to user balance
    pub fun depositBalance(user: Address, vault: @FlowToken.Vault) {
        let amount = vault.balance
        
        if self.userAccounts[user] == nil {
            // Create new account if doesn't exist
            let newAccount <- create LINInterfaces.UserAccount(balance: amount, flowDeposit: 0.0)
            let oldAccount <- self.userAccounts[user] <- newAccount
            destroy oldAccount
        } else {
            let userAccount = &self.userAccounts[user] as &LINInterfaces.UserAccount?
            userAccount!.balance = userAccount!.balance + amount
        }
        
        // Store the vault (in real implementation, this would be handled differently)
        destroy vault
        
        emit LINInterfaces.LINEvents.BalanceUpdated(user: user, newBalance: self.getBalance(user: user))
    }
    
    // Withdraw FLOW from user balance
    pub fun withdrawBalance(user: Address, amount: UFix64): @FlowToken.Vault {
        pre {
            self.userAccounts[user] != nil: "User account does not exist"
            self.getBalance(user: user) >= amount: "Insufficient balance"
        }
        
        let userAccount = &self.userAccounts[user] as &LINInterfaces.UserAccount?
        userAccount!.balance = userAccount!.balance - amount
        
        emit LINInterfaces.LINEvents.BalanceUpdated(user: user, newBalance: userAccount!.balance)
        
        // In real implementation, this would withdraw from a vault
        return <-FlowToken.createEmptyVault() as! @FlowToken.Vault
    }
    
    // Get protocol statistics
    pub fun getProtocolStats(): {String: UInt64} {
        return {
            "totalUsers": self.totalUsers,
            "totalTransactionsProcessed": self.totalTransactionsProcessed,
            "activeAccounts": UInt64(self.userAccounts.length)
        }
    }
    
    // Deactivate user account
    pub fun deactivateAccount(user: Address) {
        let userAccount = &self.userAccounts[user] as &LINInterfaces.UserAccount?
        if userAccount != nil {
            userAccount!.deactivate()
            emit LINInterfaces.LINEvents.AccountDeactivated(user: user)
        }
    }
    
    // Reactivate user account
    pub fun reactivateAccount(user: Address) {
        let userAccount = &self.userAccounts[user] as &LINInterfaces.UserAccount?
        if userAccount != nil {
            userAccount!.activate()
            emit LINInterfaces.LINEvents.AccountReactivated(user: user)
        }
    }
    
    init() {
        self.ProtocolStoragePath = /storage/LINProtocol
        self.ProtocolPublicPath = /public/LINProtocol
        self.UserAccountStoragePath = /storage/LINUserAccount
        self.UserAccountPublicPath = /public/LINUserAccount
        
        self.userAccounts <- {}
        self.totalUsers = 0
        self.totalTransactionsProcessed = 0
        
        // Save contract capability to account
        self.account.save(<-create ProtocolResource(), to: self.ProtocolStoragePath)
        self.account.link<&{LINInterfaces.ILINProtocol}>(self.ProtocolPublicPath, target: self.ProtocolStoragePath)
        
        emit ProtocolInitialized()
    }
    
    // Resource for managing protocol
    pub resource ProtocolResource {
        pub fun getProtocol(): &LINProtocol {
            return &LINProtocol as &LINProtocol
        }
    }
}
