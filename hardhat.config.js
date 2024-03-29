require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  etherscan: {
    apiKey: "CII2ICK5C9QTN6BJ8T4DFB8ACV1WSHVNCT",
  },
  networks:{
    goerli:{
      url: "https://eth-goerli.g.alchemy.com/v2/nzn28-MdP1oHc_-NUZjhDnKvwYwKO6b3",
      accounts: [process.env.PRIVATE_KEY]
    },
    arbigoerli:{
      url: "https://arbitrum-goerli.infura.io/v3/6668ed5bd540424d93b34900704e2e4b",
      accounts: [process.env.PRIVATE_KEY]
    },
    arbi:{
      url: "https://arbitrum-mainnet.infura.io/v3/6668ed5bd540424d93b34900704e2e4b",
      accounts: [process.env.PRIVATE_KEY]
    },
    hardhat:{
      forking:{
        url: "https://ethereum-goerli.publicnode.com",
        accounts: [process.env.PRIVATE_KEY]
      },
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.19",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1,
          },
        },
      },
      {
        version: "0.6.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
};
