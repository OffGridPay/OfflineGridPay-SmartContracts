// TestUserBalance.cdc
// Test script for user balance queries

import LINProtocolComplete from 0x5495134c932c7e8a

access(all) fun main(userAddress: Address): {String: AnyStruct} {
    let results: {String: AnyStruct} = {}
    
    // Test balance query
    let balance = LINProtocolComplete.getBalance(user: userAddress)
    results["userBalance"] = balance
    
    // Test deposit balance query
    let depositBalance = LINProtocolComplete.getDepositBalance(user: userAddress)
    results["depositBalance"] = depositBalance
    
    // Test nonce query
    let nonce = LINProtocolComplete.getUserNonce(user: userAddress)
    results["userNonce"] = nonce
    
    // Test active status
    let isActive = LINProtocolComplete.isUserActive(user: userAddress)
    results["isActive"] = isActive
    
    // Add test metadata
    results["testAddress"] = userAddress.toString()
    results["testType"] = "UserBalanceQuery"
    results["timestamp"] = getCurrentBlock().timestamp
    
    return results
}
