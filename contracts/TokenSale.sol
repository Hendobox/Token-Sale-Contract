// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ITokenSale} from "./interfaces/ITokenSale.sol";
import {ISupraOraclePull} from "./interfaces/ISupraOraclePull.sol";
import {TokenVest, SafeERC20, IERC20} from "./TokenVest.sol";
import {AddressConversionUtils} from "./libraries/AddressConversionUtils.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

/**
 * @title TokenSale Contract
 * @dev Contract for token sale functionality, implementing the ITokenSale interface.
 */
contract TokenSale is ITokenSale, TokenVest, Ownable {
    using SafeERC20 for IERC20;

    uint64 public immutable saleStartTime;
    uint64 public immutable saleDuration;
    uint64 public immutable priceIncreaseInterval;
    uint256 initialTokenPriceInUSD;
    uint256 public immutable priceIncreaseAmount;
    uint256 public constant PAIR_ID = 19; // ETH_USD on supra
    uint256 public totalBuys;
    ISupraOraclePull internal immutable oracle;

    /**
     * @dev Constructor to initialize the TokenSale contract.
     * @param initialOwner The address of the initial owner of the contract.
     * @param _oracle The address of the Supraoracle contract.
     * @param _token The address of the token to be sold.
     * @param _saleStartTime The start time of the token sale.
     * @param _saleDuration The duration of the token sale.
     * @param _vestDuration The duration of the vesting period.
     * @param _initialPrice The initial price of the token in USD.
     * @param _priceIncreaseInterval The interval at which the token price increases.
     * @param _priceIncreaseAmount The amount by which the token price increases.
     */
    constructor(
        address initialOwner,
        address _oracle,
        address _token,
        uint64 _saleStartTime,
        uint64 _saleDuration,
        uint64 _vestDuration,
        uint256 _initialPrice,
        uint64 _priceIncreaseInterval,
        uint256 _priceIncreaseAmount
    )
        TokenVest(
            _token,
            uint64(block.timestamp) + _saleStartTime + _saleDuration,
            _vestDuration
        )
        Ownable(initialOwner)
    {
        oracle = ISupraOraclePull(_oracle);
        initialTokenPriceInUSD = _initialPrice;
        saleStartTime = uint64(block.timestamp) + _saleStartTime;
        saleDuration = _saleDuration;
        priceIncreaseInterval = _priceIncreaseInterval;
        priceIncreaseAmount = _priceIncreaseAmount;
    }

    /// @inheritdoc ITokenSale
    function purchaseTokens(
        bytes calldata _bytesProof,
        address recipient
    ) external payable {
        uint64 _saleStartTime = saleStartTime;
        require(block.timestamp >= _saleStartTime, "Sale has not started");
        require(
            block.timestamp < _saleStartTime + saleDuration,
            "Sale has ended"
        );

        ISupraOraclePull.PriceData memory price = getOraclePrice(_bytesProof);
        uint256 usdValue = msg.value *
            (price.prices[0] / (10 ** price.decimals[0]));
        uint256 tokenPrice = _getPrice();
        require(usdValue >= tokenPrice, "ETH is too small");
        uint256 amount = usdValue / tokenPrice;

        require(
            IERC20(token).balanceOf(address(this)) >= amount + totalBuys,
            "Not enough tokens left"
        );

        unchecked {
            // safe operation
            totalBuys += amount;
        }

        uint256 tokenId = AddressConversionUtils.addressToUint256(recipient);

        if (_ownerOf(tokenId) != recipient) {
            _mintVestNFT(recipient, VestedPurchase({amount: amount, taken: 0}));
        } else {
            unchecked {
                // safe operation
                _vestedPurchases[tokenId].amount += amount;
            }
        }

        emit TokensPurchased(
            _msgSender(),
            recipient,
            tokenId,
            msg.value,
            amount
        );
    }

    /// @inheritdoc ITokenSale
    function setInitialTokenPrice(uint256 newPrice) external onlyOwner {
        require(block.timestamp < vestStartTime, "Sale ended");
        require(newPrice > 0, "Price must be greater than zero");
        initialTokenPriceInUSD = newPrice;
        emit TokenPriceUpdated(newPrice);
    }

    /// @inheritdoc ITokenSale
    function recoverExcess(address recipient) external onlyOwner afterSale {
        IERC20 _token = IERC20(token);
        uint256 balance = _token.balanceOf(address(this));
        require(balance > totalBuys, "Not enough tokens available");
        uint256 amount = balance - totalBuys;
        _token.safeTransfer(recipient, amount);
        emit RecoverExcess(recipient, amount);
    }

    /// @inheritdoc ITokenSale
    function getPrice() external view returns (uint256 price) {
        price = _getPrice();
    }

    // Get the price of a pair from oracle data received from supra pull model
    function getOraclePrice(
        bytes memory _bytesProof
    ) public returns (ISupraOraclePull.PriceData memory price) {
        price = oracle.verifyOracleProof(_bytesProof);
        require(price.pairs[0] == PAIR_ID, "Invalid pair");
        require(price.prices[0] != 0, "Pair not found");
    }

    /**
     * @dev Private function to calculate the current token price.
     * @return The current token price.
     */
    function _getPrice() private view returns (uint256) {
        if (block.timestamp <= saleStartTime) {
            return 0;
        }
        uint256 elapsedTime = block.timestamp - saleStartTime;
        if (elapsedTime < priceIncreaseInterval) {
            return initialTokenPriceInUSD;
        }
        uint256 intervalsPassed = elapsedTime / priceIncreaseInterval;
        return (initialTokenPriceInUSD +
            (intervalsPassed * priceIncreaseAmount));
    }
}
