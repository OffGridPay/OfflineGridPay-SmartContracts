const { ethers } = require("hardhat");

async function main() {
  const CONTRACT_ADDRESS = "0xdA3Db417CEF41d8289df2db62d4752801D1dcb42";
  const TESTNET_PYUSD_ADDRESS = "0xd7d43ab7b365f0d0789aE83F4385fA710FfdC98F";

  console.log("Checking OffGridPay contract state...");
  console.log("Contract Address:", CONTRACT_ADDRESS);

  try {
    // Get the contract instance
    const OffGridPay = await ethers.getContractFactory("offgridpay");
    const contract = OffGridPay.attach(CONTRACT_ADDRESS);

    // Get current signer
    const [signer] = await ethers.getSigners();
    console.log("Current signer:", signer.address);

    // Check contract owner
    const owner = await contract.owner();
    console.log("Contract owner:", owner);
    console.log("Is signer the owner?", signer.address.toLowerCase() === owner.toLowerCase());

    // Check current PYUSD token address
    const currentPyusdToken = await contract.pyusdToken();
    console.log("Current PYUSD token address:", currentPyusdToken);
    console.log("Is PYUSD token set?", currentPyusdToken !== "0x0000000000000000000000000000000000000000");

    // Check if we need to set the PYUSD token
    if (currentPyusdToken.toLowerCase() === TESTNET_PYUSD_ADDRESS.toLowerCase()) {
      console.log("✅ PYUSD token is already set to the correct testnet address!");
    } else if (currentPyusdToken === "0x0000000000000000000000000000000000000000") {
      console.log("⚠️  PYUSD token is not set. Need to set it.");
    } else {
      console.log("⚠️  PYUSD token is set to a different address:", currentPyusdToken);
      console.log("Expected:", TESTNET_PYUSD_ADDRESS);
    }

    // Check contract constants
    console.log("\nContract Constants:");
    console.log("MINIMUM_FLOW_DEPOSIT:", ethers.formatEther(await contract.MINIMUM_FLOW_DEPOSIT()));
    console.log("MINIMUM_PYUSD_DEPOSIT:", (await contract.MINIMUM_PYUSD_DEPOSIT()).toString());

    // Check contract statistics
    console.log("\nContract Statistics:");
    console.log("Total Users:", (await contract.totalUsers()).toString());
    console.log("Total Transactions:", (await contract.totalTransactions()).toString());
    console.log("Total FLOW Deposited:", ethers.formatEther(await contract.totalFlowDeposited()));
    console.log("Total PYUSD Deposited:", (await contract.totalPyusdDeposited()).toString());

  } catch (error) {
    console.error("❌ Error checking contract state:", error.message);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
