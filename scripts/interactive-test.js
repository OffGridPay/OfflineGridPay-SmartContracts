const { ethers } = require("hardhat");
const readline = require('readline');

// Contract address on FlowEVM testnet
const CONTRACT_ADDRESS = "0x5047983EC64EF766B6a524FA2b6E1C3f766B84D6";

// Create readline interface
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

// Utility function to ask questions
function askQuestion(question) {
  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      resolve(answer);
    });
  });
}

async function main() {
  console.log("🎮 Interactive LIN Protocol Contract Testing");
  console.log("=" .repeat(50));
  console.log(`📍 Contract Address: ${CONTRACT_ADDRESS}`);
  console.log(`🌐 Network: ${hre.network.name}`);
  
  // Get signers
  const [deployer, user1, user2, user3] = await ethers.getSigners();
  
  // Connect to contract
  const LINProtocol = await ethers.getContractFactory("offgridpay");
  const contract = LINProtocol.attach(CONTRACT_ADDRESS);
  
  console.log("\n👤 Available Test Accounts:");
  console.log(`0. Deployer: ${deployer.address}`);
  console.log(`1. User1: ${user1.address}`);
  console.log(`2. User2: ${user2.address}`);
  console.log(`3. User3: ${user3.address}`);

  let running = true;
  
  while (running) {
    console.log("\n" + "=".repeat(50));
    console.log("🎯 Choose a test to run:");
    console.log("=".repeat(50));
    console.log("1.  📊 View Contract State");
    console.log("2.  🏗️  Initialize Account");
    console.log("3.  💰 Add Flow Deposit");
    console.log("4.  💸 Withdraw Flow Deposit");
    console.log("5.  👤 View Account Details");
    console.log("6.  ⚖️  Update Account Balance (Admin)");
    console.log("7.  🔒 Deactivate Account");
    console.log("8.  🔓 Reactivate Account");
    console.log("9.  🔐 Test Signature Validation");
    console.log("10. 🔢 Test Nonce Validation");
    console.log("11. 🔄 Test Replay Protection");
    console.log("12. ⏰ Test Transaction Expiry");
    console.log("13. 🛠️  Generate Transaction ID");
    console.log("14. 📱 Create Offline Transaction");
    console.log("15. 🚨 Emergency Withdraw (Owner)");
    console.log("16. 📈 View All Account Balances");
    console.log("0.  ❌ Exit");
    
    const choice = await askQuestion("\n🎯 Enter your choice (0-16): ");
    
    try {
      switch (choice) {
        case '1':
          await viewContractState(contract);
          break;
        case '2':
          await initializeAccount(contract, [deployer, user1, user2, user3]);
          break;
        case '3':
          await addFlowDeposit(contract, [deployer, user1, user2, user3]);
          break;
        case '4':
          await withdrawFlowDeposit(contract, [deployer, user1, user2, user3]);
          break;
        case '5':
          await viewAccountDetails(contract);
          break;
        case '6':
          await updateAccountBalance(contract, deployer);
          break;
        case '7':
          await deactivateAccount(contract, [deployer, user1, user2, user3]);
          break;
        case '8':
          await reactivateAccount(contract, [deployer, user1, user2, user3]);
          break;
        case '9':
          await testSignatureValidation(contract, [deployer, user1, user2, user3]);
          break;
        case '10':
          await testNonceValidation(contract);
          break;
        case '11':
          await testReplayProtection(contract);
          break;
        case '12':
          await testTransactionExpiry(contract);
          break;
        case '13':
          await generateTransactionId(contract);
          break;
        case '14':
          await createOfflineTransaction(contract, [deployer, user1, user2, user3]);
          break;
        case '15':
          await emergencyWithdraw(contract, deployer);
          break;
        case '16':
          await viewAllBalances(contract, [deployer, user1, user2, user3]);
          break;
        case '0':
          running = false;
          break;
        default:
          console.log("❌ Invalid choice. Please try again.");
      }
    } catch (error) {
      console.error(`❌ Error: ${error.message}`);
    }
    
    if (running) {
      await askQuestion("\n⏸️  Press Enter to continue...");
    }
  }
  
  rl.close();
  console.log("\n👋 Thanks for testing! Goodbye!");
}

