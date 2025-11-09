// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title ISessionKey
 * @notice Interface for session key management in EIP-7702 Account Abstraction
 * @dev This interface defines functionality for creating temporary or restricted access keys
 *      that can operate on behalf of an EOA with granular permissions, spending limits,
 *      and time-based expiration. Enables secure delegation without exposing main private keys.
 *
 * @author Qubiter Team
 */
interface ISessionKey {
    /*//////////////////////////////////////////////////////////////
                            TYPE DEFINITIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Permission types for session keys
     * @dev Bitmask-compatible permission system for efficient storage and checking
     */
    enum Permission {
        NONE,           // 0: No permissions
        TRANSFER,       // 1: Can transfer tokens
        APPROVE,        // 2: Can approve token spending
        SWAP,           // 3: Can execute swaps
        STAKE,          // 4: Can stake tokens
        UNSTAKE,        // 5: Can unstake tokens
        VOTE,           // 6: Can vote in governance
        DELEGATE,       // 7: Can delegate voting power
        INTERACT        // 8: Can make arbitrary calls to whitelisted targets
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when a new session key is created
     * @param eoa The EOA that owns this session
     * @param sessionKey The address of the session key
     * @param sessionId The unique identifier for this session
     * @param expiration The expiration timestamp
     * @param dailyLimit The daily spending limit in wei
     */
    event SessionCreated(
        address indexed eoa,
        address indexed sessionKey,
        uint256 indexed sessionId,
        uint256 expiration,
        uint256 dailyLimit
    );

    /**
     * @notice Emitted when a session key is revoked
     * @param eoa The EOA that owned the session
     * @param sessionId The session identifier that was revoked
     * @param revokedBy The address that triggered the revocation
     * @param revokedAt The timestamp of revocation
     */
    event SessionRevoked(
        address indexed eoa,
        uint256 indexed sessionId,
        address revokedBy,
        uint256 revokedAt
    );

    /**
     * @notice Emitted when a session key is used
     * @param eoa The EOA that owns the session
     * @param sessionId The session identifier
     * @param target The target contract called
     * @param value The value sent in the call
     * @param spent The amount spent against daily limit
     */
    event SessionUsed(
        address indexed eoa,
        uint256 indexed sessionId,
        address target,
        uint256 value,
        uint256 spent
    );

    /**
     * @notice Emitted when daily limit is exceeded
     * @param eoa The EOA that owns the session
     * @param sessionId The session identifier
     * @param limit The daily limit
     * @param attempted The attempted amount
     * @param alreadySpent The amount already spent today
     */
    event LimitExceeded(
        address indexed eoa,
        uint256 indexed sessionId,
        uint256 limit,
        uint256 attempted,
        uint256 alreadySpent
    );

    /**
     * @notice Emitted when a session's daily limit is updated
     * @param eoa The EOA that owns the session
     * @param sessionId The session identifier
     * @param oldLimit The previous daily limit
     * @param newLimit The new daily limit
     */
    event DailyLimitUpdated(
        address indexed eoa,
        uint256 indexed sessionId,
        uint256 oldLimit,
        uint256 newLimit
    );

    /**
     * @notice Emitted when a session's expiration is extended
     * @param eoa The EOA that owns the session
     * @param sessionId The session identifier
     * @param oldExpiration The previous expiration
     * @param newExpiration The new expiration
     */
    event SessionExtended(
        address indexed eoa,
        uint256 indexed sessionId,
        uint256 oldExpiration,
        uint256 newExpiration
    );

    /**
     * @notice Emitted when permissions are updated for a session
     * @param eoa The EOA that owns the session
     * @param sessionId The session identifier
     * @param permissions The new permission bitmap
     */
    event PermissionsUpdated(
        address indexed eoa,
        uint256 indexed sessionId,
        uint256 permissions
    );

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Thrown when a session key has expired
     * @param sessionId The expired session identifier
     * @param expiration The expiration timestamp
     * @param currentTime The current timestamp
     */
    error SessionExpired(uint256 sessionId, uint256 expiration, uint256 currentTime);

    /**
     * @notice Thrown when a session key has been revoked
     * @param sessionId The revoked session identifier
     */
    error SessionRevoked(uint256 sessionId);

    /**
     * @notice Thrown when a session key doesn't exist
     * @param sessionId The non-existent session identifier
     */
    error SessionNotFound(uint256 sessionId);

