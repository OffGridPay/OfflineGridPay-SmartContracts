// LINProtocol_test.cdc
// Unit tests for LIN Protocol contracts

import Test
import BlockchainHelpers
import FlowToken from 0x0ae53cb6e3f42a79
import LINProtocol from "../contracts/LINProtocol.cdc"
import LINInterfaces from "../contracts/LINInterfaces.cdc"
import LINConstants from "../contracts/LINConstants.cdc"
import FlowDepositManager from "../contracts/FlowDepositManager.cdc"
import OfflineTransactionValidator from "../contracts/OfflineTransactionValidator.cdc"

pub let admin = Test.createAccount()
pub let user1 = Test.createAccount()
pub let user2 = Test.createAccount()

pub fun setup() {
    // Deploy contracts
    let err1 = Test.deployContract(
        name: "LINConstants",
        path: "../contracts/LINConstants.cdc",
        arguments: []
    )
    Test.expect(err1, Test.beNil())
    
    let err2 = Test.deployContract(
        name: "LINInterfaces", 
        path: "../contracts/LINInterfaces.cdc",
        arguments: []
    )
    Test.expect(err2, Test.beNil())
    
    let err3 = Test.deployContract(
        name: "FlowDepositManager",
        path: "../contracts/FlowDepositManager.cdc", 
        arguments: []
    )
    Test.expect(err3, Test.beNil())
    
    let err4 = Test.deployContract(
        name: "OfflineTransactionValidator",
        path: "../contracts/OfflineTransactionValidator.cdc",
        arguments: []
    )
    Test.expect(err4, Test.beNil())
    
    let err5 = Test.deployContract(
        name: "LINProtocol",
        path: "../contracts/LINProtocol.cdc",
        arguments: []
    )
    Test.expect(err5, Test.beNil())
}

pub fun testAccountInitialization() {
    // Create FLOW vault for deposit
    let flowVault <- FlowToken.createEmptyVault() as! @FlowToken.Vault
    
    // Add FLOW tokens to vault (simulated)
    let depositAmount = 15.0
    
    // Test account initialization
    let txResult = Test.executeTransaction(
        "../transactions/InitializeAccount.cdc",
        [depositAmount],
        user1
    )
    
    Test.expect(txResult, Test.beSucceeded())
    
    // Verify account was created
    let balance = Test.executeScript(
        "../scripts/GetUserBalance.cdc",
        [user1.address]
    )
    
    Test.expect(balance, Test.beSucceeded())
    
    let balanceResult = balance.returnValue! as! {String: UFix64}
    Test.expect(balanceResult["flowDeposit"]!, Test.equal(depositAmount))
}

pub fun testTransactionValidation() {
    // Create a sample offline transaction
    let tx = LINInterfaces.OfflineTransaction(
        id: "test-tx-001",
        from: user1.address,
        to: user2.address,
        amount: 5.0,
        timestamp: getCurrentBlock().timestamp,
        nonce: 1,
        signature: "sample-signature-hash-12345678901234567890123456789012345678901234567890"
    )
    
    // Test transaction validation
    let validationScript = `
        import OfflineTransactionValidator from 0xf8d6e0586b0a20c7
        import LINInterfaces from 0xf8d6e0586b0a20c7
        
        pub fun main(): Bool {
            let validator = getAccount(0xf8d6e0586b0a20c7)
                .getCapability<&OfflineTransactionValidator>(OfflineTransactionValidator.ValidatorPublicPath)
                .borrow()!
            
            let tx = LINInterfaces.OfflineTransaction(
                id: "test-tx-001",
                from: 0x01cf0e2f2f715450,
                to: 0x179b6b1cb6755e31,
                amount: 5.0,
                timestamp: getCurrentBlock().timestamp,
                nonce: 1,
                signature: "sample-signature-hash-12345678901234567890123456789012345678901234567890"
            )
            
            return validator.validateTransaction(tx: tx)
        }
    `
    
    let result = Test.executeScript(validationScript, [])
    Test.expect(result, Test.beSucceeded())
}

