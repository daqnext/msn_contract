// SPDX-License-Identifier: GPL v3

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MSN_MINING {
    uint256 private payable_amount;

    address private MSNAddr;
    address private MiningOwner;

    mapping(address => string) private keepers; //keeper account can add add_merkle_root
    mapping(bytes32 => uint256) private merkleRoots; // merkleRoot=>balance
    mapping(bytes32 => mapping(uint256 => bool)) private claimed; //bytes32 merkleRoot => (index => true|false)

    mapping(address => uint256) private acc_staking;

    constructor(address _MSNcontractAddr) {
        MiningOwner = msg.sender;
        MSNAddr = _MSNcontractAddr;
        keepers[msg.sender] = "MiningOwner";
    }

    modifier onlyMiningOwner() {
        require(msg.sender == MiningOwner, "only MiningOwner");
        _;
    }

    event set_MiningOwner_EVENT(
        address trigger_user_addr,
        address oldOwner,
        address newOwner,
        uint256 blocktime
    );

    function set_MiningOwner(address _newOwner) external onlyMiningOwner {
        require(
            _newOwner != MiningOwner,
            "The new owner must be different from the old"
        );
        address oldMiningOwner = MiningOwner;
        delete keepers[oldMiningOwner];
        MiningOwner = _newOwner;
        keepers[_newOwner] = "MiningOwner";
        emit set_MiningOwner_EVENT(
            msg.sender,
            oldMiningOwner,
            _newOwner,
            block.timestamp
        );
    }

    function get_MiningOwner() external view returns (address) {
        return MiningOwner;
    }

    function get_msn_addr() public view returns (address) {
        return MSNAddr;
    }

    function get_contract_balance() public view returns (uint256) {
        return IERC20(MSNAddr).balanceOf(address(this));
    }

    function get_keeper(address keeper_addr)
        public
        view
        returns (string memory)
    {
        require(bytes(keepers[keeper_addr]).length != 0, "No such a keeper");
        return keepers[keeper_addr];
    }

    event add_keeper_EVENT(
        address trigger_user_addr,
        address keeper_addr,
        string keeper_name,
        uint256 blocktime
    );

    function add_keeper(address keeper_addr, string calldata keeper_name)
        external
        onlyMiningOwner
    {
        require(bytes(keeper_name).length != 0, "No name");
        keepers[keeper_addr] = keeper_name;
        emit add_keeper_EVENT(
            msg.sender,
            keeper_addr,
            keeper_name,
            block.timestamp
        );
    }

    event remove_keeper_EVENT(
        address trigger_user_addr,
        address keeper_addr,
        string keeper_name,
        uint256 blocktime
    );

    function remove_keeper(address keeper_addr) external onlyMiningOwner {
        require(bytes(keepers[keeper_addr]).length != 0, "No such a keeper");
        require(keeper_addr != MiningOwner, "Can not delete MiningOwner");
        string memory keeper_name = keepers[keeper_addr];
        delete keepers[keeper_addr];
        emit remove_keeper_EVENT(
            msg.sender,
            keeper_addr,
            keeper_name,
            block.timestamp
        );
    }

    modifier onlyKeeper() {
        require(bytes(keepers[msg.sender]).length != 0, "No such a keeper");
        _;
    }

    event add_merkle_root_EVENT(
        address trigger_user_addr,
        bytes32 merkleRoot,
        uint256 amount,
        uint256 blocktime
    );

    function set_merkle_root(bytes32 merkleRoot, uint256 amount)
        external
        onlyKeeper
    {
        merkleRoots[merkleRoot] = amount + 1; // +1 for never to 0 again
        emit add_merkle_root_EVENT(
            msg.sender,
            merkleRoot,
            amount,
            block.timestamp
        );
    }

    event remove_merkle_root_EVENT(
        address trigger_user_addr,
        bytes32 merkleRoot,
        uint256 blocktime
    );

    function remove_merkle_root(bytes32 merkleRoot) external onlyMiningOwner {
        delete merkleRoots[merkleRoot];
        emit remove_merkle_root_EVENT(msg.sender, merkleRoot, block.timestamp);
    }

    function get_merkle_balance(bytes32 merkleRoot)
        public
        view
        returns (uint256)
    {
        return merkleRoots[merkleRoot];
    }

    event claim_erc20_EVENT(
        address trigger_user_addr,
        bytes32 merkleRoot,
        uint256 amount,
        uint256 time
    );

    function claim_erc20(
        bytes32 merkleRoot,
        uint256 index,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        require(merkleRoots[merkleRoot] != 0, "The merkleRoot doesn't exist");
        require(claimed[merkleRoot][index] == false, "Already claimed");

        bytes32 leaf = keccak256(abi.encodePacked(index, msg.sender, amount));
        bool verify = MerkleProof.verify(merkleProof, merkleRoot, leaf);
        require(verify == true, "Not verified");

        require(merkleRoots[merkleRoot] > amount, "Not enough balance");
        merkleRoots[merkleRoot] -= amount;

        claimed[merkleRoot][index] = true;
        bool result = IERC20(MSNAddr).transfer(msg.sender, amount);
        require(result == true, "transfer error");
        emit claim_erc20_EVENT(msg.sender, merkleRoot, amount, block.timestamp);
    }

    function erc20_claimed(bytes32 merkleRoot, uint256 index)
        external
        view
        returns (bool)
    {
        return  claimed[merkleRoot][index];
    }

    event stake_token_EVENT(
        address trigger_user_addr,
        uint256 amount,
        string userid,
        uint256 blocktime
    );

    function stake_token(uint256 amount, string calldata userid) external {
        uint256 allowance = IERC20(MSNAddr).allowance(
            msg.sender,
            address(this)
        );
        require(allowance > 0, "Not allowed");
        bool t_result = IERC20(MSNAddr).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(t_result == true, "transfer error");
        acc_staking[msg.sender] += amount;
        emit stake_token_EVENT(msg.sender, amount, userid, block.timestamp);
    }

    function get_acc_staking(address addr) public view returns (uint256) {
        return acc_staking[addr];
    }

    receive() external payable {
        payable_amount += msg.value;
    }

    fallback() external payable {
        payable_amount += msg.value;
    }

    event withdraw_eth_EVENT(
        address trigger_user_addr,
        uint256 _amount,
        uint256 blocktime
    );

    function withdraw_eth() external onlyMiningOwner {
        uint256 amout_to_t = address(this).balance;
        payable(msg.sender).transfer(amout_to_t);
        payable_amount = 0;
        emit withdraw_eth_EVENT(msg.sender, amout_to_t, block.timestamp);
    }

    event withdraw_contract_EVENT(
        address trigger_user_addr,
        address _from,
        uint256 amount,
        uint256 blocktime
    );

    function withdraw_contract() public onlyMiningOwner {
        uint256 left = IERC20(MSNAddr).balanceOf(address(this));
        require(left > 0, "No balance");
        IERC20(MSNAddr).transfer(msg.sender, left);
        emit withdraw_contract_EVENT(
            msg.sender,
            address(this),
            left,
            block.timestamp
        );
    }
}
