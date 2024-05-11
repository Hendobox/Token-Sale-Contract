require("@nomiclabs/hardhat-ethers");
require("solidity-coverage");
require("hardhat-gas-reporter");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  networks: {
    hardhat: {
      forking: {
        url: "https://arbitrum-sepolia.blockpi.network/v1/rpc/public",
        chainId: 421614,
        blockNumber: 1419835,
      },
    },
  },
};
