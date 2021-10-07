
```
///////////MSN//////////////////////////////////

add_special_EVENT(address,address,uint8,uint256)
remove_special_EVENT(address,address,uint16,uint256)
mint_EVENT(address,uint256,uint256)
burn_EVENT(address,uint256,uint256)
set_exchange_open_EVENT(address,bool,uint256)
withdraw_eth_EVENT(address,uint256,uint256)
Transfer(address,address,uint256)
Approval(address,address,uint256)
withdraw_contract_EVENT(address,address,address,uint256,uint256)
special_transfer_EVENT(address,address,address,uint256,uint16,uint16,uint256)


//////////MSN_MINING/////////////

set_MiningOwner_EVENT(address,address,address,uint256)
withdraw_contract_EVENT(address,address,address,uint256,uint256)
add_keeper_EVENT(address,address,string,uint256)
remove_keeper_EVENT(address,address,string,uint256)
add_merkle_root_EVENT(address,bytes32,uint256,uint256)
remove_merkle_root_EVENT(address,bytes32,uint256)
claim_erc20_EVENT(address,bytes32,uint256,uint256)
stack_token_EVENT(address,uint256,string,uint256)
unstack_all_token_EVENT(address,uint256,uint256)

/////////// MSN_DAO //////////////

change_DAOOwner_EVENT(address,address,address,uint256)
withdraw_contract_EVENT(address,address,uint256,uint256)
add_keeper_EVENT(address,address,string,uint256)
remove_keeper_EVENT(address,address,string,uint256)
set_proposal_EVENT(address,uint16,uint256,uint256,uint256)
remove_proposal_EVENT(address,uint16,uint256)
vote_EVENT(address,uint16,uint8,uint256,uint256)
deposit_token_EVENT(address,uint256,uint256)
withdraw_token_EVENT(address,uint256,uint256)

```
