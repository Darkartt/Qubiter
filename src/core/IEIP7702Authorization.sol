// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title IEIP7702Authorization
 * @notice Interface for EIP-7702 authorization validation and management
 * @dev This interface defines the core functionality for validating authorization signatures,
 *      managing nonces to prevent replay attacks, and checking expiration timestamps.
 *      Implementations must ensure secure signature recovery and proper nonce tracking.
 *
 * @author Qubiter Team
 */
interface IEIP7702Authorization {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when an authorization is successfully validated and used
     * @param authority The address that signed the authorization
     * @param nonce The nonce value used in this authorization
     * @param validUntil The expiration timestamp of the authorization
     */
    event AuthorizationUsed(
        address indexed authority,
        uint256 indexed nonce,
        uint256 validUntil
    );

    /**
     * @notice Emitted when a nonce is incremented for an authority
     * @param authority The address whose nonce was incremented
     * @param oldNonce The previous nonce value
     * @param newNonce The new nonce value
     */
    event NonceIncremented(
        address indexed authority,
        uint256 oldNonce,
        uint256 newNonce
    );

    /**
     * @notice Emitted when an authorization is revoked
     * @param authority The address whose authorization was revoked
     * @param revokedAt The timestamp when the authorization was revoked
     */
    event AuthorizationRevoked(
        address indexed authority,
        uint256 revokedAt
    );

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Thrown when signature recovery fails or signature is invalid
     * @param authority The expected authority address
     * @param recovered The address recovered from the signature
     */
    error InvalidSignature(address authority, address recovered);

    /**
     * @notice Thrown when an authorization has expired
     * @param validUntil The expiration timestamp
     * @param currentTime The current block timestamp
     */
    error ExpiredAuthorization(uint256 validUntil, uint256 currentTime);

    /**
     * @notice Thrown when the nonce doesn't match expected value
     * @param expected The expected nonce value
     * @param provided The provided nonce value
     */
    error InvalidNonce(uint256 expected, uint256 provided);

    /**
     * @notice Thrown when an authorization has been revoked
     * @param authority The authority whose authorization was revoked
     */
    error RevokedAuthorization(address authority);

    /**
     * @notice Thrown when the authorization digest is invalid
     */
    error InvalidDigest();

    /**
     * @notice Thrown when attempting to use a zero address as authority
     */
    error ZeroAddress();

    /*//////////////////////////////////////////////////////////////
                         AUTHORIZATION VALIDATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Validates an authorization signature against a digest
     * @dev This function should:
     *      1. Recover the signer from the authorization signature
     *      2. Verify the signer matches the expected authority
     *      3. Check that the authorization hasn't expired
     *      4. Verify the nonce to prevent replay attacks
     *      5. Mark the authorization as used (increment nonce)
     *
     * @param authorization The encoded authorization data (typically signature + metadata)
     * @param digest The digest that was signed by the authority
     * @return valid True if the authorization is valid and can be used
     *
     * @custom:security This function must be resistant to signature malleability attacks
     * @custom:security Must properly validate all parameters before state changes
     */
    function validateAuthorization(
        bytes memory authorization,
        bytes32 digest
    ) external returns (bool valid);

    /**
     * @notice Recovers the authority address from an authorization signature
     * @dev Uses ECDSA signature recovery (ecrecover) to extract the signer
     *      This is a view function and doesn't modify state
     *
     * @param authorization The encoded authorization data
     * @param digest The digest that was signed
     * @return authority The recovered authority address
     *
     * @custom:security Must handle signature malleability (use proper s value range)
     */
    function recoverAuthority(
        bytes memory authorization,
        bytes32 digest
    ) external view returns (address authority);

    /*//////////////////////////////////////////////////////////////
                            NONCE MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the current nonce for an authority
     * @dev Nonces are used to prevent replay attacks. Each successful authorization
     *      increments the nonce, invalidating previous signatures with lower nonces.
     *
     * @param authority The address to query the nonce for
     * @return nonce The current nonce value
     */
    function getNonce(address authority) external view returns (uint256 nonce);

    /**
     * @notice Checks if a nonce is valid for a given authority
     * @dev A nonce is valid if it matches the authority's current nonce
     *      This prevents replay of old authorizations
     *
     * @param authority The authority address to check
     * @param nonce The nonce value to validate
     * @return valid True if the nonce matches the current nonce
     */
    function isNonceValid(
        address authority,
        uint256 nonce
    ) external view returns (bool valid);

    /**
     * @notice Increments the nonce for the caller
     * @dev Allows an authority to invalidate all pending authorizations
     *      by manually incrementing their nonce. Useful for emergency revocation.
     *
     * @return newNonce The new nonce value after increment
     */
    function incrementNonce() external returns (uint256 newNonce);

    /*//////////////////////////////////////////////////////////////
                         EXPIRATION VALIDATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Checks if an authorization has expired
     * @dev Compares the validUntil timestamp against current block.timestamp
     *      An authorization is expired if validUntil <= current time
     *
     * @param validUntil The expiration timestamp
     * @return expired True if the authorization has expired
     */
    function isExpired(uint256 validUntil) external view returns (bool expired);

    /**
     * @notice Checks if an authorization is currently valid (not expired)
     * @dev Opposite of isExpired - returns true if validUntil > current time
     *      Use validUntil = type(uint256).max for non-expiring authorizations
     *
     * @param validUntil The expiration timestamp
     * @return valid True if the authorization is still valid
     */
    function isValid(uint256 validUntil) external view returns (bool valid);

    /*//////////////////////////////////////////////////////////////
                         AUTHORIZATION REVOCATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Revokes all authorizations for the caller
     * @dev This is an emergency function that invalidates all current and future
     *      authorizations until a new one is created. More drastic than incrementNonce.
     *
     * @return success True if revocation was successful
     */
    function revokeAuthorization() external returns (bool success);

    /**
     * @notice Checks if an authority's authorization has been revoked
     * @param authority The address to check
     * @return revoked True if the authority's authorization is revoked
     */
    function isRevoked(address authority) external view returns (bool revoked);

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets comprehensive authorization status for an authority
     * @dev Returns all relevant information about an authority's current state
     *
     * @param authority The address to query
     * @return nonce The current nonce
     * @return revoked Whether the authorization is revoked
     * @return lastUsed Timestamp of last authorization use
     */
    function getAuthorizationStatus(
        address authority
    ) external view returns (
        uint256 nonce,
        bool revoked,
        uint256 lastUsed
    );
}
