// FlowDepositManager.cdc
// Manages FLOW token deposits and automatic fee deductions

import FlowToken from 0x1654653399040a61
import LINInterfaces from "./LINInterfaces.cdc"
import LINConstants from "./LINConstants.cdc"

pub contract FlowDepositManager: LINInterfaces.IDepositManager {
    
    // Storage paths
    pub let DepositStoragePath: StoragePath
    pub let DepositPublicPath: PublicPath
    
    // Contract storage
    access(self) var userDeposits: {Address: UFix64}
    access(self) var depositVault: @FlowToken.Vault
    
    // Events
    pub event DepositReceived(user: Address, amount: UFix64, newBalance: UFix64)
    pub event DepositWithdrawn(user: Address, amount: UFix64, remainingBalance: UFix64)
    pub event FeesDeducted(user: Address, amount: UFix64, remainingDeposit: UFix64)
    pub event LowDepositWarning(user: Address, currentDeposit: UFix64, threshold: UFix64)
    
    // Initialize user deposit account
    pub fun initializeDeposit(user: Address, vault: @FlowToken.Vault) {
        pre {
            vault.balance >= LINConstants.MINIMUM_FLOW_DEPOSIT: "Deposit must be at least minimum required amount"
        }
        
        let amount = vault.balance
        self.depositVault.deposit(from: <-vault)
        self.userDeposits[user] = (self.userDeposits[user] ?? 0.0) + amount
        
        emit DepositReceived(user: user, amount: amount, newBalance: self.userDeposits[user]!)
        emit LINInterfaces.LINEvents.FlowDepositUpdated(user: user, newDeposit: self.userDeposits[user]!)
    }
    
    // Deposit FLOW tokens for a user
    pub fun depositFlow(user: Address, vault: @FlowToken.Vault) {
        let amount = vault.balance
        self.depositVault.deposit(from: <-vault)
        self.userDeposits[user] = (self.userDeposits[user] ?? 0.0) + amount
        
        emit DepositReceived(user: user, amount: amount, newBalance: self.userDeposits[user]!)
        emit LINInterfaces.LINEvents.FlowDepositUpdated(user: user, newDeposit: self.userDeposits[user]!)
    }
    
    // Withdraw FLOW tokens for a user
    pub fun withdrawFlow(user: Address, amount: UFix64): @FlowToken.Vault {
        pre {
            self.userDeposits[user] != nil: "User has no deposit account"
            self.userDeposits[user]! >= amount: "Insufficient deposit balance"
            amount > 0.0: "Withdrawal amount must be positive"
        }
        
        self.userDeposits[user] = self.userDeposits[user]! - amount
        let withdrawnVault <- self.depositVault.withdraw(amount: amount) as! @FlowToken.Vault
        
        emit DepositWithdrawn(user: user, amount: amount, remainingBalance: self.userDeposits[user]!)
        emit LINInterfaces.LINEvents.FlowDepositUpdated(user: user, newDeposit: self.userDeposits[user]!)
        
        return <-withdrawnVault
    }
    
    // Get user's deposit balance
    pub fun getDepositBalance(user: Address): UFix64 {
        return self.userDeposits[user] ?? 0.0
    }
    
    // Deduct fees from user's deposit
    pub fun deductFees(user: Address, amount: UFix64): Bool {
        if self.userDeposits[user] == nil || self.userDeposits[user]! < amount {
            emit LINInterfaces.LINEvents.InsufficientFlowDeposit(
                user: user, 
                required: amount, 
                available: self.userDeposits[user] ?? 0.0
            )
            return false
        }
        
        self.userDeposits[user] = self.userDeposits[user]! - amount
        
        // Check if deposit is below threshold
        if self.userDeposits[user]! < LINConstants.AUTO_REFILL_THRESHOLD {
            emit LowDepositWarning(
                user: user, 
                currentDeposit: self.userDeposits[user]!, 
                threshold: LINConstants.AUTO_REFILL_THRESHOLD
            )
        }
        
        emit FeesDeducted(user: user, amount: amount, remainingDeposit: self.userDeposits[user]!)
        emit LINInterfaces.LINEvents.FlowDepositUpdated(user: user, newDeposit: self.userDeposits[user]!)
        
        return true
    }
    
    // Check if user has sufficient deposit for fees
    pub fun hasSufficientDeposit(user: Address, requiredAmount: UFix64): Bool {
        return self.getDepositBalance(user: user) >= requiredAmount
    }
    
    // Get total contract deposit balance
    pub fun getTotalDeposits(): UFix64 {
        return self.depositVault.balance
    }
    
    // Admin function to get all user deposits (for monitoring)
    pub fun getAllUserDeposits(): {Address: UFix64} {
        return self.userDeposits
    }
    
    init() {
        self.DepositStoragePath = /storage/LINDepositManager
        self.DepositPublicPath = /public/LINDepositManager
        
        self.userDeposits = {}
        self.depositVault <- FlowToken.createEmptyVault() as! @FlowToken.Vault
        
        // Save contract capability to account
        self.account.save(<-create DepositManagerResource(), to: self.DepositStoragePath)
        self.account.link<&{LINInterfaces.IDepositManager}>(self.DepositPublicPath, target: self.DepositStoragePath)
    }
    
    // Resource for managing deposits
    pub resource DepositManagerResource {
        pub fun getManager(): &FlowDepositManager {
            return &FlowDepositManager as &FlowDepositManager
        }
    }
}
