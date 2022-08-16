/**
* @type import('hardhat/config').HardhatUserConfig
*/
require('dotenv').config();
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
const { API_URL, PRIVATE_KEY, ETHERSCAN_KEY } = process.env;
module.exports = {
   solidity: {
      version: "0.8.9",
      settings: {
         optimizer: {
           enabled: true,
           runs: 1000,
         }
      }
   },
   defaultNetwork: "rinkeby",   
   networks: {
      hardhat: {},
      rinkeby: {
         url: API_URL,
         accounts: [`0x${PRIVATE_KEY}`]
      }
   },
   etherscan: {
    apiKey: {
      rinkeby: ETHERSCAN_KEY,
      mainnet: ETHERSCAN_KEY
    }
  }
}