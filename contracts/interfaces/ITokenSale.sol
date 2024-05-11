// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title Token Sale Interface
 * @dev Interface for managing token sale.
 */
interface ITokenSale {
    /**
     * @dev Emitted when tokens are purchased.
     * @param sender The address of the sender who purchased the tokens.
     * @param recipient The address of the recipient who received the tokens.
     * @param tokenId The ID of the token received.
     * @param value The value of ETH sent for the purchase.
     * @param amount The amount of tokens purchased.
     */
    event TokensPurchased(
        address indexed sender,
        address indexed recipient,
        uint256 indexed tokenId,
        uint256 value,
        uint256 amount
    );

    /**
     * @dev Emitted when the initial token price is updated.
     * @param newPrice The new initial token price.
     */
    event TokenPriceUpdated(uint256 newPrice);

    /**
     * @dev Emitted when excess funds are recovered.
     * @param recipient The address of the recipient who receives the excess funds.
     * @param amount The amount of excess funds recovered.
     */
    event RecoverExcess(address indexed recipient, uint256 amount);

    /**
     * @dev Allows a user to purchase tokens with ETH.
     * @param _bytesProof The proof of the request from Supra Pull Oracle.
     * @param recipient The address of the recipient who will receive the tokens.
     */
    function purchaseTokens(
        bytes calldata _bytesProof,
        address recipient
    ) external payable;

    /**
     * @dev Allows the owner to set the initial token price.
     * @param newPrice The new initial token price.
     */
    function setInitialTokenPrice(uint256 newPrice) external;

    /**
     * @dev Allows the owner to recover excess funds after sales.
     * @param recipient The address to send the excess funds to.
     */
    function recoverExcess(address recipient) external;

    /**
     * @dev Gets the current price of the tokens.
     * @return price The current price of the tokens.
     */
    function getPrice() external view returns (uint256 price);
}
