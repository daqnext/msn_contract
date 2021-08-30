async function main() {

  const accounts = await ethers.getSigners();
  console.log('accounts number:',accounts.length);
  const chainid=await accounts[0].getChainId();
  console.log('chainid:',chainid);

  // We get the contract to deploy
  const Msn = await ethers.getContractFactory("MSN",accounts[0]);
  const msn = await Msn.deploy("Meson.network Testnet Token","MSNTT",100000000);
  console.log("MSNTT deployed to:", msn.address);


  const MINING = await ethers.getContractFactory("MINING",accounts[1]);
  const mining = await MINING.deploy(msn.address);
  console.log("MINING deployed to:", mining.address);


  const DAO = await ethers.getContractFactory("DAO",accounts[2]);
  //const dao = await DAO.deploy(msn.address,3600*24*3);    //3 days
  const dao = await DAO.deploy(msn.address,300);//5mins for easy testing 
  console.log("DAO deployed to:", dao.address);


  var keysjson= require("../../assets/koa_static/keys.json")
  var account_pkeys=keysjson.private_keys;

  var info={};
  info.endpoint='54.219.243.224:8545';
  info.chainid=chainid;

  info.MSN=msn.address;
  info.msn_deploy_account=Object.keys(account_pkeys)[0];
  info.msn_deploy_key=account_pkeys[info.msn_deploy_account];

   
  info.MINING=mining.address;
  info.mining_deploy_account=Object.keys(account_pkeys)[1];
  info.mining_deploy_key=account_pkeys[info.mining_deploy_account];

  info.DAO=dao.address;
  info.dao_deploy_account=Object.keys(account_pkeys)[2];
  info.dao_deploy_key=account_pkeys[info.dao_deploy_account];

  info.accounts=account_pkeys;

  const fs = require('fs');
  fs.writeFileSync("assets/koa_static/deployinfo.json", JSON.stringify(info));


  ///make some  claim test data////
  
  const {MTree} =require('merkle-tree-util');
  
  let mtree=new MTree();

  claim_test={
    merkelRoot:'',
    merkleProofs:[]
  };

  //wallet from 3 to 7
  for(var i=0;i<5;i++){
      mtree.addLeaf(Object.keys(account_pkeys)[i+3],100*(i+1));
  }
  mtree.build();
  
  claim_test.merkelRoot=mtree.get_root();
  for(var i=0;i<5;i++){
    claim_test.merkleProofs.push({
      index:i,
      account:Object.keys(account_pkeys)[i+3],
      key:account_pkeys[Object.keys(account_pkeys)[i+3]],
      proof:mtree.gen_proof(i)
    });
  }

  console.log("claim_test_data :",claim_test);
  fs.writeFileSync("assets/koa_static/claim_test_data.json", JSON.stringify(claim_test));
}


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
})