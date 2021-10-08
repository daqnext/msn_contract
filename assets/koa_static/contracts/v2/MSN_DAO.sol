// SPDX-License-Identifier: GPL v3
// README: https://github.com/daqnext/msn_contracts/blob/main/assets/koa_static/contracts/v2/proposal

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MSN_DAO {
    uint256 payable_amount;

    struct Proposal {
        uint16 pid; // proposal identifier
        address creator; // address of the shareholder who created the proposal
        uint256 startTime; // a unix timestamp, denoting the start of the voting period
        uint256 endTime; // a unix timestamp, denoting the end of the voting period
    }

    mapping(uint16 => Proposal) private proposals; // pid => proposal
    mapping(uint16 => mapping(uint8 => uint256)) private proposal_votes; // pid => (option => total_votes)
    mapping(address => mapping(uint16 => uint8)) private votes; // voter => (pid => selected option), selected option should start from 1

    string private ProposalFolderUrl; // the detailed proposal description is inside this folder
    address private DAOOwner;
    address private MSNAddr;

    mapping(address => string) private keepers; // who can create and manage proposals
    mapping(address => uint256) private deposit; // depositor => amount
    mapping(address => uint256) private deposit_lasttime; // depositor => last vote time
    uint256 private voter_hold_secs; // how long in seconds to keep before voters withdraw

    constructor(address _MSNcontractAddr, uint256 _voter_hold_secs) {
        DAOOwner = msg.sender;
        MSNAddr = _MSNcontractAddr;
        keepers[msg.sender] = "DAOOwner";
        voter_hold_secs = _voter_hold_secs;
    }

    modifier onlyDAOOwner() {
        require(msg.sender == DAOOwner, "Only DAOOwner");
        _;
    }

    event change_DAOOwner_EVENT(
        address trigger_user_addr,
        address oldOwner,
        address newOwner,
        uint256 blocktime
    );

    function change_DAOOwner(address _newOwner) external onlyDAOOwner {
        require(
            _newOwner != DAOOwner,
            "The new owner must be different from the old"
        );
        address oldDAOOwner = DAOOwner;
        delete keepers[oldDAOOwner];
        DAOOwner = _newOwner;
        keepers[_newOwner] = "DAOOwner";
        emit change_DAOOwner_EVENT(
            msg.sender,
            oldDAOOwner,
            _newOwner,
            block.timestamp
        );
    }

    function get_DAOOwner() external view returns (address) {
        return DAOOwner;
    }

    function set_ProposalFolderUrl(string calldata _url) external onlyDAOOwner {
        ProposalFolderUrl = _url;
    }

    function get_ProposalFolderUrl() external view returns (string memory) {
        return ProposalFolderUrl;
    }

    modifier onlyKeeper() {
        require(bytes(keepers[msg.sender]).length != 0, "No such a Keeper");
        _;
    }

    event add_keeper_EVENT(
        address trigger_user_addr,
        address keeper_addr,
        string keeper_name,
        uint256 blocktime
    );

    function add_keeper(address keeper_addr, string calldata keeper_name)
        external
        onlyDAOOwner
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

    function get_keeper(address keeper_addr)
        public
        view
        returns (string memory)
    {
        require(bytes(keepers[keeper_addr]).length != 0, "No such a keeper");
        return keepers[keeper_addr];
    }

    event remove_keeper_EVENT(
        address trigger_user_addr,
        address keeper_addr,
        string keeper_name,
        uint256 blocktime
    );

    function remove_keeper(address keeper_addr) external onlyDAOOwner {
        require(bytes(keepers[keeper_addr]).length != 0, "No such a keeper");
        require(keeper_addr != DAOOwner, "Can not delete DAOOwner");
        string memory keeper_name = keepers[keeper_addr];
        delete keepers[keeper_addr];
        emit remove_keeper_EVENT(
            msg.sender,
            keeper_addr,
            keeper_name,
            block.timestamp
        );
    }

    function set_voter_hold_secs(uint256 secs) public onlyDAOOwner {
        voter_hold_secs = secs;
    }

    function get_voter_hold_secs() public view returns (uint256) {
        return voter_hold_secs;
    }

    function get_blocktime() public view returns (uint256) {
        return block.timestamp;
    }

    event set_proposal_EVENT(
        address trigger_user_addr,
        uint16 _pid,
        uint256 _startTime,
        uint256 _endTime,
        uint256 blocktime
    );

    function set_proposal(
        uint16 _pid,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyKeeper {
        require(proposals[_pid].pid == 0, "The proposal already exists");
        require(
            _endTime > block.timestamp,
            "EndTime must be bigger than blocktime"
        );
        require(
            _startTime < _endTime,
            "StartTime must be smaller than endTime"
        );
        proposals[_pid] = Proposal(_pid, msg.sender, _startTime, _endTime);
        emit set_proposal_EVENT(
            msg.sender,
            _pid,
            _startTime,
            _endTime,
            block.timestamp
        );
    }

    event remove_proposal_EVENT(
        address trigger_user_addr,
        uint16 _pid,
        uint256 blocktime
    );

    function remove_proposal(uint16 _pid) external onlyKeeper {
        require(proposals[_pid].pid != 0, "The proposal doesn't exist");
        require(
            (proposals[_pid].creator == msg.sender) || (msg.sender == DAOOwner),
            "No permission to remove the proposal"
        );
        delete proposals[_pid];
        emit remove_proposal_EVENT(msg.sender, _pid, block.timestamp);
    }

    function get_proposal(uint16 _pid)
        external
        view
        returns (
            uint16,
            address,
            uint256,
            uint256
        )
    {
        require(proposals[_pid].pid != 0, "The proposal doesn't exist");
        return (
            _pid,
            proposals[_pid].creator,
            proposals[_pid].startTime,
            proposals[_pid].endTime
        );
    }

    event deposit_token_EVENT(
        address trigger_user_addr,
        uint256 amount,
        uint256 blocktime
    );

    function deposit_token(uint256 amount) external {
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

        deposit[msg.sender] += amount;
        deposit_lasttime[msg.sender] = block.timestamp;
        emit deposit_token_EVENT(msg.sender, amount, block.timestamp);
    }

    function get_deposit(address addr) public view returns (uint256) {
        return deposit[addr];
    }

    function get_deposit_lasttime(address addr) public view returns (uint256) {
        return deposit_lasttime[addr];
    }

    event vote_EVENT(
        address trigger_user_addr,
        uint16 _pid,
        uint8 _option,
        uint256 _all_votes,
        uint256 blocktime
    );

    function vote(uint16 _pid, uint8 _option) external {
        require(_pid > 0, "Pid should start from 1");
        require(proposals[_pid].pid != 0, "The proposal doesn't exist");
        require(
            proposals[_pid].startTime < block.timestamp,
            "The proposal doesn't start yet"
        );
        require(
            proposals[_pid].endTime > block.timestamp,
            "The proposal already ends voting"
        );
        require(deposit[msg.sender] > 0, "No deposit");
        require(votes[msg.sender][_pid] == 0, "Voted already");

        votes[msg.sender][_pid] = _option;
        proposal_votes[_pid][_option] += deposit[msg.sender];

        emit vote_EVENT(
            msg.sender,
            _pid,
            _option,
            proposal_votes[_pid][_option],
            block.timestamp
        );
    }

    function get_proposal_votes(uint16 _pid, uint8 _option)
        external
        view
        returns (uint256)
    {
        require(proposals[_pid].pid != 0, "The proposal doesn't exist");
        return proposal_votes[_pid][_option];
    }

    event withdraw_token_EVENT(
        address trigger_user_addr,
        uint256 amount,
        uint256 blocktime
    );

    function withdraw_token(uint256 amount) external {
        require(
            deposit_lasttime[msg.sender] + voter_hold_secs < block.timestamp,
            "Not enough time"
        );
        uint256 d_amount = deposit[msg.sender];
        require(d_amount >= amount, "not enough to withdraw");
        deposit[msg.sender] = d_amount - amount;
        bool t_result = IERC20(MSNAddr).transfer(msg.sender, amount);
        require(t_result == true, "transfer error");
        emit withdraw_token_EVENT(msg.sender, amount, block.timestamp);
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


    function withdraw_eth() external onlyDAOOwner {
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

    function withdraw_contract() public onlyDAOOwner {
        uint256 left = IERC20(MSNAddr).balanceOf(address(this));
        require(left > 0, "No Balance");
        IERC20(MSNAddr).transfer(msg.sender, left);
        emit withdraw_contract_EVENT(
            msg.sender,
            address(this),
            left,
            block.timestamp
        );
    }
}
