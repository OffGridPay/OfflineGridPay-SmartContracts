// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title LINProtocolEVM
 * @dev Complete LIN Protocol implementation for FlowEVM
 * Enables offline cryptocurrency transactions through Bluetooth peer-to-peer communication
 * with automatic blockchain synchronization when users come online
 */
contract LINProtocolEVM is ReentrancyGuard, Ownable {
    using ECDSA for bytes32;

    // Protocol constants
    uint256 public constant MINIMUM_FLOW_DEPOSIT = 10 ether;
    uint256 public constant AUTO_REFILL_THRESHOLD = 1 ether;
    uint256 public constant MAX_BATCH_SIZE = 100;
    uint256 public constant TRANSACTION_VALIDITY_HOURS = 24;
    uint256 public constant BASE_TRANSACTION_FEE = 0.001 ether;
    uint256 public constant MAX_TRANSACTION_AMOUNT = 1000000 ether;
    uint256 public constant TRANSACTION_EXPIRY_SECONDS = 86400; // 24 hours
    uint256 public constant MAX_NONCE_SKIP = 10;
    uint256 public constant MAX_SIGNATURE_LENGTH = 256;
    uint256 public constant MIN_SIGNATURE_LENGTH = 64;

    // Transaction status enumeration
    enum TransactionStatus {
        Pending,
        Executed,
        Failed,
        Expired
    }

    // Core offline transaction structure
    struct OfflineTransaction {
        string id;
        address from;
        address to;
        uint256 amount;
        uint256 timestamp;
        uint256 nonce;
        bytes signature;
        TransactionStatus status;
    }

    // Transaction batch structure
    struct TransactionBatch {
        string batchId;
        address submitter;
        OfflineTransaction[] transactions;
        uint256 timestamp;
        uint256 flowUsed;
    }

    // User account structure
    struct UserAccount {
        uint256 balance;
        uint256 flowDeposit;
        uint256 nonce;
        uint256 lastSyncTime;
        bool isActive;
        address publicKeyAddress; // Using address as public key identifier
    }

    // Contract storage
    uint256 public totalUsers;
    uint256 public totalTransactions;
    uint256 public totalFlowDeposited;
    
    mapping(string => bool) public processedTransactions;
    mapping(address => UserAccount) public userAccounts;
    mapping(address => bool) public registeredUsers;

    // Events
    event AccountInitialized(address indexed user, uint256 flowDeposit);
    event AccountDeactivated(address indexed user);
    event AccountReactivated(address indexed user);
    event FlowDepositAdded(address indexed user, uint256 amount);
    event FlowDepositWithdrawn(address indexed user, uint256 amount);
    event OfflineTransactionCreated(string indexed txId, address indexed from, address indexed to, uint256 amount);
    event OfflineTransactionExecuted(string indexed txId, address indexed from, address indexed to, uint256 amount);
    event OfflineTransactionFailed(string indexed txId, address indexed from, string reason);
    event OfflineBatchProcessed(string indexed batchId, uint256 transactionCount, address indexed submitter);
    event InvalidSignature(string indexed txId, address indexed signer);
    event ReplayAttackDetected(string indexed txId, address indexed attacker);
    event NonceValidationFailed(address indexed user, uint256 expectedNonce, uint256 providedNonce);
    event TransactionExpired(string indexed txId, uint256 expiryTime);
    event PublicKeyRegistered(address indexed user);

    // Error messages
    string constant ERROR_INSUFFICIENT_DEPOSIT = "INSUFFICIENT_DEPOSIT";
    string constant ERROR_INVALID_SIGNATURE = "INVALID_SIGNATURE";
    string constant ERROR_REPLAY_ATTACK = "REPLAY_ATTACK";
    string constant ERROR_TRANSACTION_EXPIRED = "TRANSACTION_EXPIRED";
    string constant ERROR_INVALID_NONCE = "INVALID_NONCE";
    string constant ERROR_BATCH_TOO_LARGE = "BATCH_TOO_LARGE";
    string constant ERROR_ACCOUNT_INACTIVE = "ACCOUNT_INACTIVE";
    string constant ERROR_INSUFFICIENT_BALANCE = "INSUFFICIENT_BALANCE";

    constructor() {
        totalUsers = 0;
        totalTransactions = 0;
        totalFlowDeposited = 0;
    }

    /**
     * @dev Initialize user account with Flow deposit
     */
    function initializeAccount() external payable {
        require(msg.value >= MINIMUM_FLOW_DEPOSIT, ERROR_INSUFFICIENT_DEPOSIT);
        require(!registeredUsers[msg.sender], "Account already initialized");

        UserAccount storage account = userAccounts[msg.sender];
        account.balance = 0;
        account.flowDeposit = msg.value;
        account.nonce = 0;
        account.lastSyncTime = block.timestamp;
        account.isActive = true;
        account.publicKeyAddress = msg.sender; // Using sender address as public key

        registeredUsers[msg.sender] = true;
        totalUsers++;
        totalFlowDeposited += msg.value;

        emit AccountInitialized(msg.sender, msg.value);
        emit PublicKeyRegistered(msg.sender);
    }

    /**
     * @dev Add Flow deposit to user account
     */
    function addFlowDeposit() external payable {
        require(registeredUsers[msg.sender], "Account not initialized");
        require(msg.value > 0, "Deposit must be greater than 0");

        UserAccount storage account = userAccounts[msg.sender];
        account.flowDeposit += msg.value;
        totalFlowDeposited += msg.value;

        emit FlowDepositAdded(msg.sender, msg.value);
    }

    /**
     * @dev Withdraw Flow deposit from user account
     */
    function withdrawFlowDeposit(uint256 amount) external nonReentrant {
        require(registeredUsers[msg.sender], "Account not initialized");
        UserAccount storage account = userAccounts[msg.sender];
        require(account.flowDeposit >= amount, "Insufficient deposit balance");

        account.flowDeposit -= amount;
        totalFlowDeposited -= amount;

        payable(msg.sender).transfer(amount);

        emit FlowDepositWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Validate transaction signature using ECDSA
     */
    function validateSignature(OfflineTransaction memory transaction) public view  returns (bool) {
        // Create message hash from transaction data
        bytes32 messageHash = keccak256(abi.encodePacked(
            transaction.id,
            transaction.from,
            transaction.to,
            transaction.amount,
            transaction.timestamp,
            transaction.nonce
        ));

        // Convert to Ethereum signed message hash
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(messageHash);

        // Recover signer address from signature
        address recoveredSigner = ethSignedMessageHash.recover(transaction.signature);

        // Verify the signer matches the transaction sender
        return recoveredSigner == transaction.from;
    }

    /**
     * @dev Prevent replay attacks
     */
    function preventReplay(string memory txId) public view returns (bool) {
        return !processedTransactions[txId];
    }

    /**
     * @dev Validate transaction nonce
     */
    function validateNonce(address user, uint256 providedNonce) public view returns (bool) {
        UserAccount storage account = userAccounts[user];
        uint256 currentNonce = account.nonce;
        
        // Allow nonce to be current + 1, or within MAX_NONCE_SKIP range for out-of-order processing
        return (providedNonce == currentNonce + 1) || 
               (providedNonce > currentNonce && providedNonce <= currentNonce + MAX_NONCE_SKIP);
    }

    /**
     * @dev Check if transaction has expired
     */
    function isTransactionExpired(uint256 timestamp) public view returns (bool) {
        return block.timestamp > timestamp + TRANSACTION_EXPIRY_SECONDS;
    }

    /**
     * @dev Process offline transaction batch
     */
    function syncOfflineTransactions(TransactionBatch memory batch) external nonReentrant returns (bool) {
        require(batch.transactions.length > 0, "Batch cannot be empty");
        require(batch.transactions.length <= MAX_BATCH_SIZE, ERROR_BATCH_TOO_LARGE);
        require(registeredUsers[msg.sender], "Account not initialized");

        UserAccount storage submitterAccount = userAccounts[msg.sender];
        require(submitterAccount.isActive, ERROR_ACCOUNT_INACTIVE);

        uint256 successCount = 0;
        uint256 totalFees = batch.transactions.length * BASE_TRANSACTION_FEE;

        require(submitterAccount.flowDeposit >= totalFees, ERROR_INSUFFICIENT_DEPOSIT);

        for (uint256 i = 0; i < batch.transactions.length; i++) {
            OfflineTransaction memory tx = batch.transactions[i];
            
            if (processTransaction(tx)) {
                successCount++;
            }
        }

        // Deduct fees from submitter's deposit
        submitterAccount.flowDeposit -= totalFees;
        submitterAccount.lastSyncTime = block.timestamp;

        totalTransactions += successCount;

        emit OfflineBatchProcessed(batch.batchId, successCount, msg.sender);

        return successCount == batch.transactions.length;
    }

    /**
     * @dev Process individual transaction
     */
    function processTransaction(OfflineTransaction memory transaction) internal returns (bool) {
        // Check if transaction has already been processed
        if (!preventReplay(transaction.id)) {
            emit ReplayAttackDetected(transaction.id, transaction.from);
            return false;
        }

        // Check if transaction has expired
        if (isTransactionExpired(transaction.timestamp)) {
            emit TransactionExpired(transaction.id, transaction.timestamp + TRANSACTION_EXPIRY_SECONDS);
            return false;
        }

        // Validate signature
        if (!validateSignature(transaction)) {
            emit InvalidSignature(transaction.id, transaction.from);
            return false;
        }

        // Check if sender account exists and is active
        if (!registeredUsers[transaction.from] || !userAccounts[transaction.from].isActive) {
            emit OfflineTransactionFailed(transaction.id, transaction.from, ERROR_ACCOUNT_INACTIVE);
            return false;
        }

        // Check if recipient account exists
        if (!registeredUsers[transaction.to]) {
            emit OfflineTransactionFailed(transaction.id, transaction.from, "Recipient account not found");
            return false;
        }

        // Validate nonce
        if (!validateNonce(transaction.from, transaction.nonce)) {
            emit NonceValidationFailed(transaction.from, userAccounts[transaction.from].nonce + 1, transaction.nonce);
            return false;
        }

        // Check sender balance
        UserAccount storage senderAccount = userAccounts[transaction.from];
        if (senderAccount.balance < transaction.amount) {
            emit OfflineTransactionFailed(transaction.id, transaction.from, ERROR_INSUFFICIENT_BALANCE);
            return false;
        }

        // Execute transaction
        UserAccount storage recipientAccount = userAccounts[transaction.to];
        
        senderAccount.balance -= transaction.amount;
        recipientAccount.balance += transaction.amount;
        senderAccount.nonce = transaction.nonce;

        // Mark transaction as processed
        processedTransactions[transaction.id] = true;

        emit OfflineTransactionExecuted(transaction.id, transaction.from, transaction.to, transaction.amount);
        return true;
    }

    /**
     * @dev Deactivate user account
     */
    function deactivateAccount() external {
        require(registeredUsers[msg.sender], "Account not initialized");
        
        UserAccount storage account = userAccounts[msg.sender];
        account.isActive = false;

        emit AccountDeactivated(msg.sender);
    }

    /**
     * @dev Reactivate user account
     */
    function reactivateAccount() external {
        require(registeredUsers[msg.sender], "Account not initialized");
        
        UserAccount storage account = userAccounts[msg.sender];
        account.isActive = true;

        emit AccountReactivated(msg.sender);
    }

    /**
     * @dev Update user balance (only for testing/admin purposes)
     */
    function updateBalance(address user, uint256 newBalance) external onlyOwner {
        require(registeredUsers[user], "Account not initialized");
        
        UserAccount storage account = userAccounts[user];
        account.balance = newBalance;
    }

    // View functions
    function getBalance(address user) external view returns (uint256) {
        return userAccounts[user].balance;
    }

    function getDepositBalance(address user) external view returns (uint256) {
        return userAccounts[user].flowDeposit;
    }

    function getUserNonce(address user) external view returns (uint256) {
        return userAccounts[user].nonce;
    }

    function isUserActive(address user) external view returns (bool) {
        return userAccounts[user].isActive;
    }

    function getUserAccount(address user) external view returns (UserAccount memory) {
        return userAccounts[user];
    }

    function isTransactionProcessed(string memory txId) external view returns (bool) {
        return processedTransactions[txId];
    }

    /**
     * @dev Generate transaction ID
     */
    function generateTransactionId(
        address from,
        address to,
        uint256 nonce,
        uint256 timestamp
    ) external pure returns (string memory) {
        return string(abi.encodePacked(
            addressToString(from),
            "-",
            addressToString(to),
            "-",
            uintToString(nonce),
            "-",
            uintToString(timestamp)
        ));
    }

    // Utility functions
    function addressToString(address _addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    function uintToString(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    // Emergency functions
    function emergencyWithdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {
        // Allow contract to receive ETH
    }
}
