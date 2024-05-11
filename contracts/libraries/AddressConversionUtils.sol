// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

library AddressConversionUtils {
    /**
     * @dev Converts an address to a uint256 value.
     * @param addr The address to convert.
     * @return The uint256 value representing the address.
     */
    function addressToUint256(address addr) internal pure returns (uint256) {
        return uint256(uint160(addr));
    }

    /**
     * @dev Converts a uint256 value to an address.
     * @param value The uint256 value to convert.
     * @return The address represented by the uint256 value.
     */
    function uint256ToAddress(uint256 value) internal pure returns (address) {
        return address(uint160(value));
    }
}
