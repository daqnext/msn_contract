require("@nomiclabs/hardhat-waffle");
var account_key = require("./assets/koa_static/account_key.json");

var privatekeys=[];
account_key.forEach(ele=>function(){
  privatekeys.push(ele.key);
});


console.log(privatekeys);

module.exports = {
    defaultNetwork: "devchain",
    networks: {
      devchain: {
        url: `HTTP://54.219.243.224:8545`,
        accounts: privatekeys,//['0x'+p_key], 
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