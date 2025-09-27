// TestLINProtocol.cdc
// Script to test the deployed LIN Protocol Simple contract

import LINProtocolSimple from 0xf8d6e0586b0a20c7

access(all) fun main(): {String: AnyStruct} {
    // Test getting protocol statistics
    let stats = LINProtocolSimple.getProtocolStats()
    
    // Test getting balance for a non-existent user
    let testAddress: Address = 0x01cf0e2f2f715450
    let balance = LINProtocolSimple.getBalance(user: testAddress)
    let depositBalance = LINProtocolSimple.getDepositBalance(user: testAddress)
    
    // Create a test offline transaction
    let testTx = LINProtocolSimple.OfflineTransaction(
        id: "test-tx-001",
        from: 0x01cf0e2f2f715450,
        to: 0x179b6b1cb6755e31,
        amount: 10.0,
        timestamp: getCurrentBlock().timestamp,
        nonce: 1,
        signature: "test-signature-123"
    )
    
    // Test transaction validation
    let isValid = LINProtocolSimple.validateTransaction(tx: testTx)
    
    return {
        "protocolStats": stats,
        "testUserBalance": balance,
        "testUserDeposit": depositBalance,
        "transactionValid": isValid,
        "testTransactionId": testTx.id,
        "testTransactionAmount": testTx.amount,
        "contractAddress": "0xf8d6e0586b0a20c7",
        "deploymentStatus": "SUCCESS"
    }
}
