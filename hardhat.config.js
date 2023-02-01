require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config({ path: ".env" });

PRIVATE_KEY = process.env.PRIVATE_KEY;
ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;
POLYGON_TESTNET_URL = process.env.POLYGON_TESTNET_URL;
FILECOIN_TESTNET_URL = process.env.FILECOIN_TESTNET_URL;

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
    },
    hyperspace: {
      chainId: 3141,
      url: FILECOIN_TESTNET_URL,
      accounts: [PRIVATE_KEY],
    },
    localhost: {
      url: "http://127.0.0.1:8545/",
      chainId: 31337,
    }
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY
  }
};