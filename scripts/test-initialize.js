const { ethers } = require("hardhat");

const CONTRACT_ADDRESS = "0x5047983EC64EF766B6a524FA2b6E1C3f766B84D6";

async function main() {
  console.log("🧪 Testing initializeAccount with proper value...");
  
  const [deployer] = await ethers.getSigners();
  console.log(`👤 Using account: ${deployer.address}`);
  
  // Connect to contract
  const contract = await ethers.getContractAt("offgridpay", CONTRACT_ADDRESS);
  
  // Check minimum deposit requirement
  const minDeposit = await contract.MINIMUM_FLOW_DEPOSIT();
  console.log(`💰 Minimum deposit required: ${ethers.formatEther(minDeposit)} FLOW`);
  
  // Check if account is already initialized
  const isActive = await contract.isUserActive(deployer.address);
  console.log(`📊 Account already initialized: ${isActive}`);
  
  if (isActive) {
    console.log("✅ Account already initialized! Showing current details:");
    const account = await contract.getUserAccount(deployer.address);
    console.log(`   Balance: ${ethers.formatEther(account.balance)} FLOW`);
    console.log(`   Deposit: ${ethers.formatEther(account.flowDeposit)} FLOW`);
    console.log(`   Nonce: ${account.nonce}`);
    console.log(`   Active: ${account.isActive}`);
    return;
  }
  
  // Check deployer balance
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log(`💳 Your balance: ${ethers.formatEther(balance)} FLOW`);
  
  if (balance < ethers.parseEther("20")) {
    console.log("❌ Insufficient balance! You need at least 20 FLOW to test.");
    console.log("🔗 Get testnet FLOW from: https://testnet-faucet.onflow.org/fund-account");
    return;
  }
  
  try {
    console.log("🚀 Attempting to initialize account with 20 FLOW...");
    
    // This is the CORRECT way to send 20 FLOW
    const tx = await contract.initializeAccount({ 
      value: ethers.parseEther("20") // This converts 20 to 20000000000000000000 wei
    });
    
    console.log(`⏳ Transaction sent: ${tx.hash}`);
    console.log("⏳ Waiting for confirmation...");
    
    const receipt = await tx.wait();
    console.log("✅ Transaction confirmed!");
    
    // Check the account details
    const account = await contract.getUserAccount(deployer.address);
    console.log("\n📊 Account initialized successfully:");
    console.log(`   Balance: ${ethers.formatEther(account.balance)} FLOW`);
    console.log(`   Deposit: ${ethers.formatEther(account.flowDeposit)} FLOW`);
    console.log(`   Nonce: ${account.nonce}`);
    console.log(`   Active: ${account.isActive}`);
    
    // Check contract stats
    const totalUsers = await contract.totalUsers();
    const totalDeposited = await contract.totalFlowDeposited();
    console.log(`\n📈 Contract stats:`);
    console.log(`   Total users: ${totalUsers}`);
    console.log(`   Total deposited: ${ethers.formatEther(totalDeposited)} FLOW`);
    
  } catch (error) {
    console.error("❌ Transaction failed:");
    console.error(`   Error: ${error.message}`);
    
    if (error.message.includes("INSUFFICIENT_DEPOSIT")) {
      console.log("\n💡 This means the value sent was less than 10 FLOW");
      console.log("   Make sure you're using: ethers.parseEther('20')");
      console.log("   NOT just: 20");
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
