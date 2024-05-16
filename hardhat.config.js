require("@nomiclabs/hardhat-ethers");
require("solidity-coverage");
require("hardhat-gas-reporter");
// require("hardhat-libutils");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  networks: {
    hardhat: {
      forking: {
        url: "https://arb-mainnet.g.alchemy.com/v2/pNtjIQbC4mlX4kKD0dQgc7vsjvid1uO4", // "https://arbitrum.gateway.tenderly.co/[YOUR_API_KEY]",
        chainId: 42161,
        blockNumber: 210983988,
        loggingEnabled: true,
      },
    },
  },
};