    /**
     * @notice Thrown when caller lacks required permission
     * @param sessionId The session identifier
     * @param required The required permission
     * @param actual The actual permission bitmap
     */
    error InsufficientPermission(uint256 sessionId, Permission required, uint256 actual);

    /**
     * @notice Thrown when daily spending limit is exceeded
     * @param sessionId The session identifier
     * @param limit The daily limit
     * @param attempted The attempted spend amount
     * @param remaining The remaining daily budget
     */
    error DailyLimitExceeded(
        uint256 sessionId,
        uint256 limit,
        uint256 attempted,
        uint256 remaining
    );

    /**
     * @notice Thrown when target is not in the allowed list
     * @param sessionId The session identifier
     * @param target The unauthorized target address
     */
    error TargetNotAllowed(uint256 sessionId, address target);

    /**
     * @notice Thrown when unauthorized caller attempts action
     * @param caller The unauthorized caller
     * @param owner The session owner
     */
    error UnauthorizedCaller(address caller, address owner);

    /**
     * @notice Thrown when attempting to use zero address
     */
    error ZeroAddress();

    /**
     * @notice Thrown when invalid permission bitmap provided
     */
    error InvalidPermissions();

    /**
     * @notice Thrown when expiration time is in the past
     */
    error InvalidExpiration();

    /*//////////////////////////////////////////////////////////////
                         SESSION CREATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Creates a new session key with specified permissions and limits
     * @dev Creates a delegated session key that can act on behalf of the EOA
     *      with restricted permissions, spending limits, and expiration
     *
     * @param sessionKey The address that will be able to use this session
     * @param expiration The timestamp when this session expires (type(uint256).max for no expiry)
     * @param permissions Bitmap of allowed permissions
     * @param dailyLimit Maximum amount that can be spent per day (in wei)
     * @param allowedTargets Array of contract addresses this session can interact with
     * @return sessionId The unique identifier for this session
     *
     * @custom:security Must validate expiration is in the future
     * @custom:security Must validate permissions bitmap is valid
     * @custom:security Must validate session key is not zero address
     */
    function createSession(
        address sessionKey,
        uint256 expiration,
        uint256 permissions,
        uint256 dailyLimit,
        address[] calldata allowedTargets
    ) external returns (uint256 sessionId);

    /**
     * @notice Creates a session key with default permissions
     * @dev Convenience function for creating basic sessions with common settings
     *      Uses default: TRANSFER | APPROVE permissions, no expiry, no daily limit
     *
     * @param sessionKey The address that will use this session
     * @return sessionId The unique identifier for this session
     */
    function createDefaultSession(address sessionKey) external returns (uint256 sessionId);

    /*//////////////////////////////////////////////////////////////
                         SESSION REVOCATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Revokes a session key, preventing any further use
     * @dev Only the EOA owner or the session key itself can revoke
     *      Immediately invalidates the session - cannot be undone
     *
     * @param sessionId The session identifier to revoke
     * @return success True if revocation was successful
     */
    function revokeSession(uint256 sessionId) external returns (bool success);

    /**
     * @notice Revokes all session keys for the caller
     * @dev Emergency function to invalidate all sessions at once
     *      Useful if EOA believes sessions may be compromised
     *
     * @return count The number of sessions revoked
     */
    function revokeAllSessions() external returns (uint256 count);

    /*//////////////////////////////////////////////////////////////
                         PERMISSION CHECKING
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Checks if a session has a specific permission
     * @dev Uses bitmap operations for efficient permission checking
     *
     * @param sessionId The session identifier
     * @param permission The permission to check
     * @return hasPermission True if session has the permission
     */
    function hasPermission(
        uint256 sessionId,
        Permission permission
    ) external view returns (bool hasPermission);

    /**
     * @notice Validates if a session can execute a call
     * @dev Comprehensive validation including:
     *      - Session exists and not revoked
     *      - Session not expired
     *      - Has required permission
     *      - Target is whitelisted
     *      - Daily limit not exceeded
     *
     * @param sessionId The session identifier
     * @param target The target contract
     * @param value The value to send
     * @param data The calldata
     * @return valid True if call can be executed
     * @return reason Human-readable reason if invalid
     */
    function validateSessionCall(
        uint256 sessionId,
        address target,
        uint256 value,
        bytes calldata data
    ) external view returns (bool valid, string memory reason);

