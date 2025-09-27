const { ethers } = require("hardhat");

async function main() {
  console.log("🚀 Starting offgridpay deployment...");

  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("📝 Deploying contracts with account:", deployer.address);

  // Check deployer balance
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("💰 Account balance:", ethers.formatEther(balance), "FLOW");

  if (balance < ethers.parseEther("0.1")) {
    console.warn("⚠️  Warning: Low balance. Make sure you have enough FLOW for deployment.");
  }

  // Deploy offgridpay contract
  console.log("\n📦 Deploying offgridpay contract...");
  
  const offgridpay = await ethers.getContractFactory("offgridpay");
  const linProtocol = await offgridpay.deploy();
  
  await linProtocol.waitForDeployment();
  const contractAddress = await linProtocol.getAddress();

  console.log("✅ offgridpay deployed to:", contractAddress);

  // Verify deployment by calling a view function
  try {
    const totalUsers = await linProtocol.totalUsers();
    console.log("🔍 Contract verification - Total users:", totalUsers.toString());
    
    const minimumDeposit = await linProtocol.MINIMUM_FLOW_DEPOSIT();
    console.log("🔍 Contract verification - Minimum deposit:", ethers.formatEther(minimumDeposit), "FLOW");
  } catch (error) {
    console.error("❌ Contract verification failed:", error.message);
  }

  // Save deployment information
  const deploymentInfo = {
    network: hre.network.name,
    contractAddress: contractAddress,
    deployer: deployer.address,
    deploymentTime: new Date().toISOString(),
    transactionHash: linProtocol.deploymentTransaction()?.hash,
    blockNumber: linProtocol.deploymentTransaction()?.blockNumber,
  };

  console.log("\n📋 Deployment Summary:");
  console.log("=".repeat(50));
  console.log(`Network: ${deploymentInfo.network}`);
  console.log(`Contract Address: ${deploymentInfo.contractAddress}`);
  console.log(`Deployer: ${deploymentInfo.deployer}`);
  console.log(`Deployment Time: ${deploymentInfo.deploymentTime}`);
  console.log(`Transaction Hash: ${deploymentInfo.transactionHash}`);
  console.log("=".repeat(50));

  // Instructions for users
  console.log("\n🎉 Deployment completed successfully!");
  console.log("\n📚 Next Steps:");
  console.log("1. Save the contract address for your frontend integration");
  console.log("2. Verify the contract on FlowScan (optional):");
  console.log(`   npx hardhat verify --network ${hre.network.name} ${contractAddress}`);
  console.log("3. Test the contract functionality");
  console.log("4. Update your frontend configuration with the new contract address");

  console.log("\n🔗 Useful Links:");
  if (hre.network.name === "flowTestnet") {
    console.log(`FlowScan (Testnet): https://evm-testnet.flowscan.org/address/${contractAddress}`);
    console.log("Faucet: https://testnet-faucet.onflow.org/fund-account");
  } else if (hre.network.name === "flowMainnet") {
    console.log(`FlowScan (Mainnet): https://evm.flowscan.org/address/${contractAddress}`);
  }

  return deploymentInfo;
}

// Execute deployment
main()
  .then((deploymentInfo) => {
    console.log("\n✅ All done!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("\n❌ Deployment failed:");
    console.error(error);
    process.exit(1);
  });
