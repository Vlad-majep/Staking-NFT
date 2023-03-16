import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-etherscan";
import * as dotenv from 'dotenv'
dotenv.config()

const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY
const GOEGLI_PRIVATE_KEY = process.env.GOERLI_PRIVATE_KEY
const api_key = process.env.APIKEY

module.exports = {
  solidity: "0.8.17",
  networks: {
    sepolia: {
      url: `https://sepolia.infura.io/v3/${ALCHEMY_API_KEY}`,
      accounts: [GOEGLI_PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: api_key
  }
};