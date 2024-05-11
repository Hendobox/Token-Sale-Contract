// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title Token Vesting Interface
 * @dev Interface for managing token vesting.
 */
interface ITokenVest {
    /**
     * @dev Struct to represent a vested purchase.
     * @param amount The total amount of tokens purchased.
     * @param taken The amount of tokens already claimed by the user.
     */
    struct VestedPurchase {
        uint256 amount;
        uint256 taken;
    }

    /**
     * @dev Emitted when a user claims tokens from their vested purchase.
     * @param user The address of the user who claimed the tokens.
     * @param amount The amount of tokens claimed.
     */
    event ClaimTokens(address indexed user, uint256 amount);

    /**
     * @dev Allows a user to claim claimable tokens from their vested purchase.
     */
    function claimTokens() external;

    /**
     * @dev Gets the amount of tokens claimable by a user.
     * @param who The address of the user.
     * @return The amount of tokens claimable.
     */
    function getClaimable(address who) external view returns (uint256);

    /**
     * @dev Gets the balance of tokens vested for a user.
     * @param who The address of the user.
     * @return The balance of tokens vested.
     */
    function getBalance(address who) external view returns (uint256);
}
