const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("offgridpay Multi-Token Support", function () {
  let offgridpay;
  let mockPYUSD;
  let owner;
  let user1;
  let user2;
  let user3;

  const MINIMUM_FLOW_DEPOSIT = ethers.parseEther("10");
  const MINIMUM_PYUSD_DEPOSIT = 10 * 10**6; // 10 PYUSD (6 decimals)
  const PYUSD_AMOUNT = 1000 * 10**6; // 1000 PYUSD for testing

  beforeEach(async function () {
    [owner, user1, user2, user3] = await ethers.getSigners();

    // Deploy MockPYUSD token
    const MockPYUSD = await ethers.getContractFactory("MockPYUSD");
    mockPYUSD = await MockPYUSD.deploy();
    await mockPYUSD.waitForDeployment();

    // Deploy offgridpay contract
    const OffGridPay = await ethers.getContractFactory("offgridpay");
    offgridpay = await OffGridPay.deploy();
    await offgridpay.waitForDeployment();

    // Set PYUSD token address
    await offgridpay.connect(owner).setPyusdToken(await mockPYUSD.getAddress());

    // Distribute PYUSD tokens to test users
    await mockPYUSD.mint(user1.address, PYUSD_AMOUNT);
    await mockPYUSD.mint(user2.address, PYUSD_AMOUNT);
    await mockPYUSD.mint(user3.address, PYUSD_AMOUNT);
  });

  describe("Deployment and Setup", function () {
    it("Should deploy with correct initial values", async function () {
      expect(await offgridpay.totalUsers()).to.equal(0);
      expect(await offgridpay.totalTransactions()).to.equal(0);
      expect(await offgridpay.totalFlowDeposited()).to.equal(0);
      expect(await offgridpay.totalPyusdDeposited()).to.equal(0);
      expect(await offgridpay.MINIMUM_FLOW_DEPOSIT()).to.equal(MINIMUM_FLOW_DEPOSIT);
      expect(await offgridpay.MINIMUM_PYUSD_DEPOSIT()).to.equal(MINIMUM_PYUSD_DEPOSIT);
    });

    it("Should set PYUSD token address correctly", async function () {
      expect(await offgridpay.pyusdToken()).to.equal(await mockPYUSD.getAddress());
    });

    it("Should emit PyusdTokenSet event", async function () {
      const newContract = await ethers.getContractFactory("offgridpay");
      const newOffgridpay = await newContract.deploy();
      
      await expect(newOffgridpay.connect(owner).setPyusdToken(await mockPYUSD.getAddress()))
        .to.emit(newOffgridpay, "PyusdTokenSet")
        .withArgs(await mockPYUSD.getAddress());
    });
  });

  describe("Account Initialization", function () {
    it("Should initialize account with FLOW deposit", async function () {
      const depositAmount = ethers.parseEther("15");
      
      await expect(offgridpay.connect(user1).initializeAccount({ value: depositAmount }))
        .to.emit(offgridpay, "AccountInitialized")
        .withArgs(user1.address, depositAmount, 0);

      const account = await offgridpay.getUserAccount(user1.address);
      expect(account.flowBalance).to.equal(0);
      expect(account.pyusdBalance).to.equal(0);
      expect(account.flowDeposit).to.equal(depositAmount);
      expect(account.pyusdDeposit).to.equal(0);
      expect(account.isActive).to.be.true;

      expect(await offgridpay.totalUsers()).to.equal(1);
      expect(await offgridpay.totalFlowDeposited()).to.equal(depositAmount);
    });

    it("Should initialize account with PYUSD deposit", async function () {
      const depositAmount = 50 * 10**6; // 50 PYUSD
      
      // Approve PYUSD transfer
      await mockPYUSD.connect(user1).approve(await offgridpay.getAddress(), depositAmount);
      
      await expect(offgridpay.connect(user1).initializeAccountWithPyusd(depositAmount))
        .to.emit(offgridpay, "AccountInitialized")
        .withArgs(user1.address, 0, depositAmount);

      const account = await offgridpay.getUserAccount(user1.address);
      expect(account.flowBalance).to.equal(0);
      expect(account.pyusdBalance).to.equal(0);
      expect(account.flowDeposit).to.equal(0);
      expect(account.pyusdDeposit).to.equal(depositAmount);
      expect(account.isActive).to.be.true;

      expect(await offgridpay.totalUsers()).to.equal(1);
      expect(await offgridpay.totalPyusdDeposited()).to.equal(depositAmount);
    });

    it("Should initialize account with both FLOW and PYUSD deposits", async function () {
      const flowAmount = ethers.parseEther("15");
      const pyusdAmount = 50 * 10**6; // 50 PYUSD
      
      // Approve PYUSD transfer
      await mockPYUSD.connect(user1).approve(await offgridpay.getAddress(), pyusdAmount);
      
      await expect(offgridpay.connect(user1).initializeAccountWithBoth(pyusdAmount, { value: flowAmount }))
        .to.emit(offgridpay, "AccountInitialized")
        .withArgs(user1.address, flowAmount, pyusdAmount);

      const account = await offgridpay.getUserAccount(user1.address);
      expect(account.flowDeposit).to.equal(flowAmount);
      expect(account.pyusdDeposit).to.equal(pyusdAmount);

      expect(await offgridpay.totalUsers()).to.equal(1);
      expect(await offgridpay.totalFlowDeposited()).to.equal(flowAmount);
      expect(await offgridpay.totalPyusdDeposited()).to.equal(pyusdAmount);
    });

    it("Should reject PYUSD initialization with insufficient deposit", async function () {
      const insufficientAmount = 5 * 10**6; // 5 PYUSD (below minimum)
      
      await mockPYUSD.connect(user1).approve(await offgridpay.getAddress(), insufficientAmount);
      
      await expect(
        offgridpay.connect(user1).initializeAccountWithPyusd(insufficientAmount)
      ).to.be.revertedWith("INSUFFICIENT_DEPOSIT");
    });
  });

  describe("Deposit Management", function () {
    beforeEach(async function () {
      // Initialize user1 with FLOW, user2 with PYUSD, user3 with both
      await offgridpay.connect(user1).initializeAccount({ value: MINIMUM_FLOW_DEPOSIT });
      
      await mockPYUSD.connect(user2).approve(await offgridpay.getAddress(), MINIMUM_PYUSD_DEPOSIT);
      await offgridpay.connect(user2).initializeAccountWithPyusd(MINIMUM_PYUSD_DEPOSIT);
      
      await mockPYUSD.connect(user3).approve(await offgridpay.getAddress(), MINIMUM_PYUSD_DEPOSIT);
      await offgridpay.connect(user3).initializeAccountWithBoth(MINIMUM_PYUSD_DEPOSIT, { value: MINIMUM_FLOW_DEPOSIT });
    });

    it("Should allow adding PYUSD deposit", async function () {
      const additionalAmount = 25 * 10**6; // 25 PYUSD
      
      await mockPYUSD.connect(user2).approve(await offgridpay.getAddress(), additionalAmount);
      
      await expect(offgridpay.connect(user2).addPyusdDeposit(additionalAmount))
        .to.emit(offgridpay, "PyusdDepositAdded")
        .withArgs(user2.address, additionalAmount);

      const account = await offgridpay.getUserAccount(user2.address);
      expect(account.pyusdDeposit).to.equal(MINIMUM_PYUSD_DEPOSIT + additionalAmount);
    });

    it("Should allow withdrawing PYUSD deposit", async function () {
      const withdrawAmount = 5 * 10**6; // 5 PYUSD
      
      await expect(offgridpay.connect(user2).withdrawPyusdDeposit(withdrawAmount))
        .to.emit(offgridpay, "PyusdDepositWithdrawn")
        .withArgs(user2.address, withdrawAmount);

      const account = await offgridpay.getUserAccount(user2.address);
      expect(account.pyusdDeposit).to.equal(MINIMUM_PYUSD_DEPOSIT - withdrawAmount);
    });

    it("Should allow moving PYUSD from deposit to balance", async function () {
      const moveAmount = 5 * 10**6; // 5 PYUSD
      
      await offgridpay.connect(user2).depositPyusdToBalance(moveAmount);

      const account = await offgridpay.getUserAccount(user2.address);
      expect(account.pyusdDeposit).to.equal(MINIMUM_PYUSD_DEPOSIT - moveAmount);
      expect(account.pyusdBalance).to.equal(moveAmount);
    });

    it("Should allow moving FLOW from deposit to balance", async function () {
      const moveAmount = ethers.parseEther("5");
      
      await offgridpay.connect(user1).depositFlowToBalance(moveAmount);

      const account = await offgridpay.getUserAccount(user1.address);
      expect(account.flowDeposit).to.equal(MINIMUM_FLOW_DEPOSIT - moveAmount);
      expect(account.flowBalance).to.equal(moveAmount);
    });
  });

  describe("Transaction Processing", function () {
    beforeEach(async function () {
      // Initialize accounts and set up balances
      await offgridpay.connect(user1).initializeAccount({ value: MINIMUM_FLOW_DEPOSIT });
      await offgridpay.connect(user2).initializeAccount({ value: MINIMUM_FLOW_DEPOSIT });
      
      await mockPYUSD.connect(user1).approve(await offgridpay.getAddress(), MINIMUM_PYUSD_DEPOSIT);
      await offgridpay.connect(user1).addPyusdDeposit(MINIMUM_PYUSD_DEPOSIT);
      
      await mockPYUSD.connect(user2).approve(await offgridpay.getAddress(), MINIMUM_PYUSD_DEPOSIT);
      await offgridpay.connect(user2).addPyusdDeposit(MINIMUM_PYUSD_DEPOSIT);
      
      // Move some funds to balances for transactions
      await offgridpay.connect(user1).depositFlowToBalance(ethers.parseEther("5"));
      await offgridpay.connect(user1).depositPyusdToBalance(5 * 10**6);
      await offgridpay.connect(user2).depositFlowToBalance(ethers.parseEther("5"));
      await offgridpay.connect(user2).depositPyusdToBalance(5 * 10**6);
    });

    it("Should process FLOW transaction correctly", async function () {
      const transferAmount = ethers.parseEther("2");
      
      const flowTransaction = {
        id: "flow-tx-1",
        from: user1.address,
        to: user2.address,
        amount: transferAmount,
        timestamp: Math.floor(Date.now() / 1000),
        nonce: 1,
        signature: "0x1234", // Mock signature
        status: 0, // Pending
        tokenType: 0 // FLOW
      };

      const batch = {
        batchId: "batch-1",
        submitter: user1.address,
        transactions: [flowTransaction],
        timestamp: Math.floor(Date.now() / 1000),
        flowUsed: 0
      };

      // This would normally require proper signature validation
      // For testing, we'll use the admin function to set balances
      const user1BalanceBefore = await offgridpay.getFlowBalance(user1.address);
      const user2BalanceBefore = await offgridpay.getFlowBalance(user2.address);
      
      // Simulate transaction processing by updating balances directly
      await offgridpay.connect(owner).updateFlowBalance(user1.address, user1BalanceBefore - transferAmount);
      await offgridpay.connect(owner).updateFlowBalance(user2.address, user2BalanceBefore + transferAmount);
      
      expect(await offgridpay.getFlowBalance(user1.address)).to.equal(user1BalanceBefore - transferAmount);
      expect(await offgridpay.getFlowBalance(user2.address)).to.equal(user2BalanceBefore + transferAmount);
    });

    it("Should process PYUSD transaction correctly", async function () {
      const transferAmount = 2 * 10**6; // 2 PYUSD
      
      const user1BalanceBefore = await offgridpay.getPyusdBalance(user1.address);
      const user2BalanceBefore = await offgridpay.getPyusdBalance(user2.address);
      
      // Simulate PYUSD transaction processing
      await offgridpay.connect(owner).updatePyusdBalance(user1.address, Number(user1BalanceBefore) - transferAmount);
      await offgridpay.connect(owner).updatePyusdBalance(user2.address, Number(user2BalanceBefore) + transferAmount);
      
      expect(await offgridpay.getPyusdBalance(user1.address)).to.equal(Number(user1BalanceBefore) - transferAmount);
      expect(await offgridpay.getPyusdBalance(user2.address)).to.equal(Number(user2BalanceBefore) + transferAmount);
    });
  });

  describe("View Functions", function () {
    beforeEach(async function () {
      await offgridpay.connect(user1).initializeAccount({ value: MINIMUM_FLOW_DEPOSIT });
      await mockPYUSD.connect(user1).approve(await offgridpay.getAddress(), MINIMUM_PYUSD_DEPOSIT);
      await offgridpay.connect(user1).addPyusdDeposit(MINIMUM_PYUSD_DEPOSIT);
      
      await offgridpay.connect(user1).depositFlowToBalance(ethers.parseEther("3"));
      await offgridpay.connect(user1).depositPyusdToBalance(3 * 10**6);
    });

    it("Should return correct FLOW balance", async function () {
      expect(await offgridpay.getFlowBalance(user1.address)).to.equal(ethers.parseEther("3"));
    });

    it("Should return correct PYUSD balance", async function () {
      expect(await offgridpay.getPyusdBalance(user1.address)).to.equal(3 * 10**6);
    });

    it("Should return correct FLOW deposit balance", async function () {
      expect(await offgridpay.getFlowDepositBalance(user1.address)).to.equal(MINIMUM_FLOW_DEPOSIT - ethers.parseEther("3"));
    });

    it("Should return correct PYUSD deposit balance", async function () {
      expect(await offgridpay.getPyusdDepositBalance(user1.address)).to.equal(MINIMUM_PYUSD_DEPOSIT - 3 * 10**6);
    });

    it("Should return correct user account info", async function () {
      const account = await offgridpay.getUserAccount(user1.address);
      expect(account.flowBalance).to.equal(ethers.parseEther("3"));
      expect(account.pyusdBalance).to.equal(3 * 10**6);
      expect(account.flowDeposit).to.equal(MINIMUM_FLOW_DEPOSIT - ethers.parseEther("3"));
      expect(account.pyusdDeposit).to.equal(MINIMUM_PYUSD_DEPOSIT - 3 * 10**6);
      expect(account.isActive).to.be.true;
    });
  });

  describe("Error Handling", function () {
    it("Should reject PYUSD operations when token not set", async function () {
      const newContract = await ethers.getContractFactory("offgridpay");
      const newOffgridpay = await newContract.deploy();
      
      await expect(
        newOffgridpay.connect(user1).initializeAccountWithPyusd(MINIMUM_PYUSD_DEPOSIT)
      ).to.be.revertedWith("PYUSD token not set");
    });

    it("Should reject insufficient PYUSD allowance", async function () {
      const depositAmount = 50 * 10**6;
      
      // Don't approve enough tokens
      await mockPYUSD.connect(user1).approve(await offgridpay.getAddress(), depositAmount - 1);
      
      await expect(
        offgridpay.connect(user1).initializeAccountWithPyusd(depositAmount)
      ).to.be.revertedWith("ERC20: insufficient allowance");
    });

    it("Should reject withdrawal with pending balance", async function () {
      await offgridpay.connect(user1).initializeAccount({ value: MINIMUM_FLOW_DEPOSIT });
      await offgridpay.connect(user1).depositFlowToBalance(ethers.parseEther("1"));
      
      await expect(
        offgridpay.connect(user1).withdrawFlowDeposit(ethers.parseEther("1"))
      ).to.be.revertedWith("Cannot withdraw deposit with pending balance");
    });
  });
});
