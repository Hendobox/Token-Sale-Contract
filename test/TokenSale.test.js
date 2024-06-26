const chai = require("chai");
const { expect } = require("chai");
const { solidity } = require("ethereum-waffle");
const { getProofBytes } = require("../ignition/grpc/evm_client/utils");
const { deploy, spendTime, day, week, month } = require("hardhat-libutils");

chai.use(solidity);

describe("TokenSwap and TokenVest", () => {
  let token, tokenSwap, owner, user1, user2, user3;
  const oracle = "0x41AB2059bAA4b73E9A3f55D30Dff27179e0eA181";
  const saleStartTime = week;
  const saleDuration = day * 9;
  const vestDuration = month;
  const initialPrice = 9;
  const priceIncreaseInterval = day * 3;
  const priceIncreaseAmount = 5;
  const saleSupply = ethers.utils.parseUnits("10000", "ether");

  const addressToUint256 = (address) => {
    return ethers.BigNumber.from(ethers.utils.getAddress(address));
  };
  before(async () => {
    [owner, user1, user2, user3] = await ethers.getSigners();
    // We deploy the Token contract
    token = await deploy("Token", "Token");

    // We deploy the TokenSale contract
    tokenSwap = await deploy(
      "TokenSale",
      "TokenSale",
      owner.address,
      oracle,
      token.address,
      saleStartTime,
      saleDuration,
      vestDuration,
      initialPrice,
      priceIncreaseInterval,
      priceIncreaseAmount
    );
  });

  describe("TokenSale", () => {
    it("Should properly deploy TokenSale", async () => {
      expect((await tokenSwap.saleDuration()).toString()).to.be.equal(
        saleDuration.toString()
      );
      expect((await tokenSwap.priceIncreaseInterval()).toString()).to.be.equal(
        priceIncreaseInterval.toString()
      );
      expect((await tokenSwap.priceIncreaseAmount()).toString()).to.be.equal(
        priceIncreaseAmount.toString()
      );
      expect((await tokenSwap.vestDuration()).toString()).to.be.equal(
        vestDuration.toString()
      );
      expect(
        (
          (await tokenSwap.vestStartTime()) - (await tokenSwap.saleDuration())
        ).toString()
      ).to.be.equal((await tokenSwap.saleStartTime()).toString());
      expect(await tokenSwap.token()).to.be.equal(token.address);
    });

    it("Should fail if purchase when sale hasn't started", async () => {
      const proofBytes = getProofBytes();
      await expect(
        tokenSwap.connect(user1).purchaseTokens(proofBytes, user1.address)
      ).to.revertedWith("Sale has not started");
    });

    it("Should fail if purchase doesn't have enough ETH", async () => {
      // Advance time by 7 days to reach the sale start time
      await spendTime(week);

      // make token price higher than oracle price * value
      await tokenSwap.setInitialTokenPrice(10000);

      const proofBytes = getProofBytes();

      await expect(
        tokenSwap.connect(user1).purchaseTokens(proofBytes, user1.address, {
          value: ethers.utils.parseEther("0.000000000000000001"),
        })
      ).to.revertedWith("ETH is too small");

      // reset token price
      await tokenSwap.setInitialTokenPrice(initialPrice);

      // log("see oracle feed: ", await tokenSwap.getOraclePrice(proofBytes));
    });

    it("Should fail if there aren't enough tokens to buy", async () => {
      const proofBytes = getProofBytes();
      await expect(
        tokenSwap.connect(user1).purchaseTokens(proofBytes, user1.address, {
          value: ethers.utils.parseUnits("1", "ether"),
        })
      ).to.revertedWith("Not enough tokens left");
    });

    it("Should purchase tokens", async () => {
      expect((await tokenSwap.getPrice()).toString()).to.be.equal(
        initialPrice.toString()
      );

      // Owner can set initial price
      const newPrice = 10;
      await expect(tokenSwap.connect(user1).setInitialTokenPrice(newPrice)).to
        .reverted;

      await tokenSwap.setInitialTokenPrice(newPrice);
      expect((await tokenSwap.getPrice()).toString()).to.be.equal(
        newPrice.toString()
      );

      // We transfer some tokens to the contract for purchases
      await token.transfer(tokenSwap.address, saleSupply);

      ///
      /// First buy - user1 ///
      ///
      const proofBytes = getProofBytes();

      await tokenSwap.connect(user1).purchaseTokens(proofBytes, user1.address, {
        value: ethers.utils.parseUnits("1", "ether"),
      });
      // confirm supply increase in the NFT
      expect(await tokenSwap.totalSupply()).to.equal(1);

      // confirm ownership of new NFT to be user1
      let tokenId = addressToUint256(user1.address);
      expect(await tokenSwap.ownerOf(tokenId)).to.equal(user1.address);

      // verify vested amount
      let purchasedAmountUser1 = await tokenSwap.getBalance(user1.address);
      expect(purchasedAmountUser1).to.equal(await tokenSwap.totalBuys());

      ///
      /// Second buy - user2 ///
      ///
      const proofBytes2 = getProofBytes();

      await tokenSwap
        .connect(user2)
        .purchaseTokens(proofBytes2, user2.address, {
          value: ethers.utils.parseUnits("2", "ether"),
        });
      // confirm supply increase in the NFT
      expect(await tokenSwap.totalSupply()).to.equal(2);

      // confirm ownership of new NFT to be user1
      tokenId = addressToUint256(user2.address);
      expect(await tokenSwap.ownerOf(tokenId)).to.equal(user2.address);

      let purchasedAmountUser2 = await tokenSwap.getBalance(user2.address);
      expect(
        ethers.BigNumber.from(purchasedAmountUser1).add(purchasedAmountUser2)
      ).to.equal(await tokenSwap.totalBuys());

      /// Increment past 3 days
      await spendTime(day * 3);

      // confirm token price increment by 50%
      expect(Number(await tokenSwap.getPrice())).to.be.equal(
        newPrice + newPrice / 2
      );

      ///
      /// Third buy - user1 ///
      ///
      const proofBytes3 = getProofBytes();

      await tokenSwap
        .connect(user1)
        .purchaseTokens(proofBytes3, user1.address, {
          value: ethers.utils.parseUnits("1", "ether"),
        });

      // confirm NFT supply doesn't increase since user already purchased
      expect(await tokenSwap.totalSupply()).to.equal(2);
      expect(await tokenSwap.balanceOf(user1.address)).to.equal(1);

      // verify vested amount
      expect(Number(purchasedAmountUser1)).to.lessThan(
        Number(await tokenSwap.getBalance(user1.address))
      );

      /// Increment to the 6th day
      await spendTime(day * 3);

      // confirm token price increment by 100%
      expect(Number(await tokenSwap.getPrice())).to.be.equal(newPrice * 2);

      ///
      /// Forth buy - user2 ///
      ///
      const proofBytes4 = getProofBytes();

      await tokenSwap
        .connect(user2)
        .purchaseTokens(proofBytes4, user2.address, {
          value: ethers.utils.parseUnits("2", "ether"),
        });

      // confirm NFT supply doesn't increase since user already purchased
      expect(await tokenSwap.totalSupply()).to.equal(2);
      expect(await tokenSwap.balanceOf(user2.address)).to.equal(1);

      // verify vested amount
      expect(Number(purchasedAmountUser2)).to.lessThan(
        Number(await tokenSwap.getBalance(user2.address))
      );
    });

    it("Should fail if recovering excess during sale period", async () => {
      await expect(tokenSwap.recoverExcess(owner.address)).to.revertedWith(
        "Sale hasn't ended yet"
      );

      await expect(tokenSwap.connect(user1).recoverExcess(owner.address)).to
        .reverted;
    });
  });

  describe("TokenVest", () => {
    it("Should fail if claiming tokens when sale hasn't ended", async () => {
      await expect(tokenSwap.connect(user1).claimTokens()).to.revertedWith(
        "Sale hasn't ended yet"
      );
      expect(await tokenSwap.getClaimable(user1.address)).to.equal(0);
    });

    it("Should claim tokens correctly", async () => {
      /// Increment to vesting start period
      await spendTime(day * 3);

      // Recover excess tokens left unbought
      await tokenSwap.recoverExcess(user3.address);
      const totalBuys = await tokenSwap.totalBuys();
      expect(Number(await token.balanceOf(tokenSwap.address))).to.equal(
        Number(totalBuys)
      );
      expect(await token.balanceOf(user3.address)).to.equal(
        ethers.BigNumber.from(saleSupply).sub(totalBuys)
      );

      /// Increment into vesting to obtain claimable amount
      await spendTime(day * 15);

      let claimableUser1 = await tokenSwap.getClaimable(user1.address);
      expect(claimableUser1).to.equal(
        ethers.BigNumber.from(await tokenSwap.getBalance(user1.address)).div(2)
      );

      ///
      /// First token claim - user1 ///
      ///
      await tokenSwap.connect(user1).claimTokens();

      // Verify that User received the tokens
      expect(await token.balanceOf(user1.address)).to.equal(claimableUser1);

      // verify remaining balance to be claimed by user
      expect(claimableUser1).to.equal(
        await tokenSwap.getBalance(user1.address)
      );

      /// Increment
      await spendTime(day * 5);

      let claimableUser2 = await tokenSwap.getClaimable(user2.address);
      let balanceUser2 = await tokenSwap.getBalance(user2.address);

      ///
      /// Second token claim - user2 ///
      ///
      await tokenSwap.connect(user2).claimTokens();

      // Verify that User received the tokens
      expect(await token.balanceOf(user2.address)).to.equal(claimableUser2);
      expect(ethers.BigNumber.from(balanceUser2).sub(claimableUser2)).to.equal(
        await tokenSwap.getBalance(user2.address)
      );

      /// Increment
      await spendTime(day * 10);

      ///
      /// Third token claim - user2 ///
      ///
      await tokenSwap.connect(user2).claimTokens();

      // Verify updated state
      expect(0).to.equal(await tokenSwap.getBalance(user2.address));

      // confirm supply decrease in the NFT
      expect(await tokenSwap.totalSupply()).to.equal(1);

      // confirm balance decrease in the NFT
      expect(await tokenSwap.balanceOf(user2.address)).to.equal(0);
    });
  });
});
