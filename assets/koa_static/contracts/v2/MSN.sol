// SPDX-License-Identifier: GPL v3
// README: https://github.com/daqnext/msn_contracts/blob/main/assets/koa_static/contracts/v2/MSN.md

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MSN is ERC20 {
    uint256 private payable_amount;
    address private contract_owner;
    bool private exchange_open;
    mapping(address => uint16) private special_list;
    mapping(uint16 => address) private special_list_idmap;

    modifier onlyContractOwner() {
        require(msg.sender == contract_owner, "Only contractOwner");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        uint256 inisupply
    ) ERC20(name, symbol) {
        contract_owner = msg.sender;
        special_list[msg.sender] = 1;
        special_list_idmap[1] = msg.sender;
        exchange_open = false;
        _mint(msg.sender, inisupply * (10**uint256(decimals())));
    }

    event add_special_EVENT(address special_addr, uint8 _id);

    function add_special(address special_addr, uint8 _id)
        external
        onlyContractOwner
    {
        require(_id > 0, "Special ID should start from 1");
        require(special_list_idmap[_id] == address(0x0), "Id already exist!");
        require(special_list[special_addr] == 0, "address already exist!");

        special_list[special_addr] = _id;
        special_list_idmap[_id] = special_addr;
        emit add_special_EVENT(special_addr, _id);
    }

    event remove_special_EVENT(address special_addr, uint16 _special_id);

    function remove_special(address special_addr) external onlyContractOwner {
        require(special_list[special_addr] > 0, "No such special");
        require(
            special_addr != contract_owner,
            "Can not delete contract owner"
        );
        uint16 special_id = special_list[special_addr];
        delete special_list[special_addr];
        delete special_list_idmap[special_id];
        emit remove_special_EVENT(special_addr, special_id);
    }

    function get_special(address special_addr) external view returns (uint16) {
        require(special_list[special_addr] > 0, "No such special");
        return special_list[special_addr];
    }

    function get_special_by_id(uint16 _id) external view returns (address) {
        require(special_list_idmap[_id] != address(0x0), "No such special");
        return special_list_idmap[_id];
    }

    // mint is open for mining inflation increment
    event mint_EVENT(address _from, uint256 amount);

    function mint(uint256 amount) public onlyContractOwner {
        _mint(msg.sender, amount);
        emit mint_EVENT(msg.sender, amount);
    }

    // anyone can burn their own token
    event burn_EVENT(address _from, uint256 amount);

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        emit burn_EVENT(msg.sender, amount);
    }

    function set_exchange_open(bool _exchange_open) external onlyContractOwner {
        exchange_open = _exchange_open;
    }

    function get_exchange_open() public view returns (bool) {
        return exchange_open;
    }

    //overwrite to inject the modifier
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        require(
            exchange_open == true ||
                (special_list[owner] > 0) ||
                (special_list[spender] > 0),
            "Exchange closed && not special"
        );

        super._approve(owner, spender, amount);
    }

    event special_transfer_EVENT(
        address _sender,
        address _recipient,
        uint256 _amount,
        uint256 _blocktime
    );

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(
            exchange_open == true ||
                (special_list[sender] > 0) ||
                (special_list[recipient] > 0),
            "Exchange closed && not special"
        );

        super._transfer(sender, recipient, amount);

        if ((special_list[sender] > 0) || (special_list[recipient] > 0)) {
            emit special_transfer_EVENT(
                sender,
                recipient,
                amount,
                block.timestamp
            );
        }
    }

    receive() external payable {
        payable_amount += msg.value;
    }

    fallback() external payable {
        payable_amount += msg.value;
    }

    function withdraw_eth() external onlyContractOwner {
        payable(msg.sender).transfer(address(this).balance);
        payable_amount = 0;
    }
}
