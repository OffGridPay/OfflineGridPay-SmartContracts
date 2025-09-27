// TestDeposit.cdc
// Transaction to test depositing FLOW tokens into LIN Protocol

import FlowToken from 0x7e60df042a9c0868
import LINProtocolComplete from 0x5495134c932c7e8a

transaction(depositAmount: UFix64) {
    
    let flowVault: @FlowToken.Vault
    let signerAddress: Address
    
    prepare(signer: AuthAccount) {
        // Store signer address
        self.signerAddress = signer.address
        
        // Get reference to the signer's Flow Token Vault
        let vaultRef = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow reference to the owner's Vault!")
        
        // Check if user has enough balance
        let balance = vaultRef.balance
        if balance < depositAmount {
            panic("Insufficient balance. Available: ".concat(balance.toString()).concat(", Required: ").concat(depositAmount.toString()))
        }
        
        // Withdraw FLOW tokens for deposit
        self.flowVault <- vaultRef.withdraw(amount: depositAmount) as! @FlowToken.Vault
        
        log("Prepared deposit of ".concat(depositAmount.toString()).concat(" FLOW from ").concat(signer.address.toString()))
    }
    
    execute {
        // Deposit FLOW tokens into LIN Protocol
        LINProtocolComplete.depositFlow(from: self.signerAddress, flowVault: <-self.flowVault)
        
        log("Successfully deposited ".concat(depositAmount.toString()).concat(" FLOW into LIN Protocol"))
        log("New balance: ".concat(LINProtocolComplete.getBalance(user: self.signerAddress).toString()))
        log("New deposit balance: ".concat(LINProtocolComplete.getDepositBalance(user: self.signerAddress).toString()))
    }
}
