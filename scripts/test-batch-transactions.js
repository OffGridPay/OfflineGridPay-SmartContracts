const { ethers } = require("hardhat");

// Contract address on FlowEVM testnet
const CONTRACT_ADDRESS = "0x5047983EC64EF766B6a524FA2b6E1C3f766B84D6";

async function main() {
  console.log("🔄 Testing Batch Transaction Processing");
  console.log("=" .repeat(50));

  // Get signers
  const [deployer, user1, user2, user3] = await ethers.getSigners();
  
  // Connect to contract
  const LINProtocol = await ethers.getContractFactory("LINProtocolEVM");
  const contract = LINProtocol.attach(CONTRACT_ADDRESS);
  
  console.log(`📍 Contract: ${CONTRACT_ADDRESS}`);
  console.log(`🌐 Network: ${hre.network.name}`);

  try {
    // Step 1: Initialize accounts if not already done
    console.log("\n🏗️  Step 1: Setting up test accounts");
    console.log("-".repeat(40));

    const depositAmount = ethers.parseEther("20"); // 20 FLOW each
    const initialBalance = ethers.parseEther("100"); // 100 FLOW balance each

    // Check if accounts are already initialized
    const user1Active = await contract.isUserActive(user1.address);
    const user2Active = await contract.isUserActive(user2.address);
    const user3Active = await contract.isUserActive(user3.address);

    if (!user1Active) {
      console.log("💰 Initializing User1...");
      const tx1 = await contract.connect(user1).initializeAccount({ value: depositAmount });
      await tx1.wait();
      console.log("✅ User1 initialized");
    } else {
      console.log("✅ User1 already initialized");
    }

    if (!user2Active) {
      console.log("💰 Initializing User2...");
      const tx2 = await contract.connect(user2).initializeAccount({ value: depositAmount });
      await tx2.wait();
      console.log("✅ User2 initialized");
    } else {
      console.log("✅ User2 already initialized");
    }

    if (!user3Active) {
      console.log("💰 Initializing User3...");
      const tx3 = await contract.connect(user3).initializeAccount({ value: depositAmount });
      await tx3.wait();
      console.log("✅ User3 initialized");
    } else {
      console.log("✅ User3 already initialized");
    }

    // Set balances for testing
    console.log("⚖️  Setting account balances...");
    await (await contract.connect(deployer).updateBalance(user1.address, initialBalance)).wait();
    await (await contract.connect(deployer).updateBalance(user2.address, initialBalance)).wait();
    await (await contract.connect(deployer).updateBalance(user3.address, initialBalance)).wait();
    console.log("✅ All balances set to 100 FLOW");

    // Step 2: Create offline transactions
    console.log("\n📱 Step 2: Creating offline transactions");
    console.log("-".repeat(40));

    const currentTime = Math.floor(Date.now() / 1000);
    const transactions = [];

    // Transaction 1: User1 -> User2 (10 FLOW)
    const tx1Id = await contract.generateTransactionId(user1.address, user2.address, 1, currentTime);
    const tx1 = {
      id: tx1Id,
      from: user1.address,
      to: user2.address,
      amount: ethers.parseEther("10"),
      timestamp: currentTime,
      nonce: 1,
      signature: "0x",
      status: 0
    };

    // Create signature for tx1
    const messageHash1 = ethers.keccak256(ethers.solidityPacked(
      ["string", "address", "address", "uint256", "uint256", "uint256"],
      [tx1.id, tx1.from, tx1.to, tx1.amount, tx1.timestamp, tx1.nonce]
    ));
    tx1.signature = await user1.signMessage(ethers.getBytes(messageHash1));
    transactions.push(tx1);

    console.log(`✅ Created TX1: ${user1.address.slice(0,8)}... -> ${user2.address.slice(0,8)}... (10 FLOW)`);

    // Transaction 2: User2 -> User3 (15 FLOW)
    const tx2Id = await contract.generateTransactionId(user2.address, user3.address, 1, currentTime + 1);
    const tx2 = {
      id: tx2Id,
      from: user2.address,
      to: user3.address,
      amount: ethers.parseEther("15"),
      timestamp: currentTime + 1,
      nonce: 1,
      signature: "0x",
      status: 0
    };

    const messageHash2 = ethers.keccak256(ethers.solidityPacked(
      ["string", "address", "address", "uint256", "uint256", "uint256"],
      [tx2.id, tx2.from, tx2.to, tx2.amount, tx2.timestamp, tx2.nonce]
    ));
    tx2.signature = await user2.signMessage(ethers.getBytes(messageHash2));
    transactions.push(tx2);

    console.log(`✅ Created TX2: ${user2.address.slice(0,8)}... -> ${user3.address.slice(0,8)}... (15 FLOW)`);

    // Transaction 3: User3 -> User1 (5 FLOW)
    const tx3Id = await contract.generateTransactionId(user3.address, user1.address, 1, currentTime + 2);
    const tx3 = {
      id: tx3Id,
      from: user3.address,
      to: user1.address,
      amount: ethers.parseEther("5"),
      timestamp: currentTime + 2,
      nonce: 1,
      signature: "0x",
      status: 0
    };

    const messageHash3 = ethers.keccak256(ethers.solidityPacked(
      ["string", "address", "address", "uint256", "uint256", "uint256"],
      [tx3.id, tx3.from, tx3.to, tx3.amount, tx3.timestamp, tx3.nonce]
    ));
    tx3.signature = await user3.signMessage(ethers.getBytes(messageHash3));
    transactions.push(tx3);

    console.log(`✅ Created TX3: ${user3.address.slice(0,8)}... -> ${user1.address.slice(0,8)}... (5 FLOW)`);

    // Step 3: Check balances before batch processing
    console.log("\n📊 Step 3: Balances before batch processing");
    console.log("-".repeat(40));

    const beforeUser1 = await contract.getBalance(user1.address);
    const beforeUser2 = await contract.getBalance(user2.address);
    const beforeUser3 = await contract.getBalance(user3.address);

    console.log(`User1: ${ethers.formatEther(beforeUser1)} FLOW`);
    console.log(`User2: ${ethers.formatEther(beforeUser2)} FLOW`);
    console.log(`User3: ${ethers.formatEther(beforeUser3)} FLOW`);

    // Step 4: Create and process transaction batch
    console.log("\n🔄 Step 4: Processing transaction batch");
    console.log("-".repeat(40));

    const batchId = `batch-${Date.now()}`;
    const batch = {
      batchId: batchId,
      submitter: user1.address,
      transactions: transactions,
      timestamp: currentTime,
      flowUsed: ethers.parseEther("0.003") // 3 transactions * 0.001 FLOW fee
    };

    console.log(`📦 Batch ID: ${batchId}`);
    console.log(`👤 Submitter: ${user1.address}`);
    console.log(`📊 Transaction count: ${transactions.length}`);
    console.log(`💰 Estimated fees: ${ethers.formatEther(batch.flowUsed)} FLOW`);

    // Check submitter's deposit balance
    const submitterDeposit = await contract.getDepositBalance(user1.address);
    console.log(`💳 Submitter deposit: ${ethers.formatEther(submitterDeposit)} FLOW`);

    if (submitterDeposit < batch.flowUsed) {
      console.log("⚠️  Insufficient deposit for fees. Adding more deposit...");
      const additionalDeposit = ethers.parseEther("1");
      const addDepositTx = await contract.connect(user1).addFlowDeposit({ value: additionalDeposit });
      await addDepositTx.wait();
      console.log("✅ Additional deposit added");
    }

    // Process the batch
    console.log("🚀 Processing batch...");
    try {
      const batchTx = await contract.connect(user1).syncOfflineTransactions(batch);
      console.log(`⏳ Batch transaction sent: ${batchTx.hash}`);
      
      const receipt = await batchTx.wait();
      console.log("✅ Batch processed successfully!");
      
      // Check for events
      const events = receipt.logs;
      console.log(`📋 Events emitted: ${events.length}`);
      
    } catch (error) {
      console.log(`❌ Batch processing failed: ${error.message}`);
      
      // Let's test individual transaction validation
      console.log("\n🔍 Testing individual transaction validation:");
      for (let i = 0; i < transactions.length; i++) {
        const tx = transactions[i];
        console.log(`\nTransaction ${i + 1}:`);
        
        // Test signature validation
        try {
          const isValidSig = await contract.validateSignature(tx);
          console.log(`  Signature valid: ${isValidSig}`);
        } catch (sigError) {
          console.log(`  Signature error: ${sigError.message}`);
        }
        
        // Test nonce validation
        const isValidNonce = await contract.validateNonce(tx.from, tx.nonce);
        console.log(`  Nonce valid: ${isValidNonce}`);
        
        // Test replay protection
        const canProcess = await contract.preventReplay(tx.id);
        console.log(`  Can process: ${canProcess}`);
        
        // Test expiry
        const isExpired = await contract.isTransactionExpired(tx.timestamp);
        console.log(`  Is expired: ${isExpired}`);
      }
    }

    // Step 5: Check balances after batch processing
    console.log("\n📊 Step 5: Balances after batch processing");
    console.log("-".repeat(40));

    const afterUser1 = await contract.getBalance(user1.address);
    const afterUser2 = await contract.getBalance(user2.address);
    const afterUser3 = await contract.getBalance(user3.address);

    console.log(`User1: ${ethers.formatEther(afterUser1)} FLOW (change: ${ethers.formatEther(afterUser1 - beforeUser1)})`);
    console.log(`User2: ${ethers.formatEther(afterUser2)} FLOW (change: ${ethers.formatEther(afterUser2 - beforeUser2)})`);
    console.log(`User3: ${ethers.formatEther(afterUser3)} FLOW (change: ${ethers.formatEther(afterUser3 - beforeUser3)})`);

    // Step 6: Check deposit balances
    console.log("\n💳 Step 6: Deposit balances after processing");
    console.log("-".repeat(40));

    const deposit1 = await contract.getDepositBalance(user1.address);
    const deposit2 = await contract.getDepositBalance(user2.address);
    const deposit3 = await contract.getDepositBalance(user3.address);

    console.log(`User1 deposit: ${ethers.formatEther(deposit1)} FLOW`);
    console.log(`User2 deposit: ${ethers.formatEther(deposit2)} FLOW`);
    console.log(`User3 deposit: ${ethers.formatEther(deposit3)} FLOW`);

    // Step 7: Check nonces
    console.log("\n🔢 Step 7: Account nonces after processing");
    console.log("-".repeat(40));

    const nonce1 = await contract.getUserNonce(user1.address);
    const nonce2 = await contract.getUserNonce(user2.address);
    const nonce3 = await contract.getUserNonce(user3.address);

    console.log(`User1 nonce: ${nonce1}`);
    console.log(`User2 nonce: ${nonce2}`);
    console.log(`User3 nonce: ${nonce3}`);

    // Step 8: Test replay protection
    console.log("\n🔄 Step 8: Testing replay protection");
    console.log("-".repeat(40));

    for (let i = 0; i < transactions.length; i++) {
      const tx = transactions[i];
      const isProcessed = await contract.isTransactionProcessed(tx.id);
      console.log(`TX${i + 1} (${tx.id.slice(0, 20)}...) processed: ${isProcessed}`);
    }

    // Step 9: Contract statistics
    console.log("\n📈 Step 9: Final contract statistics");
    console.log("-".repeat(40));

    const finalTotalUsers = await contract.totalUsers();
    const finalTotalTransactions = await contract.totalTransactions();
    const finalTotalDeposited = await contract.totalFlowDeposited();

    console.log(`Total users: ${finalTotalUsers}`);
    console.log(`Total transactions: ${finalTotalTransactions}`);
    console.log(`Total deposited: ${ethers.formatEther(finalTotalDeposited)} FLOW`);

    console.log("\n" + "🎉".repeat(20));
    console.log("🎉 BATCH TRANSACTION TEST COMPLETED! 🎉");
    console.log("🎉".repeat(20));

  } catch (error) {
    console.error("\n❌ Test failed with error:");
    console.error(error);
    process.exit(1);
  }
}

main()
  .then(() => {
    console.log("\n✅ Batch transaction testing completed!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("\n❌ Testing failed:");
    console.error(error);
    process.exit(1);
  });
