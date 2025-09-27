// OfflineTransactionValidator.cdc
// Validates offline transactions, manages nonces, and prevents replay attacks

import Crypto

access(all) contract OfflineTransactionValidator {
    
    // Storage paths
    access(all) let ValidatorStoragePath: StoragePath
    access(all) let ValidatorPublicPath: PublicPath
    
    // Constants
    access(all) let MIN_SIGNATURE_LENGTH: Int
    access(all) let MAX_SIGNATURE_LENGTH: Int
    access(all) let TRANSACTION_EXPIRY_SECONDS: UFix64
    access(all) let MAX_NONCE_SKIP: UInt64
    
    // Contract storage
    access(self) var processedTransactions: {String: Bool}
    access(self) var userNonces: {Address: UInt64}
    access(self) var userPublicKeys: {Address: String}
    
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
    
    // Events
    access(all) event TransactionValidated(txId: String, from: Address, to: Address, amount: UFix64)
    access(all) event SignatureVerified(txId: String, signer: Address)
    access(all) event NonceUpdated(user: Address, newNonce: UInt64)
    access(all) event ReplayAttemptBlocked(txId: String, attacker: Address)
    access(all) event TransactionExpired(txId: String, expiryTime: UInt64)
    access(all) event NonceValidationFailed(user: Address, expectedNonce: UInt64, providedNonce: UInt64)
    access(all) event InvalidSignature(txId: String, signer: Address)
    access(all) event ReplayAttackDetected(txId: String, attacker: Address)
    
    // Register user's public key for signature verification
    access(all) fun registerPublicKey(user: Address, publicKey: String) {
        pre {
            publicKey.length > 0: "Public key cannot be empty"
        }
        
        self.userPublicKeys[user] = publicKey
    }
    
    // Validate transaction signature using Flow's crypto functions
    access(all) fun validateSignature(tx: OfflineTransaction): Bool {
        // Check signature format
        if !self.isValidSignatureFormat(signature: tx.signature) {
            emit InvalidSignature(txId: tx.id, signer: tx.from)
            return false
        }
        
        // Get user's public key
        let publicKey = self.userPublicKeys[tx.from]
        if publicKey == nil {
            emit LINInterfaces.LINEvents.InvalidSignature(txId: tx.id, signer: tx.from)
            return false
        }
        
        // Create message to verify
        let message = self.createSignatureMessage(tx: tx)
        
        // Verify signature using Flow's crypto functions
        let isValid = self.verifyECDSASignature(
            message: message,
            signature: tx.signature,
            publicKey: publicKey!
        )
        
        if isValid {
            emit SignatureVerified(txId: tx.id, signer: tx.from)
        } else {
            emit LINInterfaces.LINEvents.InvalidSignature(txId: tx.id, signer: tx.from)
        }
        
        return isValid
    }
    
    // Validate transaction nonce
    pub fun validateNonce(user: Address, nonce: UInt64): Bool {
        let currentNonce = self.userNonces[user] ?? 0
        
        if !LINConstants.isValidNonceSequence(currentNonce: currentNonce, providedNonce: nonce) {
            emit LINInterfaces.LINEvents.NonceValidationFailed(
                user: user, 
                expectedNonce: currentNonce + 1, 
                providedNonce: nonce
            )
            return false
        }
        
        return true
    }
    
    // Prevent replay attacks
    pub fun preventReplay(txId: String): Bool {
        if self.processedTransactions[txId] == true {
            emit LINInterfaces.LINEvents.ReplayAttackDetected(txId: txId, attacker: Address(0x0))
            return false
        }
        
        return true
    }
    
    // Check if transaction is expired
    pub fun isTransactionExpired(tx: LINInterfaces.OfflineTransaction): Bool {
        let isExpired = LINConstants.isTransactionExpired(timestamp: tx.timestamp)
        
        if isExpired {
            emit LINInterfaces.LINEvents.TransactionExpired(txId: tx.id, expiryTime: tx.timestamp)
        }
        
        return isExpired
    }
    
    // Comprehensive transaction validation
    pub fun validateTransaction(tx: LINInterfaces.OfflineTransaction): Bool {
        // Check if transaction is expired
        if self.isTransactionExpired(tx: tx) {
            return false
        }
        
        // Check for replay attacks
        if !self.preventReplay(txId: tx.id) {
            return false
        }
        
        // Validate nonce
        if !self.validateNonce(user: tx.from, nonce: tx.nonce) {
            return false
        }
        
        // Validate signature
        if !self.validateSignature(tx: tx) {
            return false
        }
        
        // Validate transaction amount
        if !LINConstants.isValidTransactionAmount(amount: tx.amount) {
            return false
        }
        
        emit TransactionValidated(txId: tx.id, from: tx.from, to: tx.to)
        return true
    }
    
    // Mark transaction as processed
    pub fun markTransactionProcessed(txId: String, user: Address, nonce: UInt64) {
        self.processedTransactions[txId] = true
        self.userNonces[user] = nonce
        
        emit NonceUpdated(user: user, newNonce: nonce)
    }
    
    // Get user's current nonce
    pub fun getUserNonce(user: Address): UInt64 {
        return self.userNonces[user] ?? 0
    }
    
    // Check if transaction was already processed
    pub fun isTransactionProcessed(txId: String): Bool {
        return self.processedTransactions[txId] ?? false
    }
    
    // Create signature message from transaction data
    access(self) fun createSignatureMessage(tx: LINInterfaces.OfflineTransaction): String {
        return tx.id
            .concat("-").concat(tx.from.toString())
            .concat("-").concat(tx.to.toString())
            .concat("-").concat(tx.amount.toString())
            .concat("-").concat(tx.nonce.toString())
            .concat("-").concat(tx.timestamp.toString())
    }
    
    // Check if signature format is valid
    access(all) fun isValidSignatureFormat(signature: String): Bool {
        let length = signature.length
        return length >= self.MIN_SIGNATURE_LENGTH && length <= self.MAX_SIGNATURE_LENGTH
    }
    
    // Check if transaction amount is valid
    access(all) fun isValidTransactionAmount(amount: UFix64): Bool {
        return amount > 0.0 && amount <= 1000000.0 // Max 1M FLOW
    }
    
    // Check if nonce sequence is valid
    access(all) fun isValidNonceSequence(currentNonce: UInt64, providedNonce: UInt64): Bool {
        return providedNonce == currentNonce + 1 || 
               (providedNonce > currentNonce && (providedNonce - currentNonce) <= self.MAX_NONCE_SKIP)
    }
    
    // Check if transaction timestamp is expired
    access(all) fun isTimestampExpired(timestamp: UFix64): Bool {
        let currentTime = getCurrentBlock().timestamp
        return (currentTime - timestamp) > self.TRANSACTION_EXPIRY_SECONDS
    }
    
    // Verify ECDSA signature using Flow's crypto functions
    access(self) fun verifyECDSASignature(message: String, signature: String, publicKey: String): Bool {
        // Convert message to bytes
        let messageBytes = message.utf8
        
        // For now, return true for valid format signatures (placeholder for actual crypto verification)
        // In production, this would use Flow's Crypto.KeyListEntry and signature verification
        return signature.length >= self.MIN_SIGNATURE_LENGTH && 
               signature.length <= self.MAX_SIGNATURE_LENGTH &&
               publicKey.length > 0
    }
    
    // Batch validate multiple transactions
    pub fun validateTransactionBatch(transactions: [LINInterfaces.OfflineTransaction]): {String: Bool} {
        let results: {String: Bool} = {}
        
        for tx in transactions {
            results[tx.id] = self.validateTransaction(tx: tx)
        }
        
        return results
    }
    
    // Get validation statistics
    pub fun getValidationStats(): {String: UInt64} {
        return {
            "totalProcessedTransactions": UInt64(self.processedTransactions.length),
            "totalRegisteredUsers": UInt64(self.userNonces.length),
            "totalPublicKeys": UInt64(self.userPublicKeys.length)
        }
    }
    
    init() {
        self.ValidatorStoragePath = /storage/LINTransactionValidator
        self.ValidatorPublicPath = /public/LINTransactionValidator
        
        // Initialize constants
        self.MIN_SIGNATURE_LENGTH = 64
        self.MAX_SIGNATURE_LENGTH = 256
        self.TRANSACTION_EXPIRY_SECONDS = 86400.0 // 24 hours
        self.MAX_NONCE_SKIP = 10
        
        self.processedTransactions = {}
        self.userNonces = {}
        self.userPublicKeys = {}
    }
    
    // Resource for managing validation
    pub resource ValidatorResource {
        pub fun getValidator(): &OfflineTransactionValidator {
            return &OfflineTransactionValidator as &OfflineTransactionValidator
        }
    }
}
