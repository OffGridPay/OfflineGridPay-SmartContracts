// TestConstants.cdc
// Test script for contract constants and configuration

import LINProtocolComplete from 0x5495134c932c7e8a

access(all) fun main(): {String: AnyStruct} {
    let results: {String: AnyStruct} = {}
    
    // Test all contract constants (these are public so we can access them)
    results["MINIMUM_FLOW_DEPOSIT"] = LINProtocolComplete.MINIMUM_FLOW_DEPOSIT
    results["AUTO_REFILL_THRESHOLD"] = LINProtocolComplete.AUTO_REFILL_THRESHOLD
    results["MAX_BATCH_SIZE"] = LINProtocolComplete.MAX_BATCH_SIZE
    results["TRANSACTION_VALIDITY_HOURS"] = LINProtocolComplete.TRANSACTION_VALIDITY_HOURS
    results["BASE_TRANSACTION_FEE"] = LINProtocolComplete.BASE_TRANSACTION_FEE
    results["MAX_TRANSACTION_AMOUNT"] = LINProtocolComplete.MAX_TRANSACTION_AMOUNT
    results["TRANSACTION_EXPIRY_SECONDS"] = LINProtocolComplete.TRANSACTION_EXPIRY_SECONDS
    results["MAX_NONCE_SKIP"] = LINProtocolComplete.MAX_NONCE_SKIP
    results["MAX_SIGNATURE_LENGTH"] = LINProtocolComplete.MAX_SIGNATURE_LENGTH
    results["MIN_SIGNATURE_LENGTH"] = LINProtocolComplete.MIN_SIGNATURE_LENGTH
    
    // Test error message constants
    results["ERROR_INSUFFICIENT_DEPOSIT"] = LINProtocolComplete.ERROR_INSUFFICIENT_DEPOSIT
    results["ERROR_INVALID_SIGNATURE"] = LINProtocolComplete.ERROR_INVALID_SIGNATURE
    results["ERROR_REPLAY_ATTACK"] = LINProtocolComplete.ERROR_REPLAY_ATTACK
    results["ERROR_TRANSACTION_EXPIRED"] = LINProtocolComplete.ERROR_TRANSACTION_EXPIRED
    results["ERROR_INVALID_NONCE"] = LINProtocolComplete.ERROR_INVALID_NONCE
    results["ERROR_BATCH_TOO_LARGE"] = LINProtocolComplete.ERROR_BATCH_TOO_LARGE
    results["ERROR_ACCOUNT_INACTIVE"] = LINProtocolComplete.ERROR_ACCOUNT_INACTIVE
    results["ERROR_INSUFFICIENT_BALANCE"] = LINProtocolComplete.ERROR_INSUFFICIENT_BALANCE
    
    // Test storage paths
    results["ProtocolStoragePath"] = LINProtocolComplete.ProtocolStoragePath.toString()
    results["ProtocolPublicPath"] = LINProtocolComplete.ProtocolPublicPath.toString()
    results["UserAccountStoragePath"] = LINProtocolComplete.UserAccountStoragePath.toString()
    results["UserAccountPublicPath"] = LINProtocolComplete.UserAccountPublicPath.toString()
    
    // Add test metadata
    results["testType"] = "ContractConstants"
    results["timestamp"] = getCurrentBlock().timestamp
    results["contractAddress"] = "0x5495134c932c7e8a"
    
    return results
}
