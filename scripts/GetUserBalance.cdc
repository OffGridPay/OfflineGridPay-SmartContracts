// GetUserBalance.cdc
// Script to get user's balance and account information

import LINProtocol from "../contracts/LINProtocol.cdc"
import FlowDepositManager from "../contracts/FlowDepositManager.cdc"

pub fun main(userAddress: Address): {String: UFix64} {
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
    
    // Get user balance and deposit information
    let balance = linProtocol.getBalance(user: userAddress)
    let deposit = depositManager.getDepositBalance(user: userAddress)
    
    return {
        "balance": balance,
        "flowDeposit": deposit
    }
}
