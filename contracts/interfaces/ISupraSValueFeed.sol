// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title SupraSValueFeed Interface
 * @dev Interface for interacting with the SupraSValueFeed contract.
 */
interface ISupraSValueFeed {
    /**
     * @dev Struct representing price feed data.
     * @param round The round number.
     * @param decimals The number of decimals in the price.
     * @param time The timestamp of the price feed data.
     * @param price The price value.
     */
    struct priceFeed {
        uint256 round;
        uint256 decimals;
        uint256 time;
        uint256 price;
    }

    /**
     * @dev Gets the price feed data for a given pair index.
     * @param _pairIndex The index of the pair.
     * @return The price feed data for the pair.
     */
    function getSvalue(
        uint256 _pairIndex
    ) external view returns (priceFeed memory);
}
