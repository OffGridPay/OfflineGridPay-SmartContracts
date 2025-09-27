// TestProtocolStats.cdc
// Test script for protocol statistics

import LINProtocolComplete from 0x5495134c932c7e8a

access(all) fun main(): {String: AnyStruct} {
    let results: {String: AnyStruct} = {}
    
    // Get protocol statistics
    results["totalUsers"] = LINProtocolComplete.getTotalUsers()
    results["totalTransactions"] = LINProtocolComplete.getTotalTransactions()
    results["totalFlowDeposited"] = LINProtocolComplete.getTotalFlowDeposited()
    
    // Test utility functions
    let testAmount: UFix64 = 100.0
    results["transactionFeeSimple"] = LINProtocolComplete.calculateTransactionFee(amount: testAmount, isComplexTransaction: false)
    results["transactionFeeComplex"] = LINProtocolComplete.calculateTransactionFee(amount: testAmount, isComplexTransaction: true)
    results["batchFee10Txs"] = LINProtocolComplete.calculateBatchFee(transactionCount: 10)
    
    // Test validation functions
    results["validAmount100"] = LINProtocolComplete.isValidTransactionAmount(amount: 100.0)
    results["validAmount0"] = LINProtocolComplete.isValidTransactionAmount(amount: 0.0)
    results["validAmountMax"] = LINProtocolComplete.isValidTransactionAmount(amount: 1000000.0)
    
    // Generate test transaction ID
    let testTxId = LINProtocolComplete.generateTransactionId(
        from: 0x5495134c932c7e8a,
        to: 0x1234567890abcdef,
        nonce: 1,
        timestamp: getCurrentBlock().timestamp
    )
    results["generatedTxId"] = testTxId
    
    // Add test metadata
    results["testType"] = "ProtocolStatistics"
    results["timestamp"] = getCurrentBlock().timestamp
    results["blockHeight"] = getCurrentBlock().height
    
    return results
}
