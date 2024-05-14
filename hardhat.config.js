require("@nomiclabs/hardhat-ethers");
require("solidity-coverage");
require("hardhat-gas-reporter");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  networks: {
    hardhat: {
      forking: {
        url: "https://arbitrum.gateway.tenderly.co/[YOUR_API_KEY]",
        chainId: 42161,
        blockNumber: 210983988,
        loggingEnabled: true,
      },
    },
  },
};
