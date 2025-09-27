// InitializeAccount.cdc
// Transaction to initialize a user account with FLOW deposit

import FlowToken from 0x1654653399040a61
import LINProtocol from "../contracts/LINProtocol.cdc"

transaction(depositAmount: UFix64) {
    
    let flowVault: @FlowToken.Vault
    let linProtocol: &LINProtocol
    
    prepare(signer: AuthAccount) {
        // Get reference to the signer's Flow Token Vault
        let vaultRef = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow reference to the owner's Vault!")
        
        // Withdraw FLOW tokens for deposit
        self.flowVault <- vaultRef.withdraw(amount: depositAmount) as! @FlowToken.Vault
        
        // Get reference to LIN Protocol
        self.linProtocol = getAccount(0xf8d6e0586b0a20c7)
            .getCapability<&LINProtocol>(LINProtocol.ProtocolPublicPath)
            .borrow()
            ?? panic("Could not borrow reference to LIN Protocol")
    }
    
    execute {
        // Initialize account with FLOW deposit
        let userAccount <- self.linProtocol.initializeAccount(
            user: self.flowVault.owner!.address, 
            flowDeposit: <-self.flowVault
        )
        
        // Store the user account in the signer's storage
        signer.save(<-userAccount, to: LINProtocol.UserAccountStoragePath)
        signer.link<&LINInterfaces.UserAccount>(
            LINProtocol.UserAccountPublicPath, 
            target: LINProtocol.UserAccountStoragePath
        )
        
        log("Account initialized successfully with deposit: ".concat(depositAmount.toString()))
    }
}
