// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract SecureDAO {
    mapping(address => uint256) public balances;
    bool private locked;
    uint256 public constant MIN_DEPOSIT = 1 ether;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    modifier noReentrancy() {
        require(!locked, "SecureDAO: reentrancy detected");
        locked = true;
        _;
        locked = false;
    }

    function deposit() public payable {
        require(msg.value >= MIN_DEPOSIT, "SecureDAO: minimum deposit is 1 ETH");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw() public noReentrancy {
        require(balances[msg.sender] >= MIN_DEPOSIT, "SecureDAO: insufficient funds");
        uint256 bal = balances[msg.sender];

        // FIX: Update balance BEFORE external call
        balances[msg.sender] = 0;

        // Now send ETH - if reentrancy is attempted, balance is already 0
        (bool sent,) = msg.sender.call{value: bal}("");
        require(sent, "SecureDAO: failed to send ETH");

        emit Withdraw(msg.sender, bal);
    }

    function daoBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getBalance(address user) public view returns (uint256) {
        return balances[user];
    }
}
