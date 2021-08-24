
async function main() {
    // We get the contract to deploy
    const Msn = await ethers.getContractFactory("MSN");
    const msn = await Msn.deploy("Meson.network Testnet Token","MSNTT",100000000);
    console.log("MSNTT deployed to:", msn.address);


    const MINING = await ethers.getContractFactory("MINING");
    const mining = await MINING.deploy(msn.address);
    console.log("MINING deployed to:", mining.address);


    const DAO = await ethers.getContractFactory("DAO");
    //const dao = await DAO.deploy(msn.address,3600*24*3);    //3 days
    const dao = await DAO.deploy(msn.address,300);//5mins for easy testing 
    console.log("DAO deployed to:", dao.address);


    var keysjson= require("../../assets/koa_static/keys.json")
    var account_pkeys=keysjson.private_keys;
    var account_used=Object.keys(account_pkeys)[0];
    var key_used=account_pkeys[account_used];

    var info={};
    info.endpoint='54.219.243.224:8545';
    info.chainid='8080';
    info.account_used=account_used;
    info.key_used=key_used;

    info.MSN=msn.address;
    info.MINING=mining.address;
    info.DAO=dao.address;
    
    info.accounts=account_pkeys;

    const fs = require('fs');
    fs.writeFileSync("assets/koa_static/deployinfo.json", JSON.stringify(info));
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
})