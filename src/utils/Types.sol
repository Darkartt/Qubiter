// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title Types
 * @notice Core type definitions and data structures for EIP-7702 Account Abstraction
 * @dev This library contains all shared data structures used across the authorization,
 *      paymaster, and session key components. Structures are optimized for storage
 *      packing to minimize gas costs.
 *
 * @author Qubiter Team
 */
library Types {
    /*//////////////////////////////////////////////////////////////
                         AUTHORIZATION TYPES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Authorization data structure for EIP-7702 delegation
     * @dev Packed to optimize storage: 3 slots total
     *      Slot 1: authority (20 bytes) + vacant (12 bytes)
     *      Slot 2: nonce (32 bytes)
     *      Slot 3: validUntil (32 bytes)
     *
     * @param authority The address that signed this authorization
     * @param nonce The nonce for replay protection (must match current nonce)
     * @param validUntil The expiration timestamp (type(uint256).max for non-expiring)
     */
    struct Authorization {
        address authority;      // 20 bytes
        uint256 nonce;         // 32 bytes
        uint256 validUntil;    // 32 bytes
    }

    /**
     * @notice Authorization status tracking
     * @dev Tracks the state of an authority's authorization capability
     *
     * @param currentNonce The current nonce (increments with each use)
     * @param revoked Whether all authorizations are revoked
     * @param lastUsed Timestamp of last authorization use
     * @param totalUsed Total number of authorizations used
     */
    struct AuthorizationStatus {
        uint256 currentNonce;   // Current nonce value
        bool revoked;           // Global revocation flag
        uint96 lastUsed;        // Timestamp of last use (fits in uint96 until year ~2500)
        uint160 totalUsed;      // Total authorizations used
    }

    /*//////////////////////////////////////////////////////////////
                         PAYMASTER TYPES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sponsor data for gas sponsorship
     * @dev Optimized packing: 3 slots
     *      Slot 1: registered (1 byte) + whitelistEnabled (1 byte) + vacant (30 bytes)
     *      Slot 2: budgetRemaining (32 bytes)
     *      Slot 3: budgetSpent (32 bytes)
     *      Slot 4: gasLimit (32 bytes)
     *
     * @param registered Whether the sponsor is registered
     * @param whitelistEnabled Whether whitelist enforcement is active
     * @param budgetRemaining Remaining budget in wei
     * @param budgetSpent Total amount spent in wei
     * @param gasLimit Maximum gas per transaction
     * @param registeredAt Timestamp when sponsor was registered
     */
    struct Sponsor {
        bool registered;           // 1 byte
        bool whitelistEnabled;     // 1 byte
        uint256 budgetRemaining;   // 32 bytes
        uint256 budgetSpent;       // 32 bytes
        uint256 gasLimit;          // 32 bytes
        uint96 registeredAt;       // Timestamp (12 bytes, fits until ~year 2500)
    }

    /**
     * @notice Transaction sponsorship record
     * @dev Records details of a sponsored transaction for accounting
     *
     * @param sponsor The sponsor that paid for the transaction
     * @param user The user whose transaction was sponsored
     * @param target The target contract
     * @param gasUsed The actual gas consumed
     * @param gasCost The cost in wei
     * @param timestamp When the transaction was sponsored
     */
    struct SponsorshipRecord {
        address sponsor;      // 20 bytes
        address user;         // 20 bytes
        address target;       // 20 bytes
        uint64 gasUsed;       // Gas used (64 bits is plenty for gas)
        uint96 gasCost;       // Cost in wei (96 bits for reasonable amounts)
        uint96 timestamp;     // Timestamp
    }

    /*//////////////////////////////////////////////////////////////
                         SESSION KEY TYPES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Session key data structure
     * @dev Optimized for storage packing
     *      Contains all information needed to validate and execute session key operations
     *
     * @param owner The EOA that owns this session
     * @param sessionKey The address authorized to use this session
     * @param expiration When this session expires (type(uint256).max for no expiry)
     * @param permissions Bitmap of allowed permissions
     * @param dailyLimit Maximum amount spendable per day (wei)
     * @param spentToday Amount spent in current day
     * @param lastResetDay The day (in days since epoch) when spending was last reset
     * @param revoked Whether this session has been revoked
     * @param createdAt Timestamp when session was created
     */
    struct SessionKey {
        address owner;              // 20 bytes - EOA owner
        address sessionKey;         // 20 bytes - Session key address
        uint256 expiration;         // 32 bytes - Expiration timestamp
        uint256 permissions;        // 32 bytes - Permission bitmap
        uint256 dailyLimit;         // 32 bytes - Daily spending limit
        uint256 spentToday;         // 32 bytes - Amount spent today
        uint32 lastResetDay;        // 4 bytes - Last reset day
        bool revoked;               // 1 byte - Revocation status
        uint96 createdAt;           // 12 bytes - Creation timestamp
    }

    /**
     * @notice Session key policy for granular permission control
     * @dev Defines what operations a session key can perform
     *
     * @param permissions Bitmap of Permission enum values
     * @param allowedTargets Array of contract addresses the session can interact with
     * @param dailyLimit Maximum daily spending in wei (0 for unlimited)
     * @param expiration Expiration timestamp
     */
    struct SessionKeyPolicy {
        uint256 permissions;           // Permission bitmap
        address[] allowedTargets;      // Whitelisted contracts
        uint256 dailyLimit;            // Daily spending limit
        uint256 expiration;            // Expiration time
    }

    /*//////////////////////////////////////////////////////////////
                         BATCH EXECUTION TYPES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Call data for batch execution
     * @dev Used in batch transaction execution
     *
     * @param target The contract to call
     * @param value The ETH value to send
     * @param data The calldata
     */
    struct Call {
        address target;     // 20 bytes - Target contract
        uint256 value;      // 32 bytes - ETH value
        bytes data;         // Variable - Calldata
    }

    /**
     * @notice Result of a batch call execution
     * @dev Contains execution results and gas information
     *
     * @param success Whether the call succeeded
     * @param returnData The return data from the call
     * @param gasUsed Gas consumed by this specific call
     */
    struct CallResult {
        bool success;           // Whether call succeeded
        bytes returnData;       // Return data
        uint256 gasUsed;        // Gas consumed
    }

    /*//////////////////////////////////////////////////////////////
                         UTILITY TYPES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Time window for rate limiting or validation
     * @param start Start timestamp
     * @param end End timestamp
     */
    struct TimeWindow {
        uint96 start;      // Start time (12 bytes)
        uint96 end;        // End time (12 bytes)
    }

    /**
     * @notice Rate limit configuration
     * @dev Used for implementing rate limiting on operations
     *
     * @param maxAmount Maximum amount in time window
     * @param windowDuration Duration of the window in seconds
     * @param currentAmount Amount used in current window
     * @param windowStart When current window started
     */
    struct RateLimit {
        uint256 maxAmount;          // Maximum per window
        uint32 windowDuration;      // Window duration in seconds
        uint256 currentAmount;      // Current usage
        uint96 windowStart;         // Window start time
    }

    /*//////////////////////////////////////////////////////////////
                         HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Calculates the current day number since epoch
     * @dev Used for daily limit tracking. Days are in UTC.
     * @return day The current day number (days since Unix epoch)
     */
    function getCurrentDay() internal view returns (uint32 day) {
        return uint32(block.timestamp / 1 days);
    }

    /**
     * @notice Checks if a time window is currently active
     * @param window The time window to check
     * @return active True if current time is within the window
     */
    function isWindowActive(TimeWindow memory window) internal view returns (bool active) {
        return block.timestamp >= window.start && block.timestamp <= window.end;
    }

    /**
     * @notice Checks if a timestamp has passed
     * @param timestamp The timestamp to check
     * @return expired True if the timestamp is in the past
     */
    function isExpired(uint256 timestamp) internal view returns (bool expired) {
        return block.timestamp > timestamp;
    }

    /**
     * @notice Validates an authorization structure
     * @dev Checks for basic validity (non-zero addresses, valid timestamps)
     * @param auth The authorization to validate
     * @return valid True if authorization structure is valid
     */
    function isAuthorizationValid(
        Authorization memory auth
    ) internal view returns (bool valid) {
        return auth.authority != address(0) && !isExpired(auth.validUntil);
    }

    /**
     * @notice Checks if a rate limit has been exceeded
     * @dev Automatically resets window if expired
     * @param limit The rate limit configuration
     * @param amount The amount to check
     * @return exceeded True if adding amount would exceed limit
     * @return remaining The remaining amount available
     */
    function checkRateLimit(
        RateLimit memory limit,
        uint256 amount
    ) internal view returns (bool exceeded, uint256 remaining) {
        // Check if window has expired
        if (block.timestamp >= limit.windowStart + limit.windowDuration) {
            // Window expired, amount fits in new window
            exceeded = amount > limit.maxAmount;
            remaining = limit.maxAmount;
        } else {
            // Check current window
            uint256 newAmount = limit.currentAmount + amount;
            exceeded = newAmount > limit.maxAmount;
            remaining = exceeded ? 0 : limit.maxAmount - newAmount;
        }
    }

    /**
     * @notice Updates a rate limit with a new amount
     * @dev Handles window rotation automatically
     * @param limit The rate limit to update
     * @param amount The amount to add
     */
    function updateRateLimit(
        RateLimit storage limit,
        uint256 amount
    ) internal {
        // Check if we need to reset the window
        if (block.timestamp >= limit.windowStart + limit.windowDuration) {
            limit.windowStart = uint96(block.timestamp);
            limit.currentAmount = amount;
        } else {
            limit.currentAmount += amount;
        }
    }

    /**
     * @notice Packs permission enum into bitmap
     * @dev Converts array of permissions into bitmap for storage
     * @param permissions Array of permission values
     * @return bitmap The packed permission bitmap
     */
    function packPermissions(
        uint8[] memory permissions
    ) internal pure returns (uint256 bitmap) {
        for (uint256 i = 0; i < permissions.length; i++) {
            bitmap |= (1 << permissions[i]);
        }
    }

    /**
     * @notice Checks if a permission is set in a bitmap
     * @param bitmap The permission bitmap
     * @param permission The permission to check
     * @return hasPermission True if permission is set
     */
    function hasPermission(
        uint256 bitmap,
        uint8 permission
    ) internal pure returns (bool hasPermission) {
        return (bitmap & (1 << permission)) != 0;
    }

    /**
     * @notice Combines multiple permission bitmaps
     * @param bitmaps Array of permission bitmaps
     * @return combined The combined bitmap
     */
    function combinePermissions(
        uint256[] memory bitmaps
    ) internal pure returns (uint256 combined) {
        for (uint256 i = 0; i < bitmaps.length; i++) {
            combined |= bitmaps[i];
        }
    }
}
