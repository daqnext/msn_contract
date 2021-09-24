require("@nomiclabs/hardhat-waffle");
var keysjson = require("./assets/koa_static/keys.json")
var account_pkeys = keysjson.private_keys;

module.exports = {
  defaultNetwork: "ganache",
  networks: {
    ganache: {
      url: `HTTP://ganache.finance.daqnext.com:8545`,
      accounts: Object.values(account_pkeys),//['0x'+p_key], 
    },
  },
  solidity: {
    version: "0.8.0",
  },
  paths: {
    sources: 'assets/koa_static/contracts/v2',
    artifacts: 'assets/koa_static/contracts/hardhatbuild_v2',
  }
}