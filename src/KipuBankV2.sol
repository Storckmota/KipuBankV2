// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title KipuBankV2
 * @author Barba - 77 Innovation Labs
 * @dev Enhanced banking contract with access control, oracle integration, and advanced features
 * @notice This contract demonstrates advanced Solidity patterns and DeFi best practices
 * @custom:contact anySocial/i3arba
 */

contract KipuBankV2 is AccessControl, Pausable {
    /*///////////////////////
        TYPE DECLARATIONS
    ///////////////////////*/
    ///@notice struct to represent user account information
    struct UserAccount {
        uint256 totalDeposits;
        uint256 totalWithdrawals;
        uint64 lastDepositTime;
        uint64 lastWithdrawalTime;
        uint16 creditScore;
        bool isActive;
    }

    ///@notice struct to represent transaction details
    struct Transaction {
        address user;
        uint256 amount;
        uint64 timestamp;
        TransactionType txType;
        bool isProcessed;
    }

    ///@notice enum for transaction types
    enum TransactionType {
        DEPOSIT,
        WITHDRAWAL,
        EMERGENCY_WITHDRAWAL,
        INTEREST_PAYMENT
    }

    ///@notice struct for oracle price data
    struct PriceData {
        uint256 price;
        uint64 timestamp;
        bool isValid;
    }

    ///@notice struct for Chainlink price feed configuration
    struct PriceFeedConfig {
        AggregatorV3Interface priceFeed;
        string description;
        bool isActive;
    }

    ///@notice struct for bank configuration parameters
    struct BankConfig {
        uint256 bankCap;
        uint256 amountPerWithdraw;
        uint256 minDeposit;
        uint256 dailyWithdrawalLimit;
        uint256 interestRateBps;
        uint16 minCreditScore;
        uint16 maxCreditScore;
    }

    /*///////////////////////
        ACCESS CONTROL ROLES
    ///////////////////////*/
    ///@notice role identifier for accounts that can pause/unpause the contract
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    ///@notice role identifier for accounts that can perform emergency withdrawals
    bytes32 public constant TREASURER_ROLE = keccak256("TREASURER_ROLE");
    ///@notice role identifier for accounts that can update oracle data
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    /*///////////////////////
        CONSTANTS
    ///////////////////////*/
    ///@notice maximum amount the vault can store
    uint256 immutable BANK_CAP;
    
    ///@notice constant variable to limit the withdrawal
    uint256 constant AMOUNT_PER_WITHDRAW = 1 * 10 ** 16;
    
    ///@notice constant for decimal precision (18 decimals)
    uint256 constant DECIMAL_PRECISION = 10 ** 18;
    
    ///@notice constant for minimum deposit amount
    uint256 constant MIN_DEPOSIT = 1 * 10 ** 15; // 0.001 ETH
    
    ///@notice constant for maximum daily withdrawal limit
    uint256 constant DAILY_WITHDRAWAL_LIMIT = 10 * 10 ** 18; // 10 ETH
    
    ///@notice constant for interest rate (basis points: 100 = 1%)
    uint256 constant INTEREST_RATE_BPS = 50; // 0.5%
    
    ///@notice constant for minimum credit score
    uint16 constant MIN_CREDIT_SCORE = 300;
    
    ///@notice constant for maximum credit score
    uint16 constant MAX_CREDIT_SCORE = 850;
    
    ///@notice constant for Chainlink price feed decimals (usually 8)
    uint256 constant CHAINLINK_DECIMALS = 8;
    
    ///@notice constant for ETH decimals
    uint256 constant ETH_DECIMALS = 18;

    ///@notice constant for stale data threshold (2 hours)
    uint256 constant STALE_THRESHOLD = 2 hours;
    
    ///@notice constant for minimum ETH price validation ($100)
    uint256 constant MIN_ETH_PRICE = 100 * 10**8;
    
    ///@notice constant for maximum ETH price validation ($50,000)
    uint256 constant MAX_ETH_PRICE = 50000 * 10**8;
    
    ///@notice constant for basis points divisor (10000 = 100%)
    uint256 constant BASIS_POINTS_DIVISOR = 10000;
    
    ///@notice constant for days in year (for interest calculation)
    uint256 constant DAYS_IN_YEAR = 365;
    
    ///@notice constant for one ether (18 decimals)
    uint256 constant ONE_ETHER = 1 ether;
    
    ///@notice constant for one gwei
    uint256 constant ONE_GWEI = 1 gwei;
    
    ///@notice constant for one wei
    uint256 constant ONE_WEI = 1 wei;
    
    ///@notice constant for seconds in minute
    uint256 constant SECONDS_IN_MINUTE = 60;
    
    ///@notice constant for seconds in hour
    uint256 constant SECONDS_IN_HOUR = 3600;
    
    ///@notice constant for seconds in day
    uint256 constant SECONDS_IN_DAY = 86400;
    
    ///@notice constant for seconds in week
    uint256 constant SECONDS_IN_WEEK = 604800;
    
    ///@notice constant for seconds in month (30.44 days)
    uint256 constant SECONDS_IN_MONTH = 2629746;
    
    ///@notice constant for percentage divisor (100)
    uint256 constant PERCENTAGE_DIVISOR = 100;
    
    ///@notice constant for permille divisor (1000)
    uint256 constant PERMILLE_DIVISOR = 1000;
    
    ///@notice constant for maximum uint256 value
    uint256 constant MAX_UINT256 = type(uint256).max;
    
    ///@notice constant for maximum uint128 value
    uint256 constant MAX_UINT128 = type(uint128).max;
    
    ///@notice constant for maximum uint64 value
    uint256 constant MAX_UINT64 = type(uint64).max;
    
    ///@notice constant for maximum uint32 value
    uint256 constant MAX_UINT32 = type(uint32).max;
    
    ///@notice constant for maximum uint16 value
    uint256 constant MAX_UINT16 = type(uint16).max;
    
    ///@notice constant for maximum uint8 value
    uint256 constant MAX_UINT8 = type(uint8).max;

    /*///////////////////////
        STATE VARIABLES
    ///////////////////////*/
    ///@notice public variable to hold the number of deposits completed
    uint256 public depositsCounter;
    ///@notice public variable to hold the number of withdrawals completed
    uint256 public withdrawsCounter;
    ///@notice public variable to track total interest paid
    uint256 public totalInterestPaid;
    ///@notice public variable to track oracle update count
    uint256 public oracleUpdateCount;

    ///@notice mapping to keep track of deposits
    mapping(address user => uint256 amount) public vault;
    
    ///@notice nested mapping for user accounts with detailed information
    mapping(address user => UserAccount account) public userAccounts;
    
    ///@notice nested mapping for daily withdrawal limits per user
    mapping(address user => mapping(uint256 day => uint256 amount)) public dailyWithdrawals;
    
    ///@notice nested mapping for transaction history
    mapping(address user => mapping(uint256 index => Transaction)) public userTransactions;
    
    ///@notice mapping to track transaction counts per user
    mapping(address user => uint256) public userTransactionCounts;
    
    ///@notice mapping for Chainlink price feeds
    mapping(string token => PriceFeedConfig) public priceFeeds;
    
    ///@notice mapping for cached price data
    mapping(string token => PriceData) public cachedPrices;

    /*///////////////////////
           EVENTS
    ///////////////////////*/
    ///@notice event emitted when a deposit is successfully completed
    event KipuBank_SuccessfullyDeposited(address user, uint256 amount);
    ///@notice event emitted when a withdrawal is successfully completed
    event KipuBank_SuccessfullyWithdrawn(address user, uint256 amount);
    ///@notice event emitted when interest is paid to a user
    event KipuBank_InterestPaid(address user, uint256 amount);
    ///@notice event emitted when Chainlink price feed is updated
    event KipuBank_PriceFeedUpdated(string token, uint256 price, uint256 timestamp);
    ///@notice event emitted when price feed is configured
    event KipuBank_PriceFeedConfigured(string token, address priceFeedAddress);
    ///@notice event emitted when user credit score is updated
    event KipuBank_CreditScoreUpdated(address user, uint256 newScore);

    /*///////////////////////
            ERRORS
    ///////////////////////*/
    ///@notice error emitted when the amount to be deposited plus the contract balance exceeds the bankCap
    error KipuBank_BankCapReached(uint256 depositCap);
    ///@notice error emitted when the amount to be withdrawn is bigger than the user's balance
    error KipuBank_AmountExceedBalance(uint256 amount, uint256 balance);
    ///@notice error emitted when the native transfer fails
    error KipuBank_TransferFailed(bytes reason);
    ///@notice error emitted when daily withdrawal limit is exceeded
    error KipuBank_DailyLimitExceeded(uint256 amount, uint256 limit);
    ///@notice error emitted when minimum deposit amount is not met
    error KipuBank_MinimumDepositNotMet(uint256 amount, uint256 minimum);
    ///@notice error emitted when credit score is too low
    error KipuBank_CreditScoreTooLow(uint256 score, uint256 minimum);
    ///@notice error emitted when oracle data is invalid
    error KipuBank_InvalidOracleData(string token);
    ///@notice error emitted when price feed is not configured
    error KipuBank_PriceFeedNotConfigured(string token);
    ///@notice error emitted when price feed returns invalid data
    error KipuBank_InvalidPriceFeedData();

    /*///////////////////////
           FUNCTIONS
    ///////////////////////*/
    /**
     * @notice constructor that initializes the bank with a maximum capacity
     * @param _bankCap maximum amount of ETH the bank can hold
     * @dev grants all roles to the deployer for initial setup
     * @dev DEFAULT_ADMIN_ROLE: can grant/revoke other roles
     * @dev PAUSER_ROLE: can pause/unpause contract operations
     * @dev TREASURER_ROLE: can perform emergency withdrawals when paused
     * @dev ORACLE_ROLE: can configure Chainlink price feeds
     */
    constructor(uint256 _bankCap) {
        BANK_CAP = _bankCap;

        // Grant all roles to the deployer for initial setup
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(TREASURER_ROLE, msg.sender);
        _grantRole(ORACLE_ROLE, msg.sender);
    }

    /**
     * @notice modifier to check if the amount follows some conditions
     * @param _amount eth amount to withdraw
     * @dev must revert if the amount is bigger than the user balance or is bigger than the AMOUNT_PER_WITHDRAW threshold.
     */
    modifier amountCheck(uint256 _amount) {
        _amountCheck(_amount);
        _;
    }

    /**
     * @notice modifier to check daily withdrawal limits
     * @param _amount amount to withdraw
     */
    modifier dailyLimitCheck(uint256 _amount) {
        _dailyLimitCheck(_amount);
        _;
    }

    /**
     * @notice internal function to validate daily withdrawal limit
     * @param _amount amount to validate against today's remaining limit
     */
    function _dailyLimitCheck(uint256 _amount) internal view {
        uint256 today = block.timestamp / SECONDS_IN_DAY;
        uint256 todayWithdrawals = dailyWithdrawals[msg.sender][today];
        if (todayWithdrawals + _amount > DAILY_WITHDRAWAL_LIMIT) {
            revert KipuBank_DailyLimitExceeded(_amount, DAILY_WITHDRAWAL_LIMIT - todayWithdrawals);
        }
    }

    /**
     * @notice modifier to check minimum deposit amount
     * @param _amount amount to deposit
     */
    modifier minimumDepositCheck(uint256 _amount) {
        _minimumDepositCheck(_amount);
        _;
    }

    /**
     * @notice internal function to validate minimum deposit value
     * @param _amount deposit amount to validate
     */
    function _minimumDepositCheck(uint256 _amount) internal pure {
        if (_amount < MIN_DEPOSIT) {
            revert KipuBank_MinimumDepositNotMet(_amount, MIN_DEPOSIT);
        }
    }

    /**
     * @notice internal function to validate withdrawal amount
     * @param _amount amount to validate
     * @dev checks if amount exceeds user balance or withdrawal limit
     */
    function _amountCheck(uint256 _amount) internal view {
        uint256 userBalance = vault[msg.sender];
        if (_amount > userBalance || _amount > AMOUNT_PER_WITHDRAW) {
            revert KipuBank_AmountExceedBalance(_amount, userBalance);
        }
    }

    /**
     * @notice function to convert wei to ETH with decimal precision
     * @param weiAmount amount in wei
     * @return ethAmount amount in ETH (with 18 decimals)
     */
    function convertWeiToEth(uint256 weiAmount) public pure returns (uint256 ethAmount) {
        return (weiAmount * DECIMAL_PRECISION) / ONE_ETHER;
    }

    /**
     * @notice function to convert ETH to wei
     * @param ethAmount amount in ETH
     * @return weiAmount amount in wei
     */
    function convertEthToWei(uint256 ethAmount) public pure returns (uint256 weiAmount) {
        return (ethAmount * ONE_ETHER) / DECIMAL_PRECISION;
    }

    /**
     * @notice function to calculate interest for a user
     * @param user address of the user
     * @return interestAmount calculated interest amount
     */
    function calculateInterest(address user) public view returns (uint256 interestAmount) {
        UserAccount memory account = userAccounts[user];
        if (!account.isActive || account.totalDeposits == 0) {
            return 0;
        }

        uint256 timeSinceLastDeposit = block.timestamp - account.lastDepositTime;
        uint256 daysSinceDeposit = timeSinceLastDeposit / SECONDS_IN_DAY;
        
        // Simple interest calculation: principal * rate * time
        interestAmount = (account.totalDeposits * INTEREST_RATE_BPS * daysSinceDeposit) / (BASIS_POINTS_DIVISOR * DAYS_IN_YEAR);
        
        return interestAmount;
    }

    /**
     * @notice function to configure Chainlink price feed
     * @param token token symbol (e.g., "ETH", "BTC")
     * @param priceFeedAddress address of the Chainlink AggregatorV3Interface
     * @param description description of the price feed
     * @dev restricted to ORACLE_ROLE
     */
    function configurePriceFeed(
        string calldata token, 
        address priceFeedAddress, 
        string calldata description
    ) external onlyRole(ORACLE_ROLE) {
        priceFeeds[token] = PriceFeedConfig({
            priceFeed: AggregatorV3Interface(priceFeedAddress),
            description: description,
            isActive: true
        });
        
        emit KipuBank_PriceFeedConfigured(token, priceFeedAddress);
    }

    /**
     * @notice function to get latest price from Chainlink with proper validation
     * @param token token symbol
     * @return price latest price from Chainlink (8 decimals)
     * @dev implements Chainlink best practices for data feed consumption
     * @dev checks for stale data, invalid answers, and reasonable price ranges
     */
    function getLatestPrice(string calldata token) public view returns (uint256 price) {
        PriceFeedConfig memory config = priceFeeds[token];
        if (!config.isActive) {
            revert KipuBank_PriceFeedNotConfigured(token);
        }

        // Get latest round data from Chainlink
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = config.priceFeed.latestRoundData();

        // Validate the data according to Chainlink best practices
        _validatePriceFeedData(answer, updatedAt, roundId, answeredInRound);
        
        return uint256(answer);
    }

    /**
     * @notice internal function to validate Chainlink price feed data
     * @param answer price answer from Chainlink
     * @param updatedAt timestamp of the update
     * @param roundId current round ID
     * @param answeredInRound round ID when answer was computed
     * @dev implements Chainlink monitoring recommendations
     */
    function _validatePriceFeedData(
        int256 answer,
        uint256 updatedAt,
        uint80 roundId,
        uint80 answeredInRound
    ) internal view {
        // Check for invalid answer (negative or zero)
        if (answer <= 0) {
            revert KipuBank_InvalidPriceFeedData();
        }

        // Check for stale data - ensure answer is from current round
        if (answeredInRound < roundId) {
            revert KipuBank_InvalidPriceFeedData();
        }

        // Check for stale timestamp - data should be recent (within 2 hours for ETH/USD)
        if (block.timestamp - updatedAt > STALE_THRESHOLD) {
            revert KipuBank_InvalidPriceFeedData();
        }

        // Additional validation: check for reasonable price ranges
        // ETH/USD should be between $100 and $50,000 (8 decimals)
        if (uint256(answer) < MIN_ETH_PRICE || uint256(answer) > MAX_ETH_PRICE) {
            revert KipuBank_InvalidPriceFeedData();
        }
    }

    /**
     * @notice function to get price feed heartbeat and deviation threshold
     * @param token token symbol
     * @return heartbeat heartbeat interval in seconds
     * @return deviation deviation threshold (basis points)
     * @dev useful for monitoring and understanding feed update frequency
     */
    function getPriceFeedConfig(string calldata token) external view returns (uint256 heartbeat, uint256 deviation) {
        PriceFeedConfig memory config = priceFeeds[token];
        if (!config.isActive) {
            revert KipuBank_PriceFeedNotConfigured(token);
        }

        // Get aggregator address from proxy
        address aggregator = config.priceFeed.aggregator();
        
        // Read heartbeat and deviation from aggregator
        // Note: These values may not be available on all networks
        try config.priceFeed.latestRoundData() returns (uint80, int256, uint256, uint256, uint80) {
            // For monitoring purposes, we'll return reasonable defaults
            // ETH/USD typically has 1 hour heartbeat and 0.5% deviation
            heartbeat = SECONDS_IN_HOUR; // 1 hour
            deviation = 50;   // 0.5% in basis points
        } catch {
            heartbeat = SECONDS_IN_HOUR;
            deviation = 50;
        }
    }

    /**
     * @notice function to get historical price data from Chainlink
     * @param token token symbol
     * @param roundId specific round ID to query
     * @return price price at the specified round (8 decimals)
     * @return timestamp timestamp of the round
     * @dev useful for backtesting and historical analysis
     */
    function getHistoricalPrice(string calldata token, uint80 roundId) external view returns (uint256 price, uint256 timestamp) {
        PriceFeedConfig memory config = priceFeeds[token];
        if (!config.isActive) {
            revert KipuBank_PriceFeedNotConfigured(token);
        }

        (
            uint80 id,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = config.priceFeed.getRoundData(roundId);

        // Validate historical data
        if (answer <= 0 || answeredInRound < id) {
            revert KipuBank_InvalidPriceFeedData();
        }

        return (uint256(answer), updatedAt);
    }

    /**
     * @notice function to get the latest round ID for a price feed
     * @param token token symbol
     * @return roundId latest round ID
     * @dev useful for iterating through historical data
     */
    function getLatestRoundId(string calldata token) external view returns (uint80 roundId) {
        PriceFeedConfig memory config = priceFeeds[token];
        if (!config.isActive) {
            revert KipuBank_PriceFeedNotConfigured(token);
        }

        (roundId, , , , ) = config.priceFeed.latestRoundData();
        return roundId;
    }

    /**
     * @notice function to get price feed description and decimals
     * @param token token symbol
     * @return description description of the price feed
     * @return decimals number of decimals for the price feed
     * @dev useful for understanding the data format
     */
    function getPriceFeedInfo(string calldata token) external view returns (string memory description, uint8 decimals) {
        PriceFeedConfig memory config = priceFeeds[token];
        if (!config.isActive) {
            revert KipuBank_PriceFeedNotConfigured(token);
        }

        description = config.priceFeed.description();
        decimals = config.priceFeed.decimals();
        
        return (description, decimals);
    }

    /**
     * @notice function to monitor price feed health
     * @param token token symbol
     * @return isHealthy true if price feed is healthy
     * @return lastUpdate timestamp of last update
     * @return price current price
     * @dev implements comprehensive monitoring as recommended by Chainlink
     */
    function monitorPriceFeedHealth(string calldata token) external view returns (
        bool isHealthy,
        uint256 lastUpdate,
        uint256 price
    ) {
        PriceFeedConfig memory config = priceFeeds[token];
        if (!config.isActive) {
            return (false, 0, 0);
        }

        try config.priceFeed.latestRoundData() returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) {
            // Check all health indicators
            bool validAnswer = answer > 0;
            bool currentRound = answeredInRound >= roundId;
            bool recentUpdate = (block.timestamp - updatedAt) <= STALE_THRESHOLD;
            bool reasonablePrice = uint256(answer) >= MIN_ETH_PRICE && uint256(answer) <= MAX_ETH_PRICE;
            
            isHealthy = validAnswer && currentRound && recentUpdate && reasonablePrice;
            lastUpdate = updatedAt;
            price = uint256(answer);
            
        } catch {
            isHealthy = false;
            lastUpdate = 0;
            price = 0;
        }
    }

    /**
     * @notice function to update cached price data
     * @param token token symbol
     * @dev restricted to ORACLE_ROLE
     */
    function updateCachedPrice(string calldata token) external onlyRole(ORACLE_ROLE) {
        uint256 price = getLatestPrice(token);
        
        cachedPrices[token] = PriceData({
            price: price,
            timestamp: block.timestamp,
            isValid: true
        });
        
        oracleUpdateCount++;
        emit KipuBank_PriceFeedUpdated(token, price, block.timestamp);
    }

    /**
     * @notice function to get cached price data
     * @param token token symbol
     * @return priceData struct containing cached price information
     */
    function getCachedPrice(string calldata token) external view returns (PriceData memory priceData) {
        priceData = cachedPrices[token];
        if (!priceData.isValid) {
            revert KipuBank_InvalidOracleData(token);
        }
        return priceData;
    }

    /**
     * @notice function to convert ETH amount to USD using Chainlink price
     * @param ethAmount amount in ETH (18 decimals)
     * @param token token symbol for price feed
     * @return usdAmount amount in USD (18 decimals)
     */
    function convertEthToUsd(uint256 ethAmount, string calldata token) external view returns (uint256 usdAmount) {
        uint256 ethPrice = getLatestPrice(token); // 8 decimals
        
        // Convert: ETH * price / 10^8 = USD (18 decimals)
        usdAmount = (ethAmount * ethPrice) / (10 ** CHAINLINK_DECIMALS);
        
        return usdAmount;
    }

    /**
     * @notice function to convert USD amount to ETH using Chainlink price
     * @param usdAmount amount in USD (18 decimals)
     * @param token token symbol for price feed
     * @return ethAmount amount in ETH (18 decimals)
     */
    function convertUsdToEth(uint256 usdAmount, string calldata token) external view returns (uint256 ethAmount) {
        uint256 ethPrice = getLatestPrice(token); // 8 decimals
        
        // Convert: USD * 10^8 / price = ETH (18 decimals)
        ethAmount = (usdAmount * (10 ** CHAINLINK_DECIMALS)) / ethPrice;
        
        return ethAmount;
    }

    /**
     * @notice function to update user credit score
     * @param user address of the user
     * @param newScore new credit score
     * @dev restricted to admin role
     */
    function updateCreditScore(address user, uint16 newScore) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newScore < MIN_CREDIT_SCORE || newScore > MAX_CREDIT_SCORE) {
            revert KipuBank_CreditScoreTooLow(newScore, MIN_CREDIT_SCORE);
        }
        
        userAccounts[user].creditScore = newScore;
        emit KipuBank_CreditScoreUpdated(user, newScore);
    }

    /**
     * @notice external function to receive native deposits
     * @notice Emit an event when deposits succeed.
     * @dev after the transaction contract balance should not be bigger than the bank cap
     * @dev can only be called when contract is not paused
     * @dev enforces minimum deposit amount
     */
    function deposit() external payable whenNotPaused minimumDepositCheck(msg.value) {
        if (address(this).balance > BANK_CAP) revert KipuBank_BankCapReached(BANK_CAP);

        depositsCounter++;
        vault[msg.sender] += msg.value;

        // Update user account information
        UserAccount storage account = userAccounts[msg.sender];
        account.totalDeposits += msg.value;
        account.lastDepositTime = block.timestamp;
        account.isActive = true;

        // Record transaction
        uint256 txIndex = userTransactionCounts[msg.sender]++;
        userTransactions[msg.sender][txIndex] = Transaction({
            user: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            txType: TransactionType.DEPOSIT,
            isProcessed: true
        });

        emit KipuBank_SuccessfullyDeposited(msg.sender, msg.value);
    }

    /**
     * @notice external function to process withdrawals
     * @param _amount is the amount to be withdrawn
     * @dev User must not be able to withdraw more than deposited
     * @dev User must not be able to withdraw more than the threshold per withdraw
     * @dev can only be called when contract is not paused
     * @dev enforces daily withdrawal limits
     */
    function withdraw(uint256 _amount) external amountCheck(_amount) whenNotPaused dailyLimitCheck(_amount) {
        withdrawsCounter++;
        vault[msg.sender] -= _amount;

        // Update daily withdrawal tracking
        uint256 today = block.timestamp / SECONDS_IN_DAY;
        dailyWithdrawals[msg.sender][today] += _amount;

        // Update user account information
        UserAccount storage account = userAccounts[msg.sender];
        account.totalWithdrawals += _amount;
        account.lastWithdrawalTime = block.timestamp;

        // Record transaction
        uint256 txIndex = userTransactionCounts[msg.sender]++;
        userTransactions[msg.sender][txIndex] = Transaction({
            user: msg.sender,
            amount: _amount,
            timestamp: block.timestamp,
            txType: TransactionType.WITHDRAWAL,
            isProcessed: true
        });

        _processTransfer(_amount);
    }

    /**
     * @notice function to pay interest to a user
     * @param user address of the user to pay interest to
     * @dev calculates and pays accumulated interest
     */
    function payInterest(address user) external {
        uint256 interestAmount = calculateInterest(user);
        if (interestAmount > 0 && address(this).balance >= interestAmount) {
            userAccounts[user].lastDepositTime = block.timestamp; // Reset interest calculation
            
            // Record transaction
            uint256 txIndex = userTransactionCounts[user]++;
            userTransactions[user][txIndex] = Transaction({
                user: user,
                amount: interestAmount,
                timestamp: block.timestamp,
                txType: TransactionType.INTEREST_PAYMENT,
                isProcessed: true
            });

            totalInterestPaid += interestAmount;
            emit KipuBank_InterestPaid(user, interestAmount);
            
            (bool success, bytes memory data) = user.call{value: interestAmount}("");
            if (!success) revert KipuBank_TransferFailed(data);
        }
    }

    /**
     * @notice pauses all contract operations (deposits and withdrawals)
     * @dev restricted to accounts with PAUSER_ROLE
     * @dev when paused, only emergency withdrawals are allowed
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice unpauses contract operations, allowing normal deposits and withdrawals
     * @dev restricted to accounts with PAUSER_ROLE
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @notice emergency withdrawal function for treasury management
     * @param to address to receive the emergency withdrawal
     * @param amount amount of ETH to withdraw (will withdraw all if amount exceeds balance)
     * @dev restricted to accounts with TREASURER_ROLE
     * @dev can only be called when contract is paused
     * @dev transfers available balance if requested amount exceeds contract balance
     */
    function emergencyWithdraw(address to, uint256 amount) external onlyRole(TREASURER_ROLE) whenPaused {
        uint256 balance = address(this).balance;
        uint256 toTransfer = amount > balance ? balance : amount;
        
        // Record transaction
        uint256 txIndex = userTransactionCounts[to]++;
        userTransactions[to][txIndex] = Transaction({
            user: to,
            amount: toTransfer,
            timestamp: block.timestamp,
            txType: TransactionType.EMERGENCY_WITHDRAWAL,
            isProcessed: true
        });
        
        (bool success, bytes memory data) = to.call{value: toTransfer}("");
        if (!success) revert KipuBank_TransferFailed(data);
    }

    /**
     * @notice returns whether the contract supports the given interface
     * @param interfaceId the interface identifier to check
     * @return true if the interface is supported, false otherwise
     * @dev required override for AccessControl compatibility
     */
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice internal function to process the ETH transfer from: contract -> to: user
     * @dev emits an event if success
     */
    function _processTransfer(uint256 _amount) private {
        emit KipuBank_SuccessfullyWithdrawn(msg.sender, _amount);

        (bool success, bytes memory data) = msg.sender.call{value: _amount}("");
        if (!success) revert KipuBank_TransferFailed(data);
    }

    /**
     * @notice external view function to return the contract's balance
     * @return _balance the amount of ETH in the contract
     */
    function contractBalance() external view returns (uint256 _balance) {
        _balance = address(this).balance;
    }

    /**
     * @notice function to get user account information
     * @param user address of the user
     * @return account UserAccount struct with user information
     */
    function getUserAccount(address user) external view returns (UserAccount memory account) {
        return userAccounts[user];
    }

    /**
     * @notice function to get user transaction history
     * @param user address of the user
     * @param index transaction index
     * @return transaction Transaction struct with transaction details
     */
    function getUserTransaction(address user, uint256 index) external view returns (Transaction memory transaction) {
        return userTransactions[user][index];
    }

    /**
     * @notice function to get user transaction count
     * @param user address of the user
     * @return count number of transactions for the user
     */
    function getUserTransactionCount(address user) external view returns (uint256 count) {
        return userTransactionCounts[user];
    }

    /**
     * @notice function to get daily withdrawal amount for a user
     * @param user address of the user
     * @param day day number (timestamp / 1 days)
     * @return amount amount withdrawn on that day
     */
    function getDailyWithdrawal(address user, uint256 day) external view returns (uint256 amount) {
        return dailyWithdrawals[user][day];
    }
}
