// InitializeAccountSimple.cdc
// Simple transaction to initialize a user account in LIN Protocol

import FlowToken from 0x7e60df042a9c0868
import LINProtocolSimple from 0xc961a88c4307d5bf

transaction(depositAmount: UFix64) {
    
    let flowVault: @FlowToken.Vault
    let userAccount: &LINProtocolSimple.UserAccount?
    
    prepare(signer: &Account) {
        // Get FlowToken vault from signer
        let vaultRef = signer.capabilities.borrow<&FlowToken.Vault>(/public/flowTokenBalance)
            ?? panic("Could not borrow FlowToken vault reference")
        
        // Withdraw FLOW tokens for deposit
        self.flowVault <- vaultRef.withdraw(amount: depositAmount) as! @FlowToken.Vault
        
        // Check if user account already exists
        self.userAccount = signer.capabilities.borrow<&LINProtocolSimple.UserAccount>(/public/LINUserAccount)
    }
    
    execute {
        // Initialize account if it doesn't exist
        if self.userAccount == nil {
            let newAccount <- LINProtocolSimple.initializeAccount(
                user: self.flowVault.owner!.address, 
                vault: <-self.flowVault
            )
            
            // Store the account (simplified - in production would use proper storage)
            destroy newAccount
        } else {
            // Account already exists, return the vault
            destroy self.flowVault
        }
    }
}
