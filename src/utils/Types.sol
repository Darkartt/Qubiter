// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title Types
 * @notice Core type definitions and data structures for EIP-7702 Account Abstraction
 * @dev Focused, essential structures optimized for storage packing and gas efficiency.
 *      All structs are carefully packed to minimize storage slots.
 *
 * @author Qubiter Team
 */
library Types {
    /*//////////////////////////////////////////////////////////////
                            CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Maximum expiration timestamp (never expires)
    uint256 internal constant MAX_EXPIRATION = type(uint256).max;

    /// @notice Minimum daily limit (1 wei)
    uint256 internal constant MIN_DAILY_LIMIT = 1;

    /// @notice Permission bitmap masks
    uint8 internal constant PERMISSION_SWAP = 1;      // 0001
    uint8 internal constant PERMISSION_TRANSFER = 2;  // 0010
    uint8 internal constant PERMISSION_APPROVE = 4;   // 0100
    uint8 internal constant PERMISSION_INTERACT = 8;  // 1000

    /// @notice All permissions combined
    uint8 internal constant PERMISSION_ALL = 15;      // 1111

    /// @notice No permissions
    uint8 internal constant PERMISSION_NONE = 0;      // 0000

    /*//////////////////////////////////////////////////////////////
                            ENUMS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Permission types for session keys
     * @dev Used as bitmap for efficient permission checking
     *      SWAP = 1 (bit 0): Can execute token swaps
     *      TRANSFER = 2 (bit 1): Can transfer tokens
     *      APPROVE = 4 (bit 2): Can approve token spending
     *      INTERACT = 8 (bit 3): Can interact with whitelisted contracts
     */
    enum Permission {
        SWAP,       // 0: Swap tokens
        TRANSFER,   // 1: Transfer tokens
        APPROVE,    // 2: Approve spending
        INTERACT    // 3: General interaction
    }

    /*//////////////////////////////////////////////////////////////
                         AUTHORIZATION TYPES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Authorization data structure for EIP-7702 delegation
     * @dev Storage packing: 4 slots
     *      Slot 1: authority (20 bytes) + vacant (12 bytes)
     *      Slot 2: delegatedTo (20 bytes) + vacant (12 bytes)
     *      Slot 3: nonce (32 bytes)
     *      Slot 4: validUntil (32 bytes)
     *
     * @param authority The address that signed this authorization (the authorizer)
     * @param delegatedTo The address receiving the delegation rights
     * @param nonce The nonce for replay protection (must match current authority nonce)
     * @param validUntil The expiration timestamp (use MAX_EXPIRATION for non-expiring)
     */
    struct Authorization {
        address authority;      // Address that signs the authorization
        address delegatedTo;    // Address that receives delegation
        uint256 nonce;          // Replay protection nonce
        uint256 validUntil;     // Expiration timestamp
    }

    /*//////////////////////////////////////////////////////////////
                         SESSION KEY TYPES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Session key policy defining permissions and limits
     * @dev Optimized packing: ~4-5 slots (depending on allowedTargets array)
     *      Slot 1: permissions (1 byte) + vacant (31 bytes)
     *      Slot 2: dailyLimit (32 bytes)
     *      Slot 3: spent (32 bytes)
     *      Slot 4: lastReset (32 bytes)
     *      Slot 5: expiration (32 bytes)
     *      Slot 6+: allowedTargets[] (dynamic array)
     *
     * @param permissions Bitmap of allowed permissions (uint8 for gas efficiency)
     *                    Bit 0 (1): SWAP
     *                    Bit 1 (2): TRANSFER
     *                    Bit 2 (4): APPROVE
     *                    Bit 3 (8): INTERACT
     * @param dailyLimit Maximum amount that can be spent per day (in wei)
     * @param spent Amount already spent in current period
     * @param lastReset Timestamp of last daily limit reset (UTC midnight)
     * @param allowedTargets Whitelist of contract addresses this session can interact with
     * @param expiration Timestamp when this session expires (use MAX_EXPIRATION for permanent)
     */
    struct SessionKeyPolicy {
        uint8 permissions;          // Permission bitmap (1 byte)
        uint256 dailyLimit;         // Daily spending limit in wei
        uint256 spent;              // Amount spent in current period
        uint256 lastReset;          // Last reset timestamp
        address[] allowedTargets;   // Whitelisted target contracts
        uint256 expiration;         // Session expiration time
    }

    /*//////////////////////////////////////////////////////////////
                         PAYMASTER TYPES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Paymaster budget tracking for gas sponsorship
     * @dev Optimized packing: 4-5 slots (depending on allowedTargets)
     *      Slot 1: sponsor (20 bytes) + paused (1 byte) + vacant (11 bytes)
     *      Slot 2: totalBudget (32 bytes)
     *      Slot 3: spent (32 bytes)
     *      Slot 4+: allowedTargets[] (dynamic array)
     *
     * @param sponsor The address providing gas sponsorship funds
     * @param totalBudget Total budget allocated for sponsorship (in wei)
     * @param spent Amount of budget already spent on gas sponsorship
     * @param allowedTargets Whitelist of contracts that can be sponsored
     *                       Empty array means all targets allowed
     * @param paused Emergency pause flag to stop all sponsorships
     */
    struct PaymasterBudget {
        address sponsor;            // Sponsor address (20 bytes)
        uint256 totalBudget;        // Total allocated budget
        uint256 spent;              // Amount spent so far
        address[] allowedTargets;   // Target whitelist
        bool paused;                // Pause flag for emergency stop
    }

    /*//////////////////////////////////////////////////////////////
                         BATCH EXECUTION TYPES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Call data for batch/multi-call execution
     * @dev Used in batch transaction execution and delegation
     *      Dynamic size based on data length
     *
     * @param target The contract address to call
     * @param value The amount of ETH to send with the call (in wei)
     * @param data The calldata to send to the target contract
     */
    struct Call {
        address target;     // Target contract address
        uint256 value;      // ETH value to send
        bytes data;         // Calldata for the call
    }

    /*//////////////////////////////////////////////////////////////
                         HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Checks if a specific permission is set in a bitmap
     * @dev Uses bitwise AND to check if permission bit is set
     *      Example: hasPermission(6, Permission.TRANSFER) returns true
     *               because 6 = 0110 and TRANSFER = 0010
     *
     * @param bitmap The permission bitmap to check
     * @param permission The permission to verify
     * @return True if the permission is granted
     */
    function hasPermission(
        uint8 bitmap,
        Permission permission
    ) internal pure returns (bool) {
        return (bitmap & (1 << uint8(permission))) != 0;
    }

    /**
     * @notice Adds a permission to a bitmap
     * @dev Uses bitwise OR to set the permission bit
     *
     * @param bitmap The current permission bitmap
     * @param permission The permission to add
     * @return The updated permission bitmap
     */
    function addPermission(
        uint8 bitmap,
        Permission permission
    ) internal pure returns (uint8) {
        return bitmap | (1 << uint8(permission));
    }

    /**
     * @notice Removes a permission from a bitmap
     * @dev Uses bitwise AND with negated mask to clear the permission bit
     *
     * @param bitmap The current permission bitmap
     * @param permission The permission to remove
     * @return The updated permission bitmap
     */
    function removePermission(
        uint8 bitmap,
        Permission permission
    ) internal pure returns (uint8) {
        return bitmap & ~(1 << uint8(permission));
    }

    /**
     * @notice Checks if all specified permissions are granted
     * @dev Verifies that all bits in required are set in bitmap
     *
     * @param bitmap The permission bitmap to check
     * @param required The required permissions bitmap
     * @return True if all required permissions are present
     */
    function hasAllPermissions(
        uint8 bitmap,
        uint8 required
    ) internal pure returns (bool) {
        return (bitmap & required) == required;
    }

    /**
     * @notice Checks if any of the specified permissions are granted
     * @dev Verifies that at least one bit in required is set in bitmap
     *
     * @param bitmap The permission bitmap to check
     * @param required The required permissions bitmap
     * @return True if any required permission is present
     */
    function hasAnyPermission(
        uint8 bitmap,
        uint8 required
    ) internal pure returns (bool) {
        return (bitmap & required) != 0;
    }

    /**
     * @notice Creates a permission bitmap from an array of permissions
     * @dev Combines multiple Permission enum values into a single bitmap
     *
     * @param permissions Array of Permission enum values
     * @return The combined permission bitmap
     */
    function createPermissionBitmap(
        Permission[] memory permissions
    ) internal pure returns (uint8) {
        uint8 bitmap = 0;
        for (uint256 i = 0; i < permissions.length; i++) {
            bitmap = addPermission(bitmap, permissions[i]);
        }
        return bitmap;
    }

    /**
     * @notice Checks if an authorization has expired
     * @dev Compares validUntil against current block timestamp
     *
     * @param auth The authorization to check
     * @return True if the authorization has expired
     */
    function isExpired(Authorization memory auth) internal view returns (bool) {
        return block.timestamp > auth.validUntil;
    }

    /**
     * @notice Checks if a session key policy has expired
     * @dev Compares expiration against current block timestamp
     *
     * @param policy The session key policy to check
     * @return True if the session has expired
     */
    function isSessionExpired(
        SessionKeyPolicy memory policy
    ) internal view returns (bool) {
        return block.timestamp > policy.expiration;
    }

    /**
     * @notice Checks if daily limit needs to be reset
     * @dev Compares lastReset with current day boundary (UTC midnight)
     *
     * @param policy The session key policy to check
     * @return True if a new day has started since lastReset
     */
    function shouldResetDailyLimit(
        SessionKeyPolicy memory policy
    ) internal view returns (bool) {
        // Calculate current day start (UTC midnight)
        uint256 currentDayStart = (block.timestamp / 1 days) * 1 days;
        return policy.lastReset < currentDayStart;
    }

    /**
     * @notice Checks if spending is within daily limit
     * @dev Accounts for automatic reset if new day has started
     *
     * @param policy The session key policy to check
     * @param amount The amount to spend
     * @return canSpend True if spending is allowed
     * @return remaining The remaining spendable amount
     */
    function checkDailyLimit(
        SessionKeyPolicy memory policy,
        uint256 amount
    ) internal view returns (bool canSpend, uint256 remaining) {
        // If new day, full limit is available
        if (shouldResetDailyLimit(policy)) {
            canSpend = amount <= policy.dailyLimit;
            remaining = canSpend ? policy.dailyLimit - amount : 0;
        } else {
            // Check against already spent amount
            uint256 available = policy.dailyLimit > policy.spent
                ? policy.dailyLimit - policy.spent
                : 0;
            canSpend = amount <= available;
            remaining = canSpend ? available - amount : 0;
        }
    }

    /**
     * @notice Validates if a target is in the allowed list
     * @dev Returns true if allowedTargets is empty (all allowed) or target is in list
     *
     * @param allowedTargets The whitelist of allowed targets
     * @param target The target to validate
     * @return True if the target is allowed
     */
    function isTargetAllowed(
        address[] memory allowedTargets,
        address target
    ) internal pure returns (bool) {
        // Empty array means all targets allowed
        if (allowedTargets.length == 0) {
            return true;
        }

        // Check if target is in whitelist
        for (uint256 i = 0; i < allowedTargets.length; i++) {
            if (allowedTargets[i] == target) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Checks if a paymaster has sufficient budget
     * @dev Compares remaining budget (total - spent) against required amount
     *
     * @param budget The paymaster budget to check
     * @param amount The required amount
     * @return True if sufficient budget is available
     */
    function hasSufficientBudget(
        PaymasterBudget memory budget,
        uint256 amount
    ) internal pure returns (bool) {
        return !budget.paused &&
               budget.totalBudget >= budget.spent &&
               (budget.totalBudget - budget.spent) >= amount;
    }

    /**
     * @notice Gets the remaining budget for a paymaster
     * @param budget The paymaster budget
     * @return The remaining budget amount
     */
    function getRemainingBudget(
        PaymasterBudget memory budget
    ) internal pure returns (uint256) {
        if (budget.paused || budget.spent >= budget.totalBudget) {
            return 0;
        }
        return budget.totalBudget - budget.spent;
    }
}
