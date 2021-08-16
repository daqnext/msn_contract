// SPDX-License-Identifier: GPL v3

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MINING {
    uint256 payable_amount;

    address private MSNAddr;
    address private MiningOwner;

    mapping(address => string) private keepers; //keeper account can add add_merkle_root
    mapping(bytes32 => uint256) merkleRoots; // merkleRoot=>balance
    mapping(bytes32 => mapping(uint256 => bool)) claimed; //bytes32 merkleRoot => (index => true|false)

    constructor(address _MSNcontractAddr) {
        MiningOwner = msg.sender;
        MSNAddr = _MSNcontractAddr;
        keepers[msg.sender] = "MiningOwner";
    }

    modifier onlyMiningOwner() {
        require(msg.sender == MiningOwner, "only MiningOwner");
        _;
    }

    event set_MiningOwner_EVENT(address oldOwner, address newOwner);

    function set_MiningOwner(address _newOwner) external onlyMiningOwner {
        require(_newOwner != MiningOwner, "The new owner must be different from the old");
        address oldMiningOwner = MiningOwner;
        delete keepers[oldMiningOwner];
        MiningOwner = _newOwner;
        keepers[_newOwner] = "MiningOwner";
        emit set_MiningOwner_EVENT(oldMiningOwner, _newOwner);
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

    event withdraw_contract_EVENT(
        address _from,
        address _to,
        uint256 amount,
        uint256 time
    );

    function withdraw_contract() public onlyMiningOwner {
        uint256 left = IERC20(MSNAddr).balanceOf(address(this));
        require(left > 0, "No balance");
        IERC20(MSNAddr).transfer(msg.sender, left);
        emit withdraw_contract_EVENT(
            address(this),
            msg.sender,
            left,
            block.timestamp
        );
    }

    event add_keeper_EVENT(address keeper_addr, string keeper_name);

    function add_keeper(address keeper_addr, string calldata keeper_name)
        external
        onlyMiningOwner
    {
        require(bytes(keeper_name).length != 0, "No name");
        keepers[keeper_addr] = keeper_name;
        emit add_keeper_EVENT(keeper_addr, keeper_name);
    }

    event remove_keeper_EVENT(address keeper_addr, string keeper_name);

    function remove_keeper(address keeper_addr) external onlyMiningOwner {
        require(bytes(keepers[keeper_addr]).length != 0, "No such a keeper");
        require(keeper_addr != MiningOwner, "Can not delete MiningOwner");
        string memory keeper_name = keepers[keeper_addr];
        delete keepers[keeper_addr];
        emit remove_keeper_EVENT(keeper_addr, keeper_name);
    }

    modifier onlyKeeper() {
        require(bytes(keepers[msg.sender]).length != 0, "No such a keeper");
        _;
    }

    event add_merkle_root_EVENT(bytes32 merkleRoot, uint256 blocktime);

    function add_merkle_root(bytes32 merkleRoot, uint256 amount)
        external
        onlyKeeper
    {
        merkleRoots[merkleRoot] = amount + 1; // +1 for never to 0 again
        emit add_merkle_root_EVENT(merkleRoot, merkleRoots[merkleRoot]);
    }

    event remove_merkle_root_EVENT(
        address _from,
        bytes32 merkleRoot,
        uint256 blocktime
    );

    function remove_merkle_root(bytes32 merkleRoot) external onlyMiningOwner {
        delete merkleRoots[merkleRoot];
        emit remove_merkle_root_EVENT(msg.sender, merkleRoot, block.timestamp);
    }

    function get_merkle_root(bytes32 merkleRoot) public view returns (uint256) {
        return merkleRoots[merkleRoot];
    }

    event claim_erc20_EVENT(
        bytes32 merkleRoot,
        address to,
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
        require(
            MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "Not verified"
        );

        require(merkleRoots[merkleRoot] > amount, "Not enough balance");
        merkleRoots[merkleRoot] -= amount;

        claimed[merkleRoot][index] = true;
        bool result = IERC20(MSNAddr).transfer(msg.sender, amount);
        if (result) {
            emit claim_erc20_EVENT(
                merkleRoot,
                msg.sender,
                amount,
                block.timestamp
            );
        } else {
            claimed[merkleRoot][index] = false;
        }
    }

    receive() external payable {
        payable_amount += msg.value;
    }

    fallback() external payable {
        payable_amount += msg.value;
    }

    function withdraw_eth() external onlyMiningOwner {
        payable(msg.sender).transfer(address(this).balance);
        payable_amount = 0;
    }
}
