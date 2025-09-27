// SyncOfflineTransactions.cdc
// Transaction to sync a batch of offline transactions to the blockchain

import LINProtocol from "../contracts/LINProtocol.cdc"
import LINInterfaces from "../contracts/LINInterfaces.cdc"

transaction(
    batchId: String,
    transactionIds: [String],
    fromAddresses: [Address],
    toAddresses: [Address],
    amounts: [UFix64],
    timestamps: [UFix64],
    nonces: [UInt64],
    signatures: [String]
) {
    
    let linProtocol: &LINProtocol
    let submitter: Address
    
    prepare(signer: AuthAccount) {
        self.submitter = signer.address
        
        // Get reference to LIN Protocol
        self.linProtocol = getAccount(0xf8d6e0586b0a20c7)
            .getCapability<&LINProtocol>(LINProtocol.ProtocolPublicPath)
            .borrow()
            ?? panic("Could not borrow reference to LIN Protocol")
    }
    
    execute {
        // Validate input arrays have same length
        assert(
            transactionIds.length == fromAddresses.length &&
            fromAddresses.length == toAddresses.length &&
            toAddresses.length == amounts.length &&
            amounts.length == timestamps.length &&
            timestamps.length == nonces.length &&
            nonces.length == signatures.length,
            message: "All input arrays must have the same length"
        )
        
        // Create offline transactions
        let transactions: [LINInterfaces.OfflineTransaction] = []
        var i = 0
        
        while i < transactionIds.length {
            let tx = LINInterfaces.OfflineTransaction(
                id: transactionIds[i],
                from: fromAddresses[i],
                to: toAddresses[i],
                amount: amounts[i],
                timestamp: timestamps[i],
                nonce: nonces[i],
                signature: signatures[i]
            )
            transactions.append(tx)
            i = i + 1
        }
        
        // Create transaction batch
        let batch = LINInterfaces.TransactionBatch(
            batchId: batchId,
            submitter: self.submitter,
            transactions: transactions
        )
        
        // Sync the batch
        let success = self.linProtocol.syncOfflineTransactions(batch: batch)
        
        if success {
            log("Batch sync completed successfully. Batch ID: ".concat(batchId))
        } else {
            log("Batch sync completed with some failures. Batch ID: ".concat(batchId))
        }
    }
}
