require("@nomiclabs/hardhat-waffle");
var keysjson= require("./assets/koa_static/keys.json")
var account_pkeys=keysjson.private_keys;
//var p_key=account_pkeys[Object.keys(account_pkeys)[0]];
//console.log("private key to use",p_key);

module.exports = {
    defaultNetwork: "ganache",
    networks: {
      ganache: {
        url: `HTTP://54.219.243.224:8545`,
        accounts: Object.values(account_pkeys),//['0x'+p_key], 
      },
    },
    solidity: {
      version: "0.8.0",
    },

    paths: {
        sources:   'assets/koa_static/contracts/v2',
        artifacts: 'assets/koa_static/contracts/hardhatbuild_v2',
    },

    namedAccounts: {
        deployer: 0,
    }

}