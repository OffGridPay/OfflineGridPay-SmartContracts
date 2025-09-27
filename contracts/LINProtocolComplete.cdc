// LINProtocolComplete.cdc
// Complete LIN Protocol implementation with all functionality in a single contract
// Includes offline transactions, validation, deposit management, and security features

import FlowToken from 0x7e60df042a9c0868
import Crypto

access(all) contract LINProtocolComplete {
    
    // Storage paths
    access(all) let ProtocolStoragePath: StoragePath
    access(all) let ProtocolPublicPath: PublicPath
    access(all) let UserAccountStoragePath: StoragePath
    access(all) let UserAccountPublicPath: PublicPath
    
    // Protocol constants
    access(all) let MINIMUM_FLOW_DEPOSIT: UFix64
    access(all) let AUTO_REFILL_THRESHOLD: UFix64
    access(all) let MAX_BATCH_SIZE: Int
    access(all) let TRANSACTION_VALIDITY_HOURS: UFix64
    access(all) let BASE_TRANSACTION_FEE: UFix64
    access(all) let MAX_TRANSACTION_AMOUNT: UFix64
    access(all) let TRANSACTION_EXPIRY_SECONDS: UFix64
    access(all) let MAX_NONCE_SKIP: UInt64
    access(all) let MAX_SIGNATURE_LENGTH: Int
    access(all) let MIN_SIGNATURE_LENGTH: Int
    
    // Error codes
    access(all) let ERROR_INSUFFICIENT_DEPOSIT: String
    access(all) let ERROR_INVALID_SIGNATURE: String
    access(all) let ERROR_REPLAY_ATTACK: String
    access(all) let ERROR_TRANSACTION_EXPIRED: String
    access(all) let ERROR_INVALID_NONCE: String
    access(all) let ERROR_BATCH_TOO_LARGE: String
    access(all) let ERROR_ACCOUNT_INACTIVE: String
    access(all) let ERROR_INSUFFICIENT_BALANCE: String
    
    // Contract storage
    access(self) var totalUsers: UInt64
    access(self) var totalTransactions: UInt64
    access(self) var totalFlowDeposited: UFix64
    access(self) var processedTransactions: {String: Bool}
    access(self) var userPublicKeys: {Address: String}
    access(self) var flowVault: @FlowToken.Vault
    
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
            self.flowUsed = UFix64(transactions.length) * LINProtocolComplete.BASE_TRANSACTION_FEE
        }
    }
    
    // User account resource
    access(all) resource UserAccount {
        access(all) var balance: UFix64
        access(all) var flowDeposit: UFix64
        access(all) var nonce: UInt64
        access(all) var lastSyncTime: UFix64
        access(all) var isActive: Bool
        
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
        
        access(all) fun incrementNonce(): UInt64 {
            self.nonce = self.nonce + 1
            return self.nonce
        }
        
        access(all) fun updateBalance(newBalance: UFix64) {
            self.balance = newBalance
        }
        
        access(all) fun updateFlowDeposit(newDeposit: UFix64) {
            self.flowDeposit = newDeposit
        }
        
        access(all) fun updateSyncTime() {
            self.lastSyncTime = getCurrentBlock().timestamp
        }
        
        access(all) fun deactivate() {
            self.isActive = false
        }
        
        access(all) fun activate() {
            self.isActive = true
        }
    }
    
    // Events
    access(all) event AccountInitialized(user: Address, flowDeposit: UFix64)
    access(all) event AccountDeactivated(user: Address)
    access(all) event AccountReactivated(user: Address)
    access(all) event OfflineBatchProcessed(batchId: String, transactionCount: Int, submitter: Address)
    access(all) event TransactionExecuted(txId: String, from: Address, to: Address, amount: UFix64)
    access(all) event TransactionFailed(txId: String, from: Address, reason: String)
    access(all) event FlowDepositUpdated(user: Address, newDeposit: UFix64)
    access(all) event BalanceUpdated(user: Address, newBalance: UFix64)
    access(all) event FlowWithdrawn(user: Address, amount: UFix64)
    access(all) event InvalidSignature(txId: String, signer: Address)
    access(all) event ReplayAttackDetected(txId: String, attacker: Address)
    access(all) event NonceValidationFailed(user: Address, expectedNonce: UInt64, providedNonce: UInt64)
    access(all) event InsufficientFlowDeposit(user: Address, required: UFix64, available: UFix64)
    access(all) event BatchProcessingFailed(batchId: String, submitter: Address, reason: String)
    access(all) event TransactionExpired(txId: String, expiryTime: UFix64)
    access(all) event PublicKeyRegistered(user: Address)
    
    // Initialize user account with FLOW deposit
    access(all) fun initializeAccount(user: Address, flowDeposit: @FlowToken.Vault): @UserAccount {
        pre {
            flowDeposit.balance >= self.MINIMUM_FLOW_DEPOSIT: "Insufficient FLOW deposit"
        }
        
        let depositAmount = flowDeposit.balance
        self.flowVault.deposit(from: <-flowDeposit)
        self.totalFlowDeposited = self.totalFlowDeposited + depositAmount
        self.totalUsers = self.totalUsers + 1
        
        emit AccountInitialized(user: user, flowDeposit: depositAmount)
        
        return <-create UserAccount(balance: 0.0, flowDeposit: depositAmount)
    }
    
    // Register user's public key for signature verification
    access(all) fun registerPublicKey(user: Address, publicKey: String) {
        pre {
            publicKey.length > 0: "Public key cannot be empty"
            publicKey.length >= self.MIN_SIGNATURE_LENGTH: "Public key too short"
            publicKey.length <= self.MAX_SIGNATURE_LENGTH: "Public key too long"
        }
        
        self.userPublicKeys[user] = publicKey
        emit PublicKeyRegistered(user: user)
    }
    
    // Validate transaction signature
    access(all) fun validateSignature(tx: OfflineTransaction): Bool {
        // Check signature format
        if !self.isValidSignatureFormat(signature: tx.signature) {
            emit InvalidSignature(txId: tx.id, signer: tx.from)
            return false
        }
        
        // Get user's public key
        let publicKey = self.userPublicKeys[tx.from]
        if publicKey == nil {
            emit InvalidSignature(txId: tx.id, signer: tx.from)
            return false
        }
        
        // Create message to verify
        let message = self.createSignatureMessage(tx: tx)
        let messageBytes = message.utf8
        let signatureBytes = tx.signature.decodeHex()
        let publicKeyBytes = publicKey!.decodeHex()
        
        // Verify signature using Flow's crypto functions
        let keyList = Crypto.KeyList()
        let publicKeyObject = PublicKey(
            publicKey: publicKeyBytes,
            signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
        )
        keyList.add(publicKeyObject, hashAlgorithm: HashAlgorithm.SHA3_256, weight: 1.0)
        
        let isValid = keyList.verify(
            signatureSet: [Crypto.KeyListSignature(keyIndex: 0, signature: signatureBytes)],
            signedData: messageBytes,
            domainSeparationTag: "FLOW-V0.0-transaction"
        )
        
        if !isValid {
            emit InvalidSignature(txId: tx.id, signer: tx.from)
        }
        
        return isValid
    }
    
    // Prevent replay attacks
    access(all) fun preventReplay(txId: String): Bool {
        if self.processedTransactions[txId] == true {
            emit ReplayAttackDetected(txId: txId, attacker: 0x0000000000000000)
            return false
        }
        
        self.processedTransactions[txId] = true
        return true
    }
    
    // Check if transaction has expired
    access(all) fun isTransactionExpired(tx: OfflineTransaction): Bool {
        let currentTime = getCurrentBlock().timestamp
        let isExpired = (currentTime - tx.timestamp) > self.TRANSACTION_EXPIRY_SECONDS
        
        if isExpired {
            emit TransactionExpired(txId: tx.id, expiryTime: tx.timestamp + self.TRANSACTION_EXPIRY_SECONDS)
        }
        
        return isExpired
    }
    
    // Validate nonce sequence
    access(all) fun validateNonce(userAccount: &UserAccount, providedNonce: UInt64): Bool {
        let currentNonce = userAccount.getNonce()
        let isValid = providedNonce == currentNonce + 1 || 
                     (providedNonce > currentNonce && (providedNonce - currentNonce) <= self.MAX_NONCE_SKIP)
        
        if !isValid {
            emit NonceValidationFailed(
                user: userAccount.owner!.address, 
                expectedNonce: currentNonce + 1, 
                providedNonce: providedNonce
            )
        }
        
        return isValid
    }
    
    // Process offline transaction batch
    access(all) fun syncOfflineTransactions(batch: TransactionBatch): Bool {
        pre {
            batch.transactions.length > 0: "Batch cannot be empty"
            batch.transactions.length <= self.MAX_BATCH_SIZE: "Batch too large"
        }
        
        var successCount = 0
        let totalTransactions = batch.transactions.length
        
        // Get submitter's account reference
        let submitterAccount = getAccount(batch.submitter)
        let userAccountRef = submitterAccount.capabilities.borrow<&UserAccount>(self.UserAccountPublicPath)
        
        if userAccountRef == nil {
            emit BatchProcessingFailed(batchId: batch.batchId, submitter: batch.submitter, reason: "User account not found")
            return false
        }
        
        // Calculate total fees required
        let totalFees = self.calculateBatchFee(transactionCount: totalTransactions)
        
        if userAccountRef!.getFlowDeposit() < totalFees {
            emit InsufficientFlowDeposit(user: batch.submitter, required: totalFees, available: userAccountRef!.getFlowDeposit())
            return false
        }
        
        // Process each transaction
        for tx in batch.transactions {
            if self.processTransaction(tx: tx, userAccount: userAccountRef!) {
                successCount = successCount + 1
            }
        }
        
        // Deduct fees from user's deposit
        let newDeposit = userAccountRef!.getFlowDeposit() - totalFees
        userAccountRef!.updateFlowDeposit(newDeposit: newDeposit)
        userAccountRef!.updateSyncTime()
        
        self.totalTransactions = self.totalTransactions + UInt64(successCount)
        
        emit OfflineBatchProcessed(batchId: batch.batchId, transactionCount: successCount, submitter: batch.submitter)
        
        return successCount == totalTransactions
    }
    
    // Process individual transaction
    access(self) fun processTransaction(tx: OfflineTransaction, userAccount: &UserAccount): Bool {
        // Validate transaction expiry
        if self.isTransactionExpired(tx: tx) {
            emit TransactionFailed(txId: tx.id, from: tx.from, reason: self.ERROR_TRANSACTION_EXPIRED)
            return false
        }
        
        // Prevent replay attacks
        if !self.preventReplay(txId: tx.id) {
            emit TransactionFailed(txId: tx.id, from: tx.from, reason: self.ERROR_REPLAY_ATTACK)
            return false
        }
        
        // Validate signature
        if !self.validateSignature(tx: tx) {
            emit TransactionFailed(txId: tx.id, from: tx.from, reason: self.ERROR_INVALID_SIGNATURE)
            return false
        }
        
        // Validate nonce
        if !self.validateNonce(userAccount: userAccount, providedNonce: tx.nonce) {
            emit TransactionFailed(txId: tx.id, from: tx.from, reason: self.ERROR_INVALID_NONCE)
            return false
        }
        
        // Validate transaction amount
        if !self.isValidTransactionAmount(amount: tx.amount) {
            emit TransactionFailed(txId: tx.id, from: tx.from, reason: "Invalid transaction amount")
            return false
        }
        
        // Check sufficient balance
        if userAccount.getBalance() < tx.amount {
            emit TransactionFailed(txId: tx.id, from: tx.from, reason: self.ERROR_INSUFFICIENT_BALANCE)
            return false
        }
        
        // Execute transaction
        let newBalance = userAccount.getBalance() - tx.amount
        userAccount.updateBalance(newBalance: newBalance)
        userAccount.incrementNonce()
        
        emit TransactionExecuted(txId: tx.id, from: tx.from, to: tx.to, amount: tx.amount)
        emit BalanceUpdated(user: tx.from, newBalance: newBalance)
        
        return true
    }
    
    // Deposit FLOW tokens
    access(all) fun depositFlow(user: Address, vault: @FlowToken.Vault) {
        pre {
            vault.balance > 0.0: "Deposit amount must be positive"
        }
        
        let depositAmount = vault.balance
        self.flowVault.deposit(from: <-vault)
        self.totalFlowDeposited = self.totalFlowDeposited + depositAmount
        
        // Update user's deposit balance
        let userAccount = getAccount(user)
        let userAccountRef = userAccount.capabilities.borrow<&UserAccount>(self.UserAccountPublicPath)
        
        if userAccountRef != nil {
            let newDeposit = userAccountRef!.getFlowDeposit() + depositAmount
            userAccountRef!.updateFlowDeposit(newDeposit: newDeposit)
            emit FlowDepositUpdated(user: user, newDeposit: newDeposit)
        }
    }
    
    // Withdraw FLOW tokens
    access(all) fun withdrawFlow(user: Address, amount: UFix64): @FlowToken.Vault {
        pre {
            amount > 0.0: "Withdrawal amount must be positive"
        }
        
        let userAccount = getAccount(user)
        let userAccountRef = userAccount.capabilities.borrow<&UserAccount>(self.UserAccountPublicPath)
        
        if userAccountRef == nil {
            panic("User account not found")
        }
        
        if userAccountRef!.getFlowDeposit() < amount {
            panic("Insufficient deposit balance")
        }
        
        let newDeposit = userAccountRef!.getFlowDeposit() - amount
        userAccountRef!.updateFlowDeposit(newDeposit: newDeposit)
        
        emit FlowWithdrawn(user: user, amount: amount)
        emit FlowDepositUpdated(user: user, newDeposit: newDeposit)
        
        return <-self.flowVault.withdraw(amount: amount) as! @FlowToken.Vault
    }
    
    // Utility functions
    access(all) fun calculateTransactionFee(amount: UFix64, isComplexTransaction: Bool): UFix64 {
        let baseFee = self.BASE_TRANSACTION_FEE
        let complexityMultiplier = isComplexTransaction ? 2.0 : 1.0
        let amountFactor = amount > 100.0 ? 1.5 : 1.0
        
        return baseFee * complexityMultiplier * amountFactor
    }
    
    access(all) fun calculateBatchFee(transactionCount: Int): UFix64 {
        if transactionCount <= 0 {
            return 0.0
        }
        
        let baseCost = UFix64(transactionCount) * self.BASE_TRANSACTION_FEE
        let batchDiscount = transactionCount > 10 ? 0.9 : 1.0 // 10% discount for batches > 10
        
        return baseCost * batchDiscount
    }
    
    access(all) fun isValidTransactionAmount(amount: UFix64): Bool {
        return amount > 0.0 && amount <= self.MAX_TRANSACTION_AMOUNT
    }
    
    access(all) fun isValidSignatureFormat(signature: String): Bool {
        let length = signature.length
        return length >= self.MIN_SIGNATURE_LENGTH && length <= self.MAX_SIGNATURE_LENGTH
    }
    
    access(all) fun generateTransactionId(from: Address, to: Address, nonce: UInt64, timestamp: UFix64): String {
        let addressString = from.toString().concat("-").concat(to.toString())
        let nonceString = nonce.toString()
        let timestampString = timestamp.toString()
        
        return addressString.concat("-").concat(nonceString).concat("-").concat(timestampString)
    }
    
    access(all) fun getCurrentTimestamp(): UFix64 {
        return getCurrentBlock().timestamp
    }
    
    access(all) fun formatError(errorCode: String, context: String): String {
        return errorCode.concat(": ").concat(context)
    }
    
    access(self) fun createSignatureMessage(tx: OfflineTransaction): String {
        return tx.id.concat("|")
            .concat(tx.from.toString()).concat("|")
            .concat(tx.to.toString()).concat("|")
            .concat(tx.amount.toString()).concat("|")
            .concat(tx.timestamp.toString()).concat("|")
            .concat(tx.nonce.toString())
    }
    
    // Public getters
    access(all) fun getTotalUsers(): UInt64 {
        return self.totalUsers
    }
    
    access(all) fun getTotalTransactions(): UInt64 {
        return self.totalTransactions
    }
    
    access(all) fun getTotalFlowDeposited(): UFix64 {
        return self.totalFlowDeposited
    }
    
    access(all) fun getBalance(user: Address): UFix64 {
        let userAccount = getAccount(user)
        let userAccountRef = userAccount.capabilities.borrow<&UserAccount>(self.UserAccountPublicPath)
        return userAccountRef?.getBalance() ?? 0.0
    }
    
    access(all) fun getDepositBalance(user: Address): UFix64 {
        let userAccount = getAccount(user)
        let userAccountRef = userAccount.capabilities.borrow<&UserAccount>(self.UserAccountPublicPath)
        return userAccountRef?.getFlowDeposit() ?? 0.0
    }
    
    access(all) fun getUserNonce(user: Address): UInt64 {
        let userAccount = getAccount(user)
        let userAccountRef = userAccount.capabilities.borrow<&UserAccount>(self.UserAccountPublicPath)
        return userAccountRef?.getNonce() ?? 0
    }
    
    access(all) fun isUserActive(user: Address): Bool {
        let userAccount = getAccount(user)
        let userAccountRef = userAccount.capabilities.borrow<&UserAccount>(self.UserAccountPublicPath)
        return userAccountRef?.getIsActive() ?? false
    }
    
    init() {
        // Initialize storage paths
        self.ProtocolStoragePath = /storage/LINProtocolComplete
        self.ProtocolPublicPath = /public/LINProtocolComplete
        self.UserAccountStoragePath = /storage/LINUserAccount
        self.UserAccountPublicPath = /public/LINUserAccount
        
        // Initialize constants
        self.MINIMUM_FLOW_DEPOSIT = 10.0
        self.AUTO_REFILL_THRESHOLD = 1.0
        self.MAX_BATCH_SIZE = 100
        self.TRANSACTION_VALIDITY_HOURS = 24.0
        self.BASE_TRANSACTION_FEE = 0.001
        self.MAX_TRANSACTION_AMOUNT = 1000000.0
        self.TRANSACTION_EXPIRY_SECONDS = 86400.0 // 24 hours
        self.MAX_NONCE_SKIP = 10
        self.MAX_SIGNATURE_LENGTH = 256
        self.MIN_SIGNATURE_LENGTH = 64
        
        // Initialize error codes
        self.ERROR_INSUFFICIENT_DEPOSIT = "INSUFFICIENT_DEPOSIT"
        self.ERROR_INVALID_SIGNATURE = "INVALID_SIGNATURE"
        self.ERROR_REPLAY_ATTACK = "REPLAY_ATTACK"
        self.ERROR_TRANSACTION_EXPIRED = "TRANSACTION_EXPIRED"
        self.ERROR_INVALID_NONCE = "INVALID_NONCE"
        self.ERROR_BATCH_TOO_LARGE = "BATCH_TOO_LARGE"
        self.ERROR_ACCOUNT_INACTIVE = "ACCOUNT_INACTIVE"
        self.ERROR_INSUFFICIENT_BALANCE = "INSUFFICIENT_BALANCE"
        
        // Initialize contract state
        self.totalUsers = 0
        self.totalTransactions = 0
        self.totalFlowDeposited = 0.0
        self.processedTransactions = {}
        self.userPublicKeys = {}
        self.flowVault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>()) as! @FlowToken.Vault
    }
}
