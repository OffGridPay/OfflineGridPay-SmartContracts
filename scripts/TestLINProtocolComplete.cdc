// TestLINProtocolComplete.cdc
// Comprehensive test script for the complete LIN Protocol contract

import LINProtocolComplete from 0x5495134c932c7e8a
import FlowToken from 0x7e60df042a9c0868

access(all) fun main(): {String: AnyStruct} {
    let results: {String: AnyStruct} = {}
    
    // Test 1: Get protocol statistics
    results["totalUsers"] = LINProtocolComplete.getTotalUsers()
    results["totalTransactions"] = LINProtocolComplete.getTotalTransactions()
    results["totalFlowDeposited"] = LINProtocolComplete.getTotalFlowDeposited()
    
    // Test 2: Test utility functions
    let testAmount: UFix64 = 100.0
    let transactionFee = LINProtocolComplete.calculateTransactionFee(amount: testAmount, isComplexTransaction: false)
    results["calculatedTransactionFee"] = transactionFee
    
    let batchFee = LINProtocolComplete.calculateBatchFee(transactionCount: 5)
    results["calculatedBatchFee"] = batchFee
    
    // Test 3: Test validation functions
    let validAmount = LINProtocolComplete.isValidTransactionAmount(amount: 50.0)
    let invalidAmount = LINProtocolComplete.isValidTransactionAmount(amount: 0.0)
    results["validAmountCheck"] = validAmount
    results["invalidAmountCheck"] = invalidAmount
    
    let validSignature = LINProtocolComplete.isValidSignatureFormat(signature: "a".repeat(128))
    let invalidSignature = LINProtocolComplete.isValidSignatureFormat(signature: "abc")
    results["validSignatureFormat"] = validSignature
    results["invalidSignatureFormat"] = invalidSignature
    
    // Test 4: Test transaction ID generation
    let testAddress1: Address = 0x01
    let testAddress2: Address = 0x02
    let testNonce: UInt64 = 1
    let testTimestamp = LINProtocolComplete.getCurrentTimestamp()
    
    let generatedTxId = LINProtocolComplete.generateTransactionId(
        from: testAddress1,
        to: testAddress2,
        nonce: testNonce,
        timestamp: testTimestamp
    )
    results["generatedTransactionId"] = generatedTxId
    
    // Test 5: Test error formatting
    let formattedError = LINProtocolComplete.formatError(
        errorCode: "TEST_ERROR",
        context: "This is a test context"
    )
    results["formattedError"] = formattedError
    
    // Test 6: Test constants access
    results["minimumFlowDeposit"] = LINProtocolComplete.MINIMUM_FLOW_DEPOSIT
    results["maxBatchSize"] = LINProtocolComplete.MAX_BATCH_SIZE
    results["baseTransactionFee"] = LINProtocolComplete.BASE_TRANSACTION_FEE
    results["transactionExpirySeconds"] = LINProtocolComplete.TRANSACTION_EXPIRY_SECONDS
    
    // Test 7: Test user account queries (will return defaults for non-existent users)
    let testUserAddress: Address = 0x1234567890abcdef
    results["userBalance"] = LINProtocolComplete.getBalance(user: testUserAddress)
    results["userDepositBalance"] = LINProtocolComplete.getDepositBalance(user: testUserAddress)
    results["userNonce"] = LINProtocolComplete.getUserNonce(user: testUserAddress)
    results["userActive"] = LINProtocolComplete.isUserActive(user: testUserAddress)
    
    // Test 8: Create sample offline transaction structure
    let sampleTransaction = LINProtocolComplete.OfflineTransaction(
        id: generatedTxId,
        from: testAddress1,
        to: testAddress2,
        amount: 10.0,
        timestamp: testTimestamp,
        nonce: testNonce,
        signature: "sample_signature_".concat("a".repeat(100))
    )
    
    results["sampleTransactionId"] = sampleTransaction.id
    results["sampleTransactionAmount"] = sampleTransaction.amount
    results["sampleTransactionStatus"] = sampleTransaction.status.rawValue
    
    // Test 9: Create sample transaction batch
    let sampleBatch = LINProtocolComplete.TransactionBatch(
        batchId: "batch_001",
        submitter: testAddress1,
        transactions: [sampleTransaction]
    )
    
    results["sampleBatchId"] = sampleBatch.batchId
    results["sampleBatchTransactionCount"] = sampleBatch.transactions.length
    results["sampleBatchFlowUsed"] = sampleBatch.flowUsed
    
    // Test 10: Test current timestamp
    results["currentTimestamp"] = LINProtocolComplete.getCurrentTimestamp()
    
    return results
}