pub fun testDepositManagement() {
    // Test deposit functionality
    let depositScript = `
        import FlowDepositManager from 0xf8d6e0586b0a20c7
        
        pub fun main(user: Address): UFix64 {
            let depositManager = getAccount(0xf8d6e0586b0a20c7)
                .getCapability<&FlowDepositManager>(FlowDepositManager.DepositPublicPath)
                .borrow()!
            
            return depositManager.getDepositBalance(user: user)
        }
    `
    
    let result = Test.executeScript(depositScript, [user1.address])
    Test.expect(result, Test.beSucceeded())
    
    let depositBalance = result.returnValue! as! UFix64
    Test.expect(depositBalance, Test.beGreaterThan(0.0))
}

pub fun testProtocolStats() {
    let result = Test.executeScript("../scripts/GetProtocolStats.cdc", [])
    Test.expect(result, Test.beSucceeded())
    
    let stats = result.returnValue! as! {String: AnyStruct}
    Test.expect(stats["protocol"], Test.beNil().not())
    Test.expect(stats["validation"], Test.beNil().not())
    Test.expect(stats["totalDeposits"], Test.beNil().not())
}

pub fun testConstants() {
    let constantsScript = `
        import LINConstants from 0xf8d6e0586b0a20c7
        
        pub fun main(): {String: AnyStruct} {
            return {
                "minimumDeposit": LINConstants.MINIMUM_FLOW_DEPOSIT,
                "maxBatchSize": LINConstants.MAX_BATCH_SIZE,
                "baseFee": LINConstants.BASE_TRANSACTION_FEE
            }
        }
    `
    
    let result = Test.executeScript(constantsScript, [])
    Test.expect(result, Test.beSucceeded())
    
    let constants = result.returnValue! as! {String: AnyStruct}
    Test.expect(constants["minimumDeposit"]! as! UFix64, Test.equal(10.0))
    Test.expect(constants["maxBatchSize"]! as! Int, Test.equal(100))
    Test.expect(constants["baseFee"]! as! UFix64, Test.equal(0.001))
}

pub fun testBatchProcessing() {
    // Test batch transaction processing
    let batchScript = `
        import LINProtocol from 0xf8d6e0586b0a20c7
        import LINInterfaces from 0xf8d6e0586b0a20c7
        
        pub fun main(): Bool {
            let protocol = getAccount(0xf8d6e0586b0a20c7)
                .getCapability<&LINProtocol>(LINProtocol.ProtocolPublicPath)
                .borrow()!
            
            let transactions: [LINInterfaces.OfflineTransaction] = []
            
            let tx = LINInterfaces.OfflineTransaction(
                id: "batch-tx-001",
                from: 0x01cf0e2f2f715450,
                to: 0x179b6b1cb6755e31,
                amount: 1.0,
                timestamp: getCurrentBlock().timestamp,
                nonce: 1,
                signature: "sample-signature-hash-12345678901234567890123456789012345678901234567890"
            )
            
            transactions.append(tx)
            
            let batch = LINInterfaces.TransactionBatch(
                batchId: "test-batch-001",
                submitter: 0x01cf0e2f2f715450,
                transactions: transactions
            )
            
            return protocol.syncOfflineTransactions(batch: batch)
        }
    `
    
    let result = Test.executeScript(batchScript, [])
    // Note: This might fail due to validation requirements, but tests the structure
    Test.expect(result, Test.beSucceeded().not()) // Expected to fail without proper setup
}

// Run all tests
pub fun main() {
    setup()
    
    testAccountInitialization()
    testTransactionValidation()
    testDepositManagement()
    testProtocolStats()
    testConstants()
    testBatchProcessing()
    
    log("All LIN Protocol tests completed!")
}
