// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {VulnerableDAO} from "../src/VulnerableDAO.sol";
import {ReentrancyAttacker} from "../src/ReentrancyAttacker.sol";
import {SecureDAO} from "../src/SecureDAO.sol";

contract ReentrancyAttackTest is Test {
    VulnerableDAO public vulnerableDAO;
    SecureDAO public secureDAO;
    ReentrancyAttacker public attacker;

    address public victim1 = address(0x1111);
    address public victim2 = address(0x2222);
    address public hacker = address(0xBAD);

    function setUp() public {
        vulnerableDAO = new VulnerableDAO();
        secureDAO = new SecureDAO();
    }

    function test_VulnerableDAO_ReentrancyAttack() public {
        // Setup: Victims deposit funds
        vm.deal(victim1, 10 ether);
        vm.deal(victim2, 10 ether);
        vm.deal(hacker, 1 ether);

        vm.startPrank(victim1);
        vulnerableDAO.deposit{value: 5 ether}();
        vm.stopPrank();

        vm.startPrank(victim2);
        vulnerableDAO.deposit{value: 5 ether}();
        vm.stopPrank();

        assertEq(vulnerableDAO.daoBalance(), 10 ether, "DAO should have 10 ETH");
        assertEq(vulnerableDAO.getBalance(victim1), 5 ether, "Victim1 should have 5 ETH balance");
        assertEq(vulnerableDAO.getBalance(victim2), 5 ether, "Victim2 should have 5 ETH balance");

        // Attack: Hacker deploys attacker contract and executes attack
        vm.startPrank(hacker);
        attacker = new ReentrancyAttacker(address(vulnerableDAO));
        attacker.attack{value: 1 ether}();
        vm.stopPrank();

        // Verify attack succeeded
        uint256 hackerBalance = attacker.getBalance();
        assertGt(hackerBalance, 1 ether, "Hacker should have stolen more than their initial deposit");
        assertEq(vulnerableDAO.daoBalance(), 0, "DAO should be drained");
        assertEq(vulnerableDAO.getBalance(address(attacker)), 0, "Attacker's balance in DAO should be 0");
    }

    function test_SecureDAO_ReentrancyPrevented() public {
        // Setup: Victims deposit funds
        vm.deal(victim1, 10 ether);
        vm.deal(victim2, 10 ether);
        vm.deal(hacker, 1 ether);

        vm.startPrank(victim1);
        secureDAO.deposit{value: 5 ether}();
        vm.stopPrank();

        vm.startPrank(victim2);
        secureDAO.deposit{value: 5 ether}();
        vm.stopPrank();

        assertEq(secureDAO.daoBalance(), 10 ether, "DAO should have 10 ETH");

        // Attack attempt: Hacker tries to exploit
        vm.startPrank(hacker);
        ReentrancyAttacker secureAttacker = new ReentrancyAttacker(address(secureDAO));

        // The attack will fail - either due to reentrancy guard or because balance is updated first
        // The exact error depends on which protection mechanism triggers first
        try secureAttacker.attack{value: 1 ether}() {
            // If attack somehow succeeds, verify funds are still safe
            assertEq(secureDAO.daoBalance(), 10 ether, "DAO should still have 10 ETH");
        } catch {
            // Attack failed as expected
        }
        vm.stopPrank();

        // Verify funds are safe
        assertEq(secureDAO.daoBalance(), 10 ether, "DAO should still have 10 ETH");
        // The attacker's balance should be 0 because SecureDAO updates balance before sending ETH
        // When the attack fails due to reentrancy guard, the balance was already set to 0
        assertEq(
            secureDAO.getBalance(address(secureAttacker)), 0, "Attacker's balance should be 0 (updated before send)"
        );
    }

    function test_VulnerableDAO_NormalWithdraw() public {
        vm.deal(victim1, 10 ether);

        vm.startPrank(victim1);
        vulnerableDAO.deposit{value: 5 ether}();
        assertEq(vulnerableDAO.getBalance(victim1), 5 ether, "Balance should be 5 ETH");

        vulnerableDAO.withdraw();
        vm.stopPrank();

        assertEq(vulnerableDAO.getBalance(victim1), 0, "Balance should be 0 after withdraw");
        assertEq(victim1.balance, 10 ether, "Victim should have their ETH back");
        assertEq(vulnerableDAO.daoBalance(), 0, "DAO should be empty");
    }

    function test_VulnerableDAO_MultipleDeposits() public {
        vm.deal(victim1, 10 ether);

        vm.startPrank(victim1);
        vulnerableDAO.deposit{value: 2 ether}();
        vulnerableDAO.deposit{value: 3 ether}();
        vm.stopPrank();

        assertEq(vulnerableDAO.getBalance(victim1), 5 ether, "Balance should be sum of deposits");
        assertEq(vulnerableDAO.daoBalance(), 5 ether, "DAO should have 5 ETH");
    }

    function test_ReentrancyAttack_Fuzz(uint256 victimDeposit, uint256 hackerDeposit) public {
        // Bound to reasonable values to avoid gas issues
        victimDeposit = bound(victimDeposit, 1 ether, 50 ether);
        hackerDeposit = bound(hackerDeposit, 1 ether, 5 ether);

        vm.deal(victim1, victimDeposit);
        vm.deal(hacker, hackerDeposit);

        vm.startPrank(victim1);
        vulnerableDAO.deposit{value: victimDeposit}();
        vm.stopPrank();

        vm.startPrank(hacker);
        attacker = new ReentrancyAttacker(address(vulnerableDAO));

        // Try the attack - it may fail with very large amounts due to gas limits
        try attacker.attack{value: hackerDeposit}() {
            // Attack succeeded - verify hacker profited
            uint256 hackerProfit = attacker.getBalance();
            assertGt(hackerProfit, hackerDeposit, "Hacker should have more than initial deposit");
            // DAO should be drained or significantly reduced
            assertLe(vulnerableDAO.daoBalance(), victimDeposit / 2, "DAO should be mostly drained");
        } catch {
            // Attack failed (likely due to gas limits with large amounts) - this is acceptable
            // Just verify the DAO still has funds
            assertGe(vulnerableDAO.daoBalance(), victimDeposit, "DAO should still have victim's deposit");
        }
        vm.stopPrank();
    }

    function test_ReentrancyAttack_AttackCount() public {
        vm.deal(victim1, 10 ether);
        vm.deal(hacker, 1 ether);

        vm.startPrank(victim1);
        vulnerableDAO.deposit{value: 5 ether}();
        vm.stopPrank();

        vm.startPrank(hacker);
        attacker = new ReentrancyAttacker(address(vulnerableDAO));
        attacker.attack{value: 1 ether}();
        vm.stopPrank();

        // Attack count should reflect number of reentrancy calls
        assertGt(attacker.attackCount(), 0, "Attack count should be greater than 0");
    }
}

