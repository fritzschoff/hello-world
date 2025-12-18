// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract VulnerableDAO {
    mapping(address => uint256) public balances;
    uint256 public constant MIN_DEPOSIT = 1 ether;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    function deposit() public payable {
        require(msg.value >= MIN_DEPOSIT, "VulnerableDAO: minimum deposit is 1 ETH");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw() public {
        require(balances[msg.sender] >= MIN_DEPOSIT, "VulnerableDAO: insufficient funds");
        uint256 bal = balances[msg.sender];

        // VULNERABILITY: Sending ETH before updating balance allows reentrancy
        (bool sent,) = msg.sender.call{value: bal}("");
        require(sent, "VulnerableDAO: failed to send ETH");

        // Balance is updated AFTER the external call
        balances[msg.sender] = 0;
        emit Withdraw(msg.sender, bal);
    }

    function daoBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getBalance(address user) public view returns (uint256) {
        return balances[user];
    }
}
