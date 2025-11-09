// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title IPaymaster
 * @notice Interface for gas sponsorship and paymaster functionality in EIP-7702
 * @dev This interface defines functionality for sponsors to pay gas fees on behalf of users.
 *      Implements budget tracking, whitelist management, and gas limit enforcement to
 *      prevent abuse and ensure sponsors maintain control over their funds.
 *
 * @author Qubiter Team
 */
interface IPaymaster {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when a new sponsor is registered
     * @param sponsor The address of the sponsor
     * @param initialBudget The initial budget allocated in wei
     * @param registeredAt The timestamp of registration
     */
    event SponsorRegistered(
        address indexed sponsor,
        uint256 initialBudget,
        uint256 registeredAt
    );

    /**
     * @notice Emitted when a sponsor's budget is updated
     * @param sponsor The address of the sponsor
     * @param oldBudget The previous budget amount
     * @param newBudget The new budget amount
     * @param updatedBy The address that triggered the update
     */
    event BudgetUpdated(
        address indexed sponsor,
        uint256 oldBudget,
        uint256 newBudget,
        address indexed updatedBy
    );

    /**
     * @notice Emitted when a transaction is successfully sponsored
     * @param sponsor The address that sponsored the transaction
     * @param user The user whose transaction was sponsored
     * @param target The target contract address
     * @param gasUsed The amount of gas consumed
     * @param gasCost The cost in wei of the gas used
     */
    event TransactionSponsored(
        address indexed sponsor,
        address indexed user,
        address target,
        uint256 gasUsed,
        uint256 gasCost
    );

    /**
     * @notice Emitted when a sponsor is revoked
     * @param sponsor The address of the revoked sponsor
     * @param remainingBudget The budget returned to the sponsor
     * @param revokedAt The timestamp of revocation
     */
    event SponsorRevoked(
        address indexed sponsor,
        uint256 remainingBudget,
        uint256 revokedAt
    );

    /**
     * @notice Emitted when a target is added to sponsor's whitelist
     * @param sponsor The sponsor address
     * @param target The whitelisted target address
     */
    event TargetWhitelisted(
        address indexed sponsor,
        address indexed target
    );

    /**
     * @notice Emitted when a target is removed from sponsor's whitelist
     * @param sponsor The sponsor address
     * @param target The removed target address
     */
    event TargetRemovedFromWhitelist(
        address indexed sponsor,
        address indexed target
    );

    /**
     * @notice Emitted when gas limit is updated for a sponsor
     * @param sponsor The sponsor address
     * @param oldLimit The previous gas limit
     * @param newLimit The new gas limit
     */
    event GasLimitUpdated(
        address indexed sponsor,
        uint256 oldLimit,
        uint256 newLimit
    );

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Thrown when sponsor has insufficient budget
     * @param sponsor The sponsor address
     * @param required The required budget amount
     * @param available The available budget amount
     */
    error InsufficientBudget(
        address sponsor,
        uint256 required,
        uint256 available
    );

    /**
     * @notice Thrown when a sponsor is not registered
     * @param sponsor The unregistered sponsor address
     */
    error SponsorNotRegistered(address sponsor);

    /**
     * @notice Thrown when trying to register an already registered sponsor
     * @param sponsor The already registered sponsor address
     */
    error SponsorAlreadyRegistered(address sponsor);

    /**
     * @notice Thrown when target is not whitelisted for sponsor
     * @param sponsor The sponsor address
     * @param target The non-whitelisted target
     */
    error TargetNotWhitelisted(address sponsor, address target);

    /**
     * @notice Thrown when gas limit is exceeded
     * @param limit The gas limit
     * @param requested The requested gas amount
     */
    error GasLimitExceeded(uint256 limit, uint256 requested);

    /**
     * @notice Thrown when attempting to sponsor with zero budget
     */
    error ZeroBudget();

    /**
     * @notice Thrown when unauthorized caller attempts restricted action
     * @param caller The unauthorized caller
     * @param sponsor The sponsor address
     */
    error UnauthorizedCaller(address caller, address sponsor);

    /**
     * @notice Thrown when attempting to use zero address
     */
    error ZeroAddress();

    /**
     * @notice Thrown when budget withdrawal fails
     */
    error WithdrawalFailed();

    /*//////////////////////////////////////////////////////////////
                         SPONSOR REGISTRATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Registers a new sponsor with initial budget
     * @dev Creates a new sponsor entry and allocates budget from msg.value
     *      Sponsor can later add more budget or withdraw remaining funds
     *
     * @param sponsor The address to register as sponsor (can be msg.sender or delegated)
     * @return success True if registration was successful
     *
     * @custom:security Must validate sponsor is not already registered
     * @custom:security Must validate msg.value > 0
     */
    function registerSponsor(address sponsor) external payable returns (bool success);

    /**
     * @notice Adds budget to an existing sponsor
     * @dev Allows sponsor to increase their available budget
     *
     * @param sponsor The sponsor address to add budget to
     * @return newBudget The total budget after addition
     */
    function addBudget(address sponsor) external payable returns (uint256 newBudget);

    /**
     * @notice Revokes a sponsor and returns remaining budget
     * @dev Only callable by the sponsor themselves
     *      Transfers remaining budget back to sponsor
     *
     * @return refundedAmount The amount refunded to the sponsor
     *
     * @custom:security Must validate caller is the sponsor
     * @custom:security Must handle reentrancy safely
     */
    function revokeSponsor() external returns (uint256 refundedAmount);

