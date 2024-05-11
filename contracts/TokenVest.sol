// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC721Enumerable, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ITokenVest} from "./interfaces/ITokenVest.sol";
import {AddressConversionUtils} from "./libraries/AddressConversionUtils.sol";

/**
 * @title TokenVest Contract
 * @dev NFT contract for token vesting functionality, implementing the ITokenVest interface.
 */
contract TokenVest is ITokenVest, ERC721Enumerable {
    using SafeERC20 for IERC20;

    uint64 public immutable vestDuration;
    uint64 public immutable vestStartTime;
    address public immutable token;

    mapping(uint256 => VestedPurchase) _vestedPurchases;

    /**
     * @dev Constructor to initialize the TokenVest contract.
     * @param _token The address of the token to be vested.
     * @param _vestStartTime The start time of the vesting period.
     * @param _vestDuration The duration of the vesting period.
     */
    constructor(
        address _token,
        uint64 _vestStartTime,
        uint64 _vestDuration
    ) ERC721("TokenVest", "NFT") {
        vestStartTime = _vestStartTime;
        vestDuration = _vestDuration;
        token = _token;
    }

    /**
     * @dev Modifier to check if the sale has ended.
     */
    modifier afterSale() {
        require(block.timestamp >= vestStartTime, "Sale hasn't ended yet");
        _;
    }

    /// @inheritdoc ITokenVest
    function claimTokens() external afterSale {
        uint256 tokenId = AddressConversionUtils.addressToUint256(_msgSender());
        require(_ownerOf(tokenId) == _msgSender(), "You are not authorized");
        VestedPurchase memory purchase = _vestedPurchases[tokenId];
        uint256 available = _getClaimable(purchase);
        require(available > 0, "Nothing available yet");
        if (available + purchase.taken == purchase.amount) {
            _burnVestNFT(_msgSender());
        } else {
            unchecked {
                // safe operations
                _vestedPurchases[tokenId].taken += available;
            }
        }
        IERC20(token).safeTransfer(_msgSender(), available);
        emit ClaimTokens(_msgSender(), available);
    }

    /// @inheritdoc ITokenVest
    function getBalance(address who) external view returns (uint256) {
        VestedPurchase memory purchase = _vestedPurchases[
            AddressConversionUtils.addressToUint256(who)
        ];
        return (purchase.amount - purchase.taken);
    }

    /// @inheritdoc ITokenVest
    function getClaimable(address who) external view returns (uint256) {
        return
            _getClaimable(
                _vestedPurchases[AddressConversionUtils.addressToUint256(who)]
            );
    }

    function _getClaimable(
        VestedPurchase memory purchase
    ) private view returns (uint256) {
        uint256 start = vestStartTime;
        uint256 duration = vestDuration;
        uint256 releasedPct;

        if (block.timestamp <= start) {
            return 0;
        } else {
            if (block.timestamp >= start + duration) {
                releasedPct = 100;
            } else releasedPct = ((block.timestamp - start) * 100) / (duration);

            uint256 released = (purchase.amount * releasedPct) / 100;
            return released - purchase.taken;
        }
    }

    /**
     * @dev Mints a vesting NFT for the given address.
     */
    function _mintVestNFT(address to, VestedPurchase memory purchase) internal {
        uint256 tokenId = AddressConversionUtils.addressToUint256(to);
        _mint(to, tokenId);
        _vestedPurchases[tokenId] = purchase;
    }

    /**
     * @dev Burns the vesting NFT for the given address.
     */
    function _burnVestNFT(address to) internal {
        uint256 tokenId = AddressConversionUtils.addressToUint256(to);
        _burn(tokenId);
        delete _vestedPurchases[tokenId];
    }
}
