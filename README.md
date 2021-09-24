# msn_contract
### meson network contract 

#### this program can only run on linux server , mac,windows (not supported!)

#### before you start please make sure 
```
ganache.finance.daqnext.com  domain points to your linux server public ip
as that domain is used to connect to the ganache chain to deploy the contracts
```

#### please run below commands on your linux server
```
npm run build
npm run run_ganache  (please run this in demond process)
npm run deploy_ganache 
```

### after running you could enjoy the ganache chain over:


### contracts are located in /assets/koa_static/contracts
### v1 is deprecated please use v2

#### 1.MSN is the token contract of erc20
#### 3.MSN-MINING is for meson.network mining 
#### 2.MSN-DAO for Governance

### build all the contract 
```
npm run build
all the build files are located at assets/koa_static/contract_build/v2/
```


### for easy test over ganache chain
#### ```npm run run_ganache```
#### ```npm run deploy_ganache```


### only provides dev invironment over ganache
```npm run dev```


 