    /*//////////////////////////////////////////////////////////////
                         SPONSORSHIP EXECUTION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sponsors a transaction for a user
     * @dev Validates sponsorship criteria and pays gas cost from sponsor budget:
     *      1. Check sponsor has sufficient budget
     *      2. Verify target is whitelisted (if whitelist enabled)
     *      3. Check gas limit not exceeded
     *      4. Execute transaction
     *      5. Deduct gas cost from sponsor budget
     *
     * @param sponsor The sponsor paying for gas
     * @param target The target contract address
     * @param data The calldata for the transaction
     * @param gasLimit The maximum gas allowed for this transaction
     * @return success True if sponsorship was successful
     * @return gasUsed The actual gas consumed
     *
     * @custom:security Must validate all parameters before execution
     * @custom:security Must protect against reentrancy
     * @custom:security Must accurately track gas consumption
     */
    function sponsorTransaction(
        address sponsor,
        address target,
        bytes calldata data,
        uint256 gasLimit
    ) external returns (bool success, uint256 gasUsed);

    /**
     * @notice Validates if a transaction can be sponsored without executing it
     * @dev Performs all sponsorship checks without state modification
     *
     * @param sponsor The sponsor address
     * @param target The target contract
     * @param estimatedGas The estimated gas cost
     * @return canSponsor True if the transaction can be sponsored
     * @return reason Human-readable reason if cannot sponsor
     */
    function canSponsorTransaction(
        address sponsor,
        address target,
        uint256 estimatedGas
    ) external view returns (bool canSponsor, string memory reason);

    /*//////////////////////////////////////////////////////////////
                         BUDGET MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the remaining budget for a sponsor
     * @param sponsor The sponsor address
     * @return remaining The remaining budget in wei
     */
    function getBudgetRemaining(address sponsor) external view returns (uint256 remaining);

    /**
     * @notice Gets total budget spent by a sponsor
     * @param sponsor The sponsor address
     * @return spent The total amount spent in wei
     */
    function getBudgetSpent(address sponsor) external view returns (uint256 spent);

    /**
     * @notice Updates the budget for a sponsor
     * @dev Only callable by sponsor themselves
     *      Can be used to reduce budget (excess returned) or increase (requires payment)
     *
     * @param newBudget The new budget amount
     * @return success True if update was successful
     */
    function updateBudget(uint256 newBudget) external payable returns (bool success);

    /**
     * @notice Withdraws excess budget from sponsor allocation
     * @dev Allows sponsor to withdraw funds they no longer want allocated
     *
     * @param amount The amount to withdraw
     * @return success True if withdrawal was successful
     */
    function withdrawBudget(uint256 amount) external returns (bool success);

    /*//////////////////////////////////////////////////////////////
                         WHITELIST MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Adds a target address to sponsor's whitelist
     * @dev Only whitelisted targets can be sponsored by this sponsor
     *      Sponsor can only modify their own whitelist
     *
     * @param target The target address to whitelist
     * @return success True if target was added
     */
    function addToWhitelist(address target) external returns (bool success);

    /**
     * @notice Removes a target address from sponsor's whitelist
     * @param target The target address to remove
     * @return success True if target was removed
     */
    function removeFromWhitelist(address target) external returns (bool success);

    /**
     * @notice Checks if a target is whitelisted for a sponsor
     * @param sponsor The sponsor address
     * @param target The target address to check
     * @return whitelisted True if target is whitelisted
     */
    function isWhitelisted(
        address sponsor,
        address target
    ) external view returns (bool whitelisted);

    /**
     * @notice Gets all whitelisted targets for a sponsor
     * @param sponsor The sponsor address
     * @return targets Array of whitelisted addresses
     */
    function getWhitelistedTargets(
        address sponsor
    ) external view returns (address[] memory targets);

    /*//////////////////////////////////////////////////////////////
                         GAS LIMIT MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the maximum gas limit per transaction for a sponsor
     * @dev Prevents individual transactions from consuming too much of the budget
     *      Only callable by the sponsor themselves
     *
     * @param gasLimit The new gas limit
     * @return success True if gas limit was updated
     */
    function setGasLimit(uint256 gasLimit) external returns (bool success);

    /**
     * @notice Gets the gas limit for a sponsor
     * @param sponsor The sponsor address
     * @return limit The current gas limit
     */
    function getGasLimit(address sponsor) external view returns (uint256 limit);

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets comprehensive information about a sponsor
     * @param sponsor The sponsor address
     * @return registered Whether the sponsor is registered
     * @return budgetRemaining The remaining budget
     * @return budgetSpent The total spent
     * @return gasLimit The per-transaction gas limit
     * @return whitelistEnabled Whether whitelist is enforced
     */
    function getSponsorInfo(
        address sponsor
    ) external view returns (
        bool registered,
        uint256 budgetRemaining,
        uint256 budgetSpent,
        uint256 gasLimit,
        bool whitelistEnabled
    );

    /**
     * @notice Checks if a sponsor is active and can sponsor transactions
     * @param sponsor The sponsor address
     * @return active True if sponsor is registered and has budget
     */
    function isSponsorActive(address sponsor) external view returns (bool active);
}
