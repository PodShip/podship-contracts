require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config({ path: ".env" });

POLYGON_TESTNET_URL = process.env.POLYGON_TESTNET_URL;
PRIVATE_KEY = process.env.PRIVATE_KEY;
ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;

module.exports = {
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    matic: {
      url: POLYGON_TESTNET_URL,
      accounts: [PRIVATE_KEY],
      gas: 2100000,
      gasPrice: 8000000000
    }
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY
  }
};