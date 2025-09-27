// TestTransfer.cdc
// Transaction to test transferring tokens between users in LIN Protocol

import LINProtocolComplete from 0x5495134c932c7e8a

transaction(toAddress: Address, amount: UFix64) {
    
    let signerAddress: Address
    
    prepare(signer: AuthAccount) {
        self.signerAddress = signer.address
        
        // Check if user has sufficient balance
        let balance = LINProtocolComplete.getBalance(user: signer.address)
        if balance < amount {
            panic("Insufficient balance. Available: ".concat(balance.toString()).concat(", Required: ").concat(amount.toString()))
        }
        
        // Check if recipient is active (has an account)
        let recipientActive = LINProtocolComplete.isUserActive(user: toAddress)
        if !recipientActive {
            log("Warning: Recipient ".concat(toAddress.toString()).concat(" is not active in LIN Protocol"))
        }
        
        log("Prepared transfer of ".concat(amount.toString()).concat(" from ").concat(signer.address.toString()).concat(" to ").concat(toAddress.toString()))
    }
    
    execute {
        // Get current balances before transfer
        let senderBalanceBefore = LINProtocolComplete.getBalance(user: self.signerAddress)
        let recipientBalanceBefore = LINProtocolComplete.getBalance(user: toAddress)
        
        // Perform the transfer
        LINProtocolComplete.transfer(from: self.signerAddress, to: toAddress, amount: amount)
        
        // Get balances after transfer
        let senderBalanceAfter = LINProtocolComplete.getBalance(user: self.signerAddress)
        let recipientBalanceAfter = LINProtocolComplete.getBalance(user: toAddress)
        
        log("Transfer completed successfully!")
        log("Sender balance: ".concat(senderBalanceBefore.toString()).concat(" -> ").concat(senderBalanceAfter.toString()))
        log("Recipient balance: ".concat(recipientBalanceBefore.toString()).concat(" -> ").concat(recipientBalanceAfter.toString()))
        log("Amount transferred: ".concat(amount.toString()))
    }
}