    /**
     * @notice Gets all permissions for a session as a bitmap
     * @param sessionId The session identifier
     * @return permissions The permission bitmap
     */
    function getPermissions(uint256 sessionId) external view returns (uint256 permissions);

    /*//////////////////////////////////////////////////////////////
                         DAILY LIMIT MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Checks if a session can spend a certain amount today
     * @dev Compares against daily limit and amount already spent today
     *      Daily limit resets at UTC midnight
     *
     * @param sessionId The session identifier
     * @param amount The amount to check
     * @return canSpend True if amount is within daily limit
     * @return remaining The remaining spendable amount today
     */
    function checkDailyLimit(
        uint256 sessionId,
        uint256 amount
    ) external view returns (bool canSpend, uint256 remaining);

    /**
     * @notice Gets the amount spent today by a session
     * @param sessionId The session identifier
     * @return spent The amount spent today
     * @return limit The daily limit
     * @return resetsAt Timestamp when the limit resets
     */
    function getDailySpending(
        uint256 sessionId
    ) external view returns (uint256 spent, uint256 limit, uint256 resetsAt);

    /**
     * @notice Updates the daily limit for a session
     * @dev Only callable by the session owner
     *
     * @param sessionId The session identifier
     * @param newLimit The new daily limit
     * @return success True if update was successful
     */
    function updateDailyLimit(
        uint256 sessionId,
        uint256 newLimit
    ) external returns (bool success);

    /**
     * @notice Manually resets the daily spending counter
     * @dev Useful for correcting errors or adjusting after limit change
     *      Only callable by session owner
     *
     * @param sessionId The session identifier
     * @return success True if reset was successful
     */
    function resetDailySpending(uint256 sessionId) external returns (bool success);

    /*//////////////////////////////////////////////////////////////
                         SESSION LIFECYCLE
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Extends the expiration of a session
     * @dev Only callable by session owner
     *      Cannot set expiration to past time
     *
     * @param sessionId The session identifier
     * @param newExpiration The new expiration timestamp
     * @return success True if extension was successful
     */
    function extendSession(
        uint256 sessionId,
        uint256 newExpiration
    ) external returns (bool success);

    /**
     * @notice Checks if a session is currently active
     * @dev A session is active if it exists, not revoked, and not expired
     *
     * @param sessionId The session identifier
     * @return active True if session is active
     */
    function isSessionActive(uint256 sessionId) external view returns (bool active);

    /**
     * @notice Gets the expiration timestamp for a session
     * @param sessionId The session identifier
     * @return expiration The expiration timestamp
     */
    function getExpiration(uint256 sessionId) external view returns (uint256 expiration);

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets comprehensive information about a session
     * @param sessionId The session identifier
     * @return owner The EOA that owns this session
     * @return sessionKey The session key address
     * @return expiration The expiration timestamp
     * @return permissions The permission bitmap
     * @return dailyLimit The daily spending limit
     * @return spentToday The amount spent today
     * @return revoked Whether the session is revoked
     * @return active Whether the session is currently active
     */
    function getSessionInfo(
        uint256 sessionId
    ) external view returns (
        address owner,
        address sessionKey,
        uint256 expiration,
        uint256 permissions,
        uint256 dailyLimit,
        uint256 spentToday,
        bool revoked,
        bool active
    );

    /**
     * @notice Gets all session IDs for an EOA
     * @param eoa The EOA address
     * @return sessionIds Array of session identifiers
     */
    function getSessionsForEOA(address eoa) external view returns (uint256[] memory sessionIds);

    /**
     * @notice Gets all active session IDs for an EOA
     * @param eoa The EOA address
     * @return sessionIds Array of active session identifiers
     */
    function getActiveSessionsForEOA(
        address eoa
    ) external view returns (uint256[] memory sessionIds);

    /**
     * @notice Gets the allowed targets for a session
     * @param sessionId The session identifier
     * @return targets Array of allowed target addresses
     */
    function getAllowedTargets(
        uint256 sessionId
    ) external view returns (address[] memory targets);

    /**
     * @notice Checks if a target is allowed for a session
     * @param sessionId The session identifier
     * @param target The target address to check
     * @return allowed True if target is allowed
     */
    function isTargetAllowed(
        uint256 sessionId,
        address target
    ) external view returns (bool allowed);
}