async function viewContractState(contract) {
  console.log("\n📊 Contract State:");
  console.log("-".repeat(30));
  
  const totalUsers = await contract.totalUsers();
  const totalTransactions = await contract.totalTransactions();
  const totalFlowDeposited = await contract.totalFlowDeposited();
  const minDeposit = await contract.MINIMUM_FLOW_DEPOSIT();
  const baseFee = await contract.BASE_TRANSACTION_FEE();
  const maxBatchSize = await contract.MAX_BATCH_SIZE();
  
  console.log(`Total Users: ${totalUsers}`);
  console.log(`Total Transactions: ${totalTransactions}`);
  console.log(`Total Flow Deposited: ${ethers.formatEther(totalFlowDeposited)} FLOW`);
  console.log(`Minimum Deposit: ${ethers.formatEther(minDeposit)} FLOW`);
  console.log(`Base Transaction Fee: ${ethers.formatEther(baseFee)} FLOW`);
  console.log(`Max Batch Size: ${maxBatchSize}`);
}

async function initializeAccount(contract, signers) {
  const userIndex = await askQuestion("👤 Select user (0-3): ");
  const user = signers[parseInt(userIndex)];
  
  if (!user) {
    console.log("❌ Invalid user selection");
    return;
  }
  
  const depositAmount = await askQuestion("💰 Enter deposit amount in FLOW (minimum 10): ");
  const deposit = ethers.parseEther(depositAmount);
  
  console.log(`🏗️  Initializing account for ${user.address}...`);
  const tx = await contract.connect(user).initializeAccount({ value: deposit });
  console.log(`⏳ Transaction sent: ${tx.hash}`);
  
  await tx.wait();
  console.log("✅ Account initialized successfully!");
}

async function addFlowDeposit(contract, signers) {
  const userIndex = await askQuestion("👤 Select user (0-3): ");
  const user = signers[parseInt(userIndex)];
  
  if (!user) {
    console.log("❌ Invalid user selection");
    return;
  }
  
  const depositAmount = await askQuestion("💰 Enter additional deposit amount in FLOW: ");
  const deposit = ethers.parseEther(depositAmount);
  
  console.log(`💰 Adding ${depositAmount} FLOW deposit for ${user.address}...`);
  const tx = await contract.connect(user).addFlowDeposit({ value: deposit });
  console.log(`⏳ Transaction sent: ${tx.hash}`);
  
  await tx.wait();
  console.log("✅ Deposit added successfully!");
}

async function withdrawFlowDeposit(contract, signers) {
  const userIndex = await askQuestion("👤 Select user (0-3): ");
  const user = signers[parseInt(userIndex)];
  
  if (!user) {
    console.log("❌ Invalid user selection");
    return;
  }
  
  const withdrawAmount = await askQuestion("💸 Enter withdrawal amount in FLOW: ");
  const amount = ethers.parseEther(withdrawAmount);
  
  console.log(`💸 Withdrawing ${withdrawAmount} FLOW for ${user.address}...`);
  const tx = await contract.connect(user).withdrawFlowDeposit(amount);
  console.log(`⏳ Transaction sent: ${tx.hash}`);
  
  await tx.wait();
  console.log("✅ Withdrawal successful!");
}

async function viewAccountDetails(contract) {
  const address = await askQuestion("📍 Enter account address: ");
  
  try {
    const account = await contract.getUserAccount(address);
    const balance = await contract.getBalance(address);
    const depositBalance = await contract.getDepositBalance(address);
    const nonce = await contract.getUserNonce(address);
    const isActive = await contract.isUserActive(address);
    
    console.log(`\n👤 Account Details for ${address}:`);
    console.log("-".repeat(50));
    console.log(`Balance: ${ethers.formatEther(balance)} FLOW`);
    console.log(`Deposit: ${ethers.formatEther(depositBalance)} FLOW`);
    console.log(`Nonce: ${nonce}`);
    console.log(`Active: ${isActive}`);
    console.log(`Last Sync: ${new Date(Number(account.lastSyncTime) * 1000).toLocaleString()}`);
  } catch (error) {
    console.log("❌ Account not found or error occurred");
  }
}

