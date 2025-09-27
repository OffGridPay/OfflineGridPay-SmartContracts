const { ethers } = require("hardhat");

async function main() {
  // FlowEVM testnet PYUSD token address
  const PYUSD_TOKEN_ADDRESS = "0xd7d43ab7b365f0d0789aE83F4385fA710FfdC98F";
  
  // Your newly deployed multi-token contract address
  const CONTRACT_ADDRESS = "0x198DD9d62c751937f0DF86c0e451F753858358f3";

  console.log("Setting PYUSD token address on OffGridPay contract...");
  console.log("Contract Address:", CONTRACT_ADDRESS);
  console.log("PYUSD Token Address:", PYUSD_TOKEN_ADDRESS);

  // Get the contract instance
  const OffGridPay = await ethers.getContractFactory("offgridpay");
  const contract = OffGridPay.attach(CONTRACT_ADDRESS);

  // Get the signer (contract owner)
  const [owner] = await ethers.getSigners();
  console.log("Setting PYUSD token with owner address:", owner.address);

  try {
    // Set the PYUSD token address
    const tx = await contract.connect(owner).setPyusdToken(PYUSD_TOKEN_ADDRESS);
    console.log("Transaction submitted:", tx.hash);
    
    // Wait for confirmation
    const receipt = await tx.wait();
    console.log("✅ PYUSD token address set successfully!");
    console.log("Transaction confirmed in block:", receipt.blockNumber);
    console.log("Gas used:", receipt.gasUsed.toString());

    // Verify the setting
    const setPyusdAddress = await contract.pyusdToken();
    console.log("Verified PYUSD token address:", setPyusdAddress);
    
    if (setPyusdAddress.toLowerCase() === PYUSD_TOKEN_ADDRESS.toLowerCase()) {
      console.log("✅ PYUSD token address verification successful!");
      console.log("\n🎉 Your OffGridPay contract now supports both FLOW and PYUSD tokens!");
      console.log("\nNext steps:");
      console.log("1. Update your frontend to handle both token types");
      console.log("2. Test with small amounts first");
      console.log("3. Users can now initialize accounts with PYUSD tokens");
    } else {
      console.log("❌ PYUSD token address verification failed!");
    }

  } catch (error) {
    console.error("❌ Error setting PYUSD token address:", error.message);
    
    if (error.message.includes("Ownable: caller is not the owner")) {
      console.log("\n💡 Make sure you're using the correct private key for the contract owner.");
      console.log("The contract owner should be: 0xC961A88C4307d5BfBE6295faeFaCbb2EBD5A83dC");
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
