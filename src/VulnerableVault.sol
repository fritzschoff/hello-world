// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VulnerableVault is ERC4626 {
    constructor(IERC20 asset_) ERC4626(asset_) ERC20("Vulnerable Vault", "VV") {}

    function totalAssets() public view override returns (uint256) {
        return IERC20(asset()).balanceOf(address(this));
    }

    function convertToShares(uint256 assets) public view override returns (uint256) {
        uint256 supply = totalSupply();
        if (supply == 0) {
            return assets;
        }
        return (supply * assets) / totalAssets();
    }

    function convertToAssets(uint256 shares) public view override returns (uint256) {
        uint256 supply = totalSupply();
        if (supply == 0) {
            return 0;
        }
        return (totalAssets() * shares) / supply;
    }

    function deposit(uint256 assets, address receiver) public override returns (uint256) {
        require(assets <= maxDeposit(receiver), "ERC4626: deposit more than max");

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        IERC20(asset()).transferFrom(caller, address(this), assets);
        _mint(receiver, shares);
        emit Deposit(caller, receiver, assets, shares);
    }

    function withdraw(uint256 assets, address receiver, address owner) public override returns (uint256) {
        require(assets <= maxWithdraw(owner), "ERC4626: withdraw more than max");

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
    {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        _burn(owner, shares);
        IERC20(asset()).transfer(receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function redeem(uint256 shares, address receiver, address owner) public override returns (uint256) {
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");

        uint256 assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    function previewDeposit(uint256 assets) public view override returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view override returns (uint256) {
        uint256 supply = totalSupply();
        if (supply == 0) {
            return shares;
        }
        return (totalAssets() * shares) / supply;
    }

    function previewWithdraw(uint256 assets) public view override returns (uint256) {
        uint256 supply = totalSupply();
        if (supply == 0) {
            return 0;
        }
        return (supply * assets) / totalAssets();
    }

    function previewRedeem(uint256 shares) public view override returns (uint256) {
        return convertToAssets(shares);
    }

    function maxDeposit(address) public view override returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view override returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view override returns (uint256) {
        return convertToAssets(balanceOf(owner));
    }

    function maxRedeem(address owner) public view override returns (uint256) {
        return balanceOf(owner);
    }
}