async function updateAccountBalance(contract, deployer) {
  const address = await askQuestion("📍 Enter account address: ");
  const newBalance = await askQuestion("💰 Enter new balance in FLOW: ");
  const balance = ethers.parseEther(newBalance);
  
  console.log(`⚖️  Updating balance for ${address}...`);
  const tx = await contract.connect(deployer).updateBalance(address, balance);
  console.log(`⏳ Transaction sent: ${tx.hash}`);
  
  await tx.wait();
  console.log("✅ Balance updated successfully!");
}

async function deactivateAccount(contract, signers) {
  const userIndex = await askQuestion("👤 Select user (0-3): ");
  const user = signers[parseInt(userIndex)];
  
  if (!user) {
    console.log("❌ Invalid user selection");
    return;
  }
  
  console.log(`🔒 Deactivating account for ${user.address}...`);
  const tx = await contract.connect(user).deactivateAccount();
  console.log(`⏳ Transaction sent: ${tx.hash}`);
  
  await tx.wait();
  console.log("✅ Account deactivated successfully!");
}

async function reactivateAccount(contract, signers) {
  const userIndex = await askQuestion("👤 Select user (0-3): ");
  const user = signers[parseInt(userIndex)];
  
  if (!user) {
    console.log("❌ Invalid user selection");
    return;
  }
  
  console.log(`🔓 Reactivating account for ${user.address}...`);
  const tx = await contract.connect(user).reactivateAccount();
  console.log(`⏳ Transaction sent: ${tx.hash}`);
  
  await tx.wait();
  console.log("✅ Account reactivated successfully!");
}

async function testSignatureValidation(contract, signers) {
  const userIndex = await askQuestion("👤 Select user for signing (0-3): ");
  const user = signers[parseInt(userIndex)];
  
  if (!user) {
    console.log("❌ Invalid user selection");
    return;
  }
  
  const toAddress = await askQuestion("📍 Enter recipient address: ");
  const amount = await askQuestion("💰 Enter amount in FLOW: ");
  const currentTime = Math.floor(Date.now() / 1000);
  
  const txId = await contract.generateTransactionId(user.address, toAddress, 1, currentTime);
  
  const offlineTransaction = {
    id: txId,
    from: user.address,
    to: toAddress,
    amount: ethers.parseEther(amount),
    timestamp: currentTime,
    nonce: 1,
    signature: "0x",
    status: 0
  };
  
  // Create signature
  const messageHash = ethers.keccak256(ethers.solidityPacked(
    ["string", "address", "address", "uint256", "uint256", "uint256"],
    [offlineTransaction.id, offlineTransaction.from, offlineTransaction.to, 
     offlineTransaction.amount, offlineTransaction.timestamp, offlineTransaction.nonce]
  ));
  
  const signature = await user.signMessage(ethers.getBytes(messageHash));
  offlineTransaction.signature = signature;
  
  console.log("🔐 Testing signature validation...");
  try {
    const isValid = await contract.validateSignature(offlineTransaction);
    console.log(`✅ Signature validation result: ${isValid}`);
  } catch (error) {
    console.log(`⚠️  Signature validation error: ${error.message}`);
  }
}

async function testNonceValidation(contract) {
  const address = await askQuestion("📍 Enter account address: ");
  const nonce = await askQuestion("🔢 Enter nonce to test: ");
  
  const isValid = await contract.validateNonce(address, parseInt(nonce));
  console.log(`✅ Nonce ${nonce} validation result: ${isValid}`);
}

async function testReplayProtection(contract) {
  const txId = await askQuestion("🔄 Enter transaction ID to test: ");
  
  const canProcess = await contract.preventReplay(txId);
  console.log(`✅ Transaction ${txId} can be processed: ${canProcess}`);
}

async function testTransactionExpiry(contract) {
  const timestamp = await askQuestion("⏰ Enter timestamp to test (Unix timestamp): ");
  
  const isExpired = await contract.isTransactionExpired(parseInt(timestamp));
  console.log(`✅ Transaction with timestamp ${timestamp} is expired: ${isExpired}`);
}

