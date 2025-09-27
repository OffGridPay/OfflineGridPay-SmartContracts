const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("offgridpay", function () {
  let linProtocol;
  let owner;
  let user1;
  let user2;
  let user3;

  const MINIMUM_DEPOSIT = ethers.parseEther("10");
  const BASE_FEE = ethers.parseEther("0.001");

  beforeEach(async function () {
    [owner, user1, user2, user3] = await ethers.getSigners();

    const offgridpay = await ethers.getContractFactory("offgridpay");
    linProtocol = await offgridpay.deploy();
    await linProtocol.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should deploy with correct initial values", async function () {
      expect(await linProtocol.totalUsers()).to.equal(0);
      expect(await linProtocol.totalTransactions()).to.equal(0);
      expect(await linProtocol.totalFlowDeposited()).to.equal(0);
      expect(await linProtocol.MINIMUM_FLOW_DEPOSIT()).to.equal(MINIMUM_DEPOSIT);
    });

    it("Should set the correct owner", async function () {
      expect(await linProtocol.owner()).to.equal(owner.address);
    });
  });

  describe("Account Initialization", function () {
    it("Should initialize account with sufficient deposit", async function () {
      const depositAmount = ethers.parseEther("15");
      
      await expect(linProtocol.connect(user1).initializeAccount({ value: depositAmount }))
        .to.emit(linProtocol, "AccountInitialized")
        .withArgs(user1.address, depositAmount);

      const account = await linProtocol.getUserAccount(user1.address);
      expect(account.balance).to.equal(0);
      expect(account.flowDeposit).to.equal(depositAmount);
      expect(account.nonce).to.equal(0);
      expect(account.isActive).to.be.true;

      expect(await linProtocol.totalUsers()).to.equal(1);
      expect(await linProtocol.totalFlowDeposited()).to.equal(depositAmount);
    });

    it("Should reject initialization with insufficient deposit", async function () {
      const insufficientDeposit = ethers.parseEther("5");
      
      await expect(
        linProtocol.connect(user1).initializeAccount({ value: insufficientDeposit })
      ).to.be.revertedWith("INSUFFICIENT_DEPOSIT");
    });

    it("Should reject duplicate account initialization", async function () {
      const depositAmount = ethers.parseEther("15");
      
      await linProtocol.connect(user1).initializeAccount({ value: depositAmount });
      
      await expect(
        linProtocol.connect(user1).initializeAccount({ value: depositAmount })
      ).to.be.revertedWith("Account already initialized");
    });
  });

  describe("Flow Deposit Management", function () {
    beforeEach(async function () {
      await linProtocol.connect(user1).initializeAccount({ value: MINIMUM_DEPOSIT });
    });

    it("Should allow adding Flow deposit", async function () {
      const additionalDeposit = ethers.parseEther("5");
      
      await expect(linProtocol.connect(user1).addFlowDeposit({ value: additionalDeposit }))
        .to.emit(linProtocol, "FlowDepositAdded")
        .withArgs(user1.address, additionalDeposit);

      const account = await linProtocol.getUserAccount(user1.address);
      expect(account.flowDeposit).to.equal(MINIMUM_DEPOSIT + additionalDeposit);
    });

    it("Should allow withdrawing Flow deposit", async function () {
      const withdrawAmount = ethers.parseEther("5");
      
      await expect(linProtocol.connect(user1).withdrawFlowDeposit(withdrawAmount))
        .to.emit(linProtocol, "FlowDepositWithdrawn")
        .withArgs(user1.address, withdrawAmount);

      const account = await linProtocol.getUserAccount(user1.address);
      expect(account.flowDeposit).to.equal(MINIMUM_DEPOSIT - withdrawAmount);
    });

    it("Should reject withdrawal of insufficient deposit", async function () {
      const excessiveAmount = ethers.parseEther("15");
      
      await expect(
        linProtocol.connect(user1).withdrawFlowDeposit(excessiveAmount)
      ).to.be.revertedWith("Insufficient deposit balance");
    });
  });

  describe("Account Management", function () {
    beforeEach(async function () {
      await linProtocol.connect(user1).initializeAccount({ value: MINIMUM_DEPOSIT });
    });

    it("Should allow account deactivation", async function () {
      await expect(linProtocol.connect(user1).deactivateAccount())
        .to.emit(linProtocol, "AccountDeactivated")
        .withArgs(user1.address);

      expect(await linProtocol.isUserActive(user1.address)).to.be.false;
    });

    it("Should allow account reactivation", async function () {
      await linProtocol.connect(user1).deactivateAccount();
      
      await expect(linProtocol.connect(user1).reactivateAccount())
        .to.emit(linProtocol, "AccountReactivated")
        .withArgs(user1.address);

      expect(await linProtocol.isUserActive(user1.address)).to.be.true;
    });
  });

  describe("Transaction Validation", function () {
    let sampleTransaction;

    beforeEach(async function () {
      await linProtocol.connect(user1).initializeAccount({ value: MINIMUM_DEPOSIT });
      await linProtocol.connect(user2).initializeAccount({ value: MINIMUM_DEPOSIT });
      
      // Set initial balances for testing
      await linProtocol.connect(owner).updateBalance(user1.address, ethers.parseEther("100"));

      sampleTransaction = {
        id: "test-tx-1",
        from: user1.address,
        to: user2.address,
        amount: ethers.parseEther("10"),
        timestamp: Math.floor(Date.now() / 1000),
        nonce: 1,
        signature: "0x", // Will be set in individual tests
        status: 0 // Pending
      };
    });

    it("Should validate nonce correctly", async function () {
      expect(await linProtocol.validateNonce(user1.address, 1)).to.be.true;
      expect(await linProtocol.validateNonce(user1.address, 0)).to.be.false;
      expect(await linProtocol.validateNonce(user1.address, 12)).to.be.false; // Beyond MAX_NONCE_SKIP
    });

    it("Should detect replay attacks", async function () {
      const txId = "unique-tx-id";
      expect(await linProtocol.preventReplay(txId)).to.be.true;
      
      // Simulate processing the transaction
      await linProtocol.connect(owner).updateBalance(user1.address, ethers.parseEther("100"));
      
      // After processing, it should be detected as replay
      // Note: This would be set internally during actual transaction processing
    });

    it("Should detect expired transactions", async function () {
      const expiredTimestamp = Math.floor(Date.now() / 1000) - 86401; // 1 day + 1 second ago
      expect(await linProtocol.isTransactionExpired(expiredTimestamp)).to.be.true;
      
      const validTimestamp = Math.floor(Date.now() / 1000);
      expect(await linProtocol.isTransactionExpired(validTimestamp)).to.be.false;
    });
  });

  describe("Utility Functions", function () {
    it("Should generate transaction ID correctly", async function () {
      const txId = await linProtocol.generateTransactionId(
        user1.address,
        user2.address,
        1,
        1234567890
      );
      
      expect(txId).to.include(user1.address.toLowerCase().slice(2));
      expect(txId).to.include(user2.address.toLowerCase().slice(2));
      expect(txId).to.include("1");
      expect(txId).to.include("1234567890");
    });
  });

  describe("View Functions", function () {
    beforeEach(async function () {
      await linProtocol.connect(user1).initializeAccount({ value: MINIMUM_DEPOSIT });
      await linProtocol.connect(owner).updateBalance(user1.address, ethers.parseEther("50"));
    });

    it("Should return correct balance", async function () {
      expect(await linProtocol.getBalance(user1.address)).to.equal(ethers.parseEther("50"));
    });

    it("Should return correct deposit balance", async function () {
      expect(await linProtocol.getDepositBalance(user1.address)).to.equal(MINIMUM_DEPOSIT);
    });

    it("Should return correct nonce", async function () {
      expect(await linProtocol.getUserNonce(user1.address)).to.equal(0);
    });

    it("Should return correct active status", async function () {
      expect(await linProtocol.isUserActive(user1.address)).to.be.true;
    });
  });

  describe("Emergency Functions", function () {
    it("Should allow owner to emergency withdraw", async function () {
      // Add some ETH to the contract
      await user1.sendTransaction({
        to: await linProtocol.getAddress(),
        value: ethers.parseEther("1")
      });

      const initialOwnerBalance = await ethers.provider.getBalance(owner.address);
      
      await linProtocol.connect(owner).emergencyWithdraw();
      
      const finalOwnerBalance = await ethers.provider.getBalance(owner.address);
      expect(finalOwnerBalance).to.be.gt(initialOwnerBalance);
    });

    it("Should reject emergency withdraw from non-owner", async function () {
      await expect(
        linProtocol.connect(user1).emergencyWithdraw()
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });
});
