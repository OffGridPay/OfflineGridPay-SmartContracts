// GetProtocolStats.cdc
// Script to get protocol statistics and health information

import LINProtocol from "../contracts/LINProtocol.cdc"
import FlowDepositManager from "../contracts/FlowDepositManager.cdc"
import OfflineTransactionValidator from "../contracts/OfflineTransactionValidator.cdc"

pub fun main(): {String: AnyStruct} {
    // Get reference to LIN Protocol
    let linProtocol = getAccount(0xf8d6e0586b0a20c7)
        .getCapability<&LINProtocol>(LINProtocol.ProtocolPublicPath)
        .borrow()
        ?? panic("Could not borrow reference to LIN Protocol")
    
    // Get reference to Deposit Manager
    let depositManager = getAccount(0xf8d6e0586b0a20c7)
        .getCapability<&FlowDepositManager>(FlowDepositManager.DepositPublicPath)
        .borrow()
        ?? panic("Could not borrow reference to FlowDepositManager")
    
    // Get reference to Transaction Validator
    let validator = getAccount(0xf8d6e0586b0a20c7)
        .getCapability<&OfflineTransactionValidator>(OfflineTransactionValidator.ValidatorPublicPath)
        .borrow()
        ?? panic("Could not borrow reference to OfflineTransactionValidator")
    
    // Collect statistics
    let protocolStats = linProtocol.getProtocolStats()
    let validationStats = validator.getValidationStats()
    let totalDeposits = depositManager.getTotalDeposits()
    
    return {
        "protocol": protocolStats,
        "validation": validationStats,
        "totalDeposits": totalDeposits,
        "timestamp": getCurrentBlock().timestamp
    }
}
