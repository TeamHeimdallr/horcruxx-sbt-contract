// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of an SBT contract
 */
interface ISBT {
    /**
     * @dev lock `tokenId` token so it can't be transferred.
     * @param tokenId The identifier for a token.
     *
     * Requirements:
     *
     * - `tokenId` token must exist and be owned or approved by caller.
     *
     * Emits a {IERC5192-Locked} event.
     */
    function lock(uint256 tokenId) external;

    /**
     * @dev unlock `tokenId` token so it can be transferred.
     * @param tokenId The identifier for a token.
     *
     * Requirements:
     *
     * - `tokenId` token must exist and be owned or approved by caller.
     *
     * Emits a {IERC5192-Unlocked} event.
     */
    function unlock(uint256 tokenId) external;
}