async function generateTransactionId(contract) {
  const fromAddress = await askQuestion("📍 Enter from address: ");
  const toAddress = await askQuestion("📍 Enter to address: ");
  const nonce = await askQuestion("🔢 Enter nonce: ");
  const timestamp = await askQuestion("⏰ Enter timestamp (or press Enter for current): ");
  
  const finalTimestamp = timestamp || Math.floor(Date.now() / 1000);
  
  const txId = await contract.generateTransactionId(
    fromAddress, 
    toAddress, 
    parseInt(nonce), 
    parseInt(finalTimestamp)
  );
  
  console.log(`✅ Generated Transaction ID: ${txId}`);
}

async function createOfflineTransaction(contract, signers) {
  const userIndex = await askQuestion("👤 Select user for signing (0-3): ");
  const user = signers[parseInt(userIndex)];
  
  if (!user) {
    console.log("❌ Invalid user selection");
    return;
  }
  
  const toAddress = await askQuestion("📍 Enter recipient address: ");
  const amount = await askQuestion("💰 Enter amount in FLOW: ");
  const currentTime = Math.floor(Date.now() / 1000);
  
  const txId = await contract.generateTransactionId(user.address, toAddress, 1, currentTime);
  
  const offlineTransaction = {
    id: txId,
    from: user.address,
    to: toAddress,
    amount: ethers.parseEther(amount),
    timestamp: currentTime,
    nonce: 1,
    signature: "0x",
    status: 0
  };
  
  // Create signature
  const messageHash = ethers.keccak256(ethers.solidityPacked(
    ["string", "address", "address", "uint256", "uint256", "uint256"],
    [offlineTransaction.id, offlineTransaction.from, offlineTransaction.to, 
     offlineTransaction.amount, offlineTransaction.timestamp, offlineTransaction.nonce]
  ));
  
  const signature = await user.signMessage(ethers.getBytes(messageHash));
  offlineTransaction.signature = signature;
  
  console.log("\n📱 Created Offline Transaction:");
  console.log("-".repeat(40));
  console.log(`ID: ${offlineTransaction.id}`);
  console.log(`From: ${offlineTransaction.from}`);
  console.log(`To: ${offlineTransaction.to}`);
  console.log(`Amount: ${ethers.formatEther(offlineTransaction.amount)} FLOW`);
  console.log(`Timestamp: ${new Date(offlineTransaction.timestamp * 1000).toLocaleString()}`);
  console.log(`Nonce: ${offlineTransaction.nonce}`);
  console.log(`Signature: ${offlineTransaction.signature.slice(0, 20)}...`);
}

async function emergencyWithdraw(contract, deployer) {
  const contractBalance = await ethers.provider.getBalance(CONTRACT_ADDRESS);
  console.log(`💰 Current contract balance: ${ethers.formatEther(contractBalance)} FLOW`);
  
  if (contractBalance > 0) {
    const confirm = await askQuestion("🚨 Are you sure you want to withdraw all funds? (yes/no): ");
    if (confirm.toLowerCase() === 'yes') {
      console.log("🚨 Executing emergency withdraw...");
      const tx = await contract.connect(deployer).emergencyWithdraw();
      console.log(`⏳ Transaction sent: ${tx.hash}`);
      
      await tx.wait();
      console.log("✅ Emergency withdraw successful!");
    } else {
      console.log("❌ Emergency withdraw cancelled");
    }
  } else {
    console.log("ℹ️  No funds to withdraw");
  }
}

async function viewAllBalances(contract, signers) {
  console.log("\n📈 All Account Balances:");
  console.log("-".repeat(60));
  
  for (let i = 0; i < signers.length; i++) {
    const address = signers[i].address;
    try {
      const balance = await contract.getBalance(address);
      const deposit = await contract.getDepositBalance(address);
      const isActive = await contract.isUserActive(address);
      
      console.log(`${i}. ${address}`);
      console.log(`   Balance: ${ethers.formatEther(balance)} FLOW`);
      console.log(`   Deposit: ${ethers.formatEther(deposit)} FLOW`);
      console.log(`   Active: ${isActive}`);
      console.log("");
    } catch (error) {
      console.log(`${i}. ${address} - Not initialized`);
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
