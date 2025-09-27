const { ethers } = require("hardhat");

// Contract address on FlowEVM testnet
const CONTRACT_ADDRESS = "0x5047983EC64EF766B6a524FA2b6E1C3f766B84D6";

async function main() {
  console.log("⚡ LIN Protocol Performance Testing");
  console.log("=" .repeat(50));

  // Get signers
  const [deployer, ...users] = await ethers.getSigners();
  
  // Connect to contract
  const LINProtocol = await ethers.getContractFactory("offgridpay");
  const contract = LINProtocol.attach(CONTRACT_ADDRESS);
  
  console.log(`📍 Contract: ${CONTRACT_ADDRESS}`);
  console.log(`🌐 Network: ${hre.network.name}`);
  console.log(`👥 Test users: ${users.length}`);

  try {
    // Performance Test 1: Mass account initialization
    console.log("\n⚡ Test 1: Mass Account Initialization");
    console.log("-".repeat(40));

    const initStartTime = Date.now();
    const depositAmount = ethers.parseEther("15");
    const initPromises = [];

    // Initialize first 5 users concurrently
    for (let i = 0; i < Math.min(5, users.length); i++) {
      const user = users[i];
      const isActive = await contract.isUserActive(user.address);
      
      if (!isActive) {
        console.log(`🏗️  Initializing User${i + 1}...`);
        initPromises.push(
          contract.connect(user).initializeAccount({ value: depositAmount })
            .then(tx => tx.wait())
            .then(() => console.log(`✅ User${i + 1} initialized`))
        );
      } else {
        console.log(`✅ User${i + 1} already initialized`);
      }
    }

    await Promise.all(initPromises);
    const initEndTime = Date.now();
    console.log(`⏱️  Mass initialization took: ${initEndTime - initStartTime}ms`);

    // Performance Test 2: Batch size limits
    console.log("\n⚡ Test 2: Batch Size Performance");
    console.log("-".repeat(40));

    const maxBatchSize = await contract.MAX_BATCH_SIZE();
    console.log(`📊 Max batch size: ${maxBatchSize}`);

    // Test different batch sizes
    const batchSizes = [1, 5, 10, 25, 50];
    const performanceResults = [];

    for (const batchSize of batchSizes) {
      if (batchSize > users.length) continue;

      console.log(`\n🔄 Testing batch size: ${batchSize}`);
      
      const batchStartTime = Date.now();
      const transactions = [];
      const currentTime = Math.floor(Date.now() / 1000);

      // Create transactions for batch
      for (let i = 0; i < batchSize; i++) {
        const fromUser = users[i % users.length];
        const toUser = users[(i + 1) % users.length];
        
        // Ensure users have balance
        try {
          await (await contract.connect(deployer).updateBalance(fromUser.address, ethers.parseEther("100"))).wait();
        } catch (error) {
          // User might not be initialized, skip
          continue;
        }

        const txId = await contract.generateTransactionId(
          fromUser.address, 
          toUser.address, 
          i + 1, 
          currentTime + i
        );

        const tx = {
          id: txId,
          from: fromUser.address,
          to: toUser.address,
          amount: ethers.parseEther("1"),
          timestamp: currentTime + i,
          nonce: i + 1,
          signature: "0x",
          status: 0
        };

        // Create signature
        const messageHash = ethers.keccak256(ethers.solidityPacked(
          ["string", "address", "address", "uint256", "uint256", "uint256"],
          [tx.id, tx.from, tx.to, tx.amount, tx.timestamp, tx.nonce]
        ));
        tx.signature = await fromUser.signMessage(ethers.getBytes(messageHash));
        transactions.push(tx);
      }

      if (transactions.length === 0) {
        console.log("⚠️  No valid transactions created for this batch size");
        continue;
      }

      // Create batch
      const batch = {
        batchId: `perf-batch-${batchSize}-${Date.now()}`,
        submitter: users[0].address,
        transactions: transactions,
        timestamp: currentTime,
        flowUsed: ethers.parseEther((transactions.length * 0.001).toString())
      };

      // Ensure submitter has enough deposit
      const submitterDeposit = await contract.getDepositBalance(users[0].address);
      if (submitterDeposit < batch.flowUsed) {
        const additionalDeposit = ethers.parseEther("2");
        await (await contract.connect(users[0]).addFlowDeposit({ value: additionalDeposit })).wait();
      }

      try {
        // Process batch and measure time
        const batchTx = await contract.connect(users[0]).syncOfflineTransactions(batch);
        const receipt = await batchTx.wait();
        
        const batchEndTime = Date.now();
        const processingTime = batchEndTime - batchStartTime;
        const gasUsed = receipt.gasUsed;

        performanceResults.push({
          batchSize,
          processingTime,
          gasUsed: gasUsed.toString(),
          gasPerTx: (gasUsed / BigInt(batchSize)).toString()
        });

        console.log(`   ⏱️  Processing time: ${processingTime}ms`);
        console.log(`   ⛽ Gas used: ${gasUsed.toLocaleString()}`);
        console.log(`   📊 Gas per transaction: ${(gasUsed / BigInt(batchSize)).toLocaleString()}`);

      } catch (error) {
        console.log(`   ❌ Batch failed: ${error.message.slice(0, 100)}...`);
      }
    }

    // Performance Test 3: Concurrent operations
    console.log("\n⚡ Test 3: Concurrent Operations");
    console.log("-".repeat(40));

    const concurrentStartTime = Date.now();
    const concurrentPromises = [];

    // Test concurrent deposit additions
    for (let i = 0; i < Math.min(3, users.length); i++) {
      const user = users[i];
      const isActive = await contract.isUserActive(user.address);
      
      if (isActive) {
        concurrentPromises.push(
          contract.connect(user).addFlowDeposit({ value: ethers.parseEther("1") })
            .then(tx => tx.wait())
            .then(() => console.log(`✅ User${i + 1} deposit added concurrently`))
            .catch(error => console.log(`❌ User${i + 1} deposit failed: ${error.message.slice(0, 50)}...`))
        );
      }
    }

    await Promise.all(concurrentPromises);
    const concurrentEndTime = Date.now();
    console.log(`⏱️  Concurrent operations took: ${concurrentEndTime - concurrentStartTime}ms`);

    // Performance Test 4: View function performance
    console.log("\n⚡ Test 4: View Function Performance");
    console.log("-".repeat(40));

    const viewTests = [
      { name: "getBalance", fn: () => contract.getBalance(users[0].address) },
      { name: "getDepositBalance", fn: () => contract.getDepositBalance(users[0].address) },
      { name: "getUserNonce", fn: () => contract.getUserNonce(users[0].address) },
      { name: "isUserActive", fn: () => contract.isUserActive(users[0].address) },
      { name: "getUserAccount", fn: () => contract.getUserAccount(users[0].address) },
      { name: "totalUsers", fn: () => contract.totalUsers() },
      { name: "totalTransactions", fn: () => contract.totalTransactions() },
      { name: "validateNonce", fn: () => contract.validateNonce(users[0].address, 1) }
    ];

    for (const test of viewTests) {
      const startTime = Date.now();
      try {
        await test.fn();
        const endTime = Date.now();
        console.log(`✅ ${test.name}: ${endTime - startTime}ms`);
      } catch (error) {
        console.log(`❌ ${test.name}: Failed - ${error.message.slice(0, 50)}...`);
      }
    }

    // Performance Test 5: Memory usage simulation
    console.log("\n⚡ Test 5: Transaction ID Generation Performance");
    console.log("-".repeat(40));

    const idGenStartTime = Date.now();
    const generatedIds = [];

    for (let i = 0; i < 100; i++) {
      const txId = await contract.generateTransactionId(
        users[0].address,
        users[1].address,
        i,
        Math.floor(Date.now() / 1000) + i
      );
      generatedIds.push(txId);
    }

    const idGenEndTime = Date.now();
    console.log(`✅ Generated 100 transaction IDs in: ${idGenEndTime - idGenStartTime}ms`);
    console.log(`📊 Average per ID: ${(idGenEndTime - idGenStartTime) / 100}ms`);

    // Performance Summary
    console.log("\n📊 Performance Summary");
    console.log("=".repeat(50));

    console.log("\n🔄 Batch Processing Results:");
    performanceResults.forEach(result => {
      console.log(`   Batch Size ${result.batchSize}: ${result.processingTime}ms, ${parseInt(result.gasUsed).toLocaleString()} gas`);
    });

    // Find optimal batch size
    if (performanceResults.length > 0) {
      const optimal = performanceResults.reduce((best, current) => {
        const currentEfficiency = parseInt(current.gasPerTx);
        const bestEfficiency = parseInt(best.gasPerTx);
        return currentEfficiency < bestEfficiency ? current : best;
      });
      
      console.log(`\n🎯 Most gas-efficient batch size: ${optimal.batchSize} (${parseInt(optimal.gasPerTx).toLocaleString()} gas per tx)`);
    }

    // Performance recommendations
    console.log("\n💡 Performance Recommendations:");
    console.log("-".repeat(40));
    console.log("✅ Use batch sizes between 10-25 for optimal gas efficiency");
    console.log("✅ Initialize accounts in parallel when possible");
    console.log("✅ Cache view function results when appropriate");
    console.log("✅ Pre-fund deposits to avoid additional transactions");
    console.log("✅ Use proper nonce management for concurrent operations");

    console.log("\n" + "🎉".repeat(20));
    console.log("🎉 PERFORMANCE TESTING COMPLETED! 🎉");
    console.log("🎉".repeat(20));

  } catch (error) {
    console.error("\n❌ Performance test failed:");
    console.error(error);
    process.exit(1);
  }
}

main()
  .then(() => {
    console.log("\n✅ Performance testing completed!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("\n❌ Performance testing failed:");
    console.error(error);
    process.exit(1);
  });
