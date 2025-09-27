// LINConstants.cdc
// Constants and utility functions for LIN Protocol

access(all) contract LINConstants {
    
    // Protocol configuration constants
    access(all) let MINIMUM_FLOW_DEPOSIT: UFix64 = 10.0
    access(all) let AUTO_REFILL_THRESHOLD: UFix64 = 1.0
    access(all) let MAX_BATCH_SIZE: Int = 100
    access(all) let TRANSACTION_VALIDITY_HOURS: UFix64 = 24.0
    access(all) let BASE_TRANSACTION_FEE: UFix64 = 0.001
    access(all) let MAX_TRANSACTION_AMOUNT: UFix64 = 1000000.0
    
    // Time constants (in seconds)
    access(all) let SECONDS_PER_HOUR: UFix64 = 3600.0
    access(all) let TRANSACTION_EXPIRY_SECONDS: UFix64 = 86400.0 // 24 hours
    
    // Protocol limits
    access(all) let MAX_NONCE_SKIP: UInt64 = 10 // Maximum nonce gap allowed
    access(all) let MAX_SIGNATURE_LENGTH: Int = 256
    access(all) let MIN_SIGNATURE_LENGTH: Int = 64
    
    // Error codes
    access(all) let ERROR_INSUFFICIENT_DEPOSIT: String = "INSUFFICIENT_DEPOSIT"
    access(all) let ERROR_INVALID_SIGNATURE: String = "INVALID_SIGNATURE"
    access(all) let ERROR_REPLAY_ATTACK: String = "REPLAY_ATTACK"
    access(all) let ERROR_TRANSACTION_EXPIRED: String = "TRANSACTION_EXPIRED"
    access(all) let ERROR_INVALID_NONCE: String = "INVALID_NONCE"
    access(all) let ERROR_BATCH_TOO_LARGE: String = "BATCH_TOO_LARGE"
    access(all) let ERROR_ACCOUNT_INACTIVE: String = "ACCOUNT_INACTIVE"
    access(all) let ERROR_INSUFFICIENT_BALANCE: String = "INSUFFICIENT_BALANCE"
    
    // Utility functions
    
    // Calculate transaction fee based on amount and complexity
    access(all) fun calculateTransactionFee(amount: UFix64, isComplexTransaction: Bool): UFix64 {
        let baseFee = self.BASE_TRANSACTION_FEE
        let complexityMultiplier = isComplexTransaction ? 2.0 : 1.0
        let amountFactor = amount > 100.0 ? 1.5 : 1.0
        
        return baseFee * complexityMultiplier * amountFactor
    }
    
    // Check if transaction is expired
    access(all) fun isTransactionExpired(timestamp: UFix64): Bool {
        let currentTime = getCurrentBlock().timestamp
        return (currentTime - timestamp) > self.TRANSACTION_EXPIRY_SECONDS
    }
    
    // Generate unique transaction ID
    access(all) fun generateTransactionId(from: Address, to: Address, nonce: UInt64, timestamp: UFix64): String {
        let addressString = from.toString().concat("-").concat(to.toString())
        let nonceString = nonce.toString()
        let timestampString = timestamp.toString()
        
        return addressString.concat("-").concat(nonceString).concat("-").concat(timestampString)
    }
    
    // Validate transaction amount
    access(all) fun isValidTransactionAmount(amount: UFix64): Bool {
        return amount > 0.0 && amount <= self.MAX_TRANSACTION_AMOUNT
    }
    
    // Validate signature format
    access(all) fun isValidSignatureFormat(signature: String): Bool {
        let length = signature.length
        return length >= self.MIN_SIGNATURE_LENGTH && length <= self.MAX_SIGNATURE_LENGTH
    }
    
    // Calculate batch processing fee
    access(all) fun calculateBatchFee(transactionCount: Int): UFix64 {
        if transactionCount <= 0 {
            return 0.0
        }
        
        let baseCost = UFix64(transactionCount) * self.BASE_TRANSACTION_FEE
        let batchDiscount = transactionCount > 10 ? 0.9 : 1.0 // 10% discount for batches > 10
        
        return baseCost * batchDiscount
    }
    
    // Validate nonce sequence
    access(all) fun isValidNonceSequence(currentNonce: UInt64, providedNonce: UInt64): Bool {
        // Allow nonce to be current + 1, or within MAX_NONCE_SKIP range for out-of-order processing
        return providedNonce == currentNonce + 1 || 
               (providedNonce > currentNonce && providedNonce <= currentNonce + self.MAX_NONCE_SKIP)
    }
    
    // Get current timestamp
    access(all) fun getCurrentTimestamp(): UFix64 {
        return getCurrentBlock().timestamp
    }
    
    // Format error message with context
    access(all) fun formatError(errorCode: String, context: String): String {
        return errorCode.concat(": ").concat(context)
    }
    
    init() {}
}
