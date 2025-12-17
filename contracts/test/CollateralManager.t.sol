// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {Stablecoin} from "../src/Stablecoin.sol";
import {CollateralManager} from "../src/CollateralManager.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MOCK") {
        _mint(msg.sender, type(uint128).max);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract MockVault is ERC4626 {
    constructor(ERC20 asset_) ERC4626(asset_) ERC20("Mock Vault", "MVAULT") {}

    function totalAssets() public view override returns (uint256) {
        return IERC20(asset()).balanceOf(address(this));
    }
}

contract CollateralManagerTest is Test {
    Stablecoin public stablecoin;
    CollateralManager public collateralManager;
    MockERC20 public asset;
    MockVault public vault;

    address public owner = address(1);
    address public user = address(2);
    address public liquidator = address(3);

    uint256 public constant INITIAL_BALANCE = 1000000e18;

    function setUp() public {
        vm.startPrank(owner);

        Stablecoin stablecoinImpl = new Stablecoin();
        bytes memory stablecoinInitData = abi.encodeCall(Stablecoin.initialize, (owner));
        ERC1967Proxy stablecoinProxy = new ERC1967Proxy(address(stablecoinImpl), stablecoinInitData);
        stablecoin = Stablecoin(address(stablecoinProxy));

        CollateralManager managerImpl = new CollateralManager();
        bytes memory managerInitData = abi.encodeCall(CollateralManager.initialize, (address(stablecoin), owner));
        ERC1967Proxy managerProxy = new ERC1967Proxy(address(managerImpl), managerInitData);
        collateralManager = CollateralManager(address(managerProxy));

        stablecoin.setMinter(address(collateralManager));

        asset = new MockERC20();
        vault = new MockVault(asset);

        collateralManager.addSupportedVault(IERC4626(address(vault)));

        asset.mint(user, INITIAL_BALANCE);
        asset.mint(liquidator, INITIAL_BALANCE);

        vm.stopPrank();
    }

    function test_DepositCollateral(uint256 depositAmount) public {
        vm.assume(depositAmount > 0 && depositAmount <= INITIAL_BALANCE);

        vm.startPrank(user);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, user);

        vault.approve(address(collateralManager), shares);
        collateralManager.depositCollateral(IERC4626(address(vault)), shares);
        vm.stopPrank();

        assertEq(collateralManager.collateralShares(user, IERC4626(address(vault))), shares);

        uint256 expectedStablecoin = (depositAmount * 10000) / 15000;
        assertEq(stablecoin.balanceOf(user), expectedStablecoin);
        assertEq(collateralManager.userDebt(user), expectedStablecoin);
    }

    function test_DepositCollateralFuzz(address depositor, uint256 depositAmount) public {
        vm.assume(depositor != address(0) && depositor != address(vault));
        vm.assume(depositor != address(collateralManager));
        vm.assume(depositAmount >= 1000 && depositAmount <= INITIAL_BALANCE);

        asset.mint(depositor, depositAmount);

        vm.startPrank(depositor);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, depositor);

        if (shares == 0) {
            vm.stopPrank();
            return;
        }

        vault.approve(address(collateralManager), shares);
        collateralManager.depositCollateral(IERC4626(address(vault)), shares);
        vm.stopPrank();

        assertGt(collateralManager.collateralShares(depositor, IERC4626(address(vault))), 0);
        assertGt(stablecoin.balanceOf(depositor), 0);
    }

    function test_WithdrawCollateral(uint256 depositAmount, uint256 withdrawShares) public {
        vm.assume(depositAmount > 1000 && depositAmount <= INITIAL_BALANCE);

        vm.startPrank(user);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, user);

        vault.approve(address(collateralManager), shares);
        collateralManager.depositCollateral(IERC4626(address(vault)), shares);

        uint256 debt = collateralManager.userDebt(user);
        if (debt > 0) {
            stablecoin.approve(address(collateralManager), debt);
            collateralManager.repayDebt(debt);
        }

        vm.assume(withdrawShares > 0 && withdrawShares <= shares);
        collateralManager.withdrawCollateral(IERC4626(address(vault)), withdrawShares);
        vm.stopPrank();

        assertEq(collateralManager.collateralShares(user, IERC4626(address(vault))), shares - withdrawShares);
    }

    function test_RepayDebt(uint256 depositAmount, uint256 repayAmount) public {
        vm.assume(depositAmount > 1000 && depositAmount <= INITIAL_BALANCE);

        vm.startPrank(user);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, user);

        vault.approve(address(collateralManager), shares);
        collateralManager.depositCollateral(IERC4626(address(vault)), shares);

        uint256 debt = collateralManager.userDebt(user);
        vm.assume(repayAmount > 0 && repayAmount <= debt);

        stablecoin.approve(address(collateralManager), repayAmount);
        collateralManager.repayDebt(repayAmount);
        vm.stopPrank();

        assertEq(collateralManager.userDebt(user), debt - repayAmount);
    }

    function test_RepayDebtWithPermit(uint256 depositAmount, uint256 privateKey) public {
        vm.assume(depositAmount > 1000 && depositAmount <= INITIAL_BALANCE);
        vm.assume(privateKey > 0 && privateKey < type(uint256).max / 2);

        address permitUser = vm.addr(privateKey);
        asset.mint(permitUser, depositAmount);

        vm.startPrank(permitUser);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, permitUser);

        vault.approve(address(collateralManager), shares);
        collateralManager.depositCollateral(IERC4626(address(vault)), shares);
        vm.stopPrank();

        uint256 debt = collateralManager.userDebt(permitUser);
        uint256 deadline = block.timestamp + 1 days;

        bytes32 domainSeparator = stablecoin.DOMAIN_SEPARATOR();
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                permitUser,
                address(collateralManager),
                debt,
                stablecoin.nonces(permitUser),
                deadline
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        collateralManager.repayDebtWithPermit(permitUser, debt, deadline, v, r, s);

        assertEq(collateralManager.userDebt(permitUser), 0);
    }

    function test_Liquidate(uint256 depositAmount) public {
        vm.assume(depositAmount > 10000 && depositAmount <= INITIAL_BALANCE);

        address anotherUser = address(5);
        asset.mint(anotherUser, depositAmount * 2);

        vm.startPrank(anotherUser);
        asset.approve(address(vault), depositAmount * 2);
        uint256 anotherShares = vault.deposit(depositAmount * 2, anotherUser);
        vault.approve(address(collateralManager), anotherShares);
        collateralManager.depositCollateral(IERC4626(address(vault)), anotherShares);
        uint256 anotherDebt = collateralManager.userDebt(anotherUser);
        vm.stopPrank();

        vm.startPrank(user);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, user);

        vault.approve(address(collateralManager), shares);
        collateralManager.depositCollateral(IERC4626(address(vault)), shares);
        vm.stopPrank();

        uint256 debt = collateralManager.userDebt(user);
        uint256 collateralValue = vault.convertToAssets(shares);

        vm.startPrank(anotherUser);
        stablecoin.transfer(liquidator, anotherDebt);
        vm.stopPrank();

        vm.warp(block.timestamp + 365 days);

        vm.startPrank(liquidator);
        uint256 assetsToRemove = (collateralValue * 60) / 100;

        vm.stopPrank();
        vm.prank(address(vault));
        asset.transfer(address(0xdead), assetsToRemove);

        vm.startPrank(liquidator);
        require(collateralManager.isLiquidatable(user), "Position must be liquidatable");

        stablecoin.approve(address(collateralManager), debt);

        uint256 collateralBefore = vault.balanceOf(liquidator);
        collateralManager.liquidate(user, IERC4626(address(vault)), debt);
        uint256 collateralAfter = vault.balanceOf(liquidator);

        vm.stopPrank();

        assertGt(collateralAfter, collateralBefore);
        assertEq(collateralManager.userDebt(user), 0);
    }

    function test_IsLiquidatable(uint256 depositAmount) public {
        vm.assume(depositAmount > 1000 && depositAmount <= INITIAL_BALANCE);

        vm.startPrank(user);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, user);

        vault.approve(address(collateralManager), shares);
        collateralManager.depositCollateral(IERC4626(address(vault)), shares);
        vm.stopPrank();

        assertFalse(collateralManager.isLiquidatable(user));

        vm.warp(block.timestamp + 365 days);
        vm.prank(address(vault));
        asset.transfer(address(0xdead), depositAmount / 2);

        assertTrue(collateralManager.isLiquidatable(user));
    }

    function test_HealthFactor(uint256 depositAmount) public {
        vm.assume(depositAmount > 1000 && depositAmount <= INITIAL_BALANCE);

        vm.startPrank(user);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, user);

        vault.approve(address(collateralManager), shares);
        collateralManager.depositCollateral(IERC4626(address(vault)), shares);
        vm.stopPrank();

        uint256 healthFactor = collateralManager.getHealthFactor(user);
        assertGe(healthFactor, 15000);
    }

    function test_SetCollateralizationRatio(uint256 newRatio) public {
        vm.assume(newRatio >= 10000 && newRatio <= 30000);

        uint256 oldRatio = collateralManager.collateralizationRatio();

        vm.prank(owner);
        collateralManager.setCollateralizationRatio(newRatio);

        assertEq(collateralManager.collateralizationRatio(), newRatio);
    }

    function test_SetLiquidationBonus(uint256 newBonus) public {
        vm.assume(newBonus <= 2000);

        uint256 oldBonus = collateralManager.liquidationBonus();

        vm.prank(owner);
        collateralManager.setLiquidationBonus(newBonus);

        assertEq(collateralManager.liquidationBonus(), newBonus);
    }

    function test_RevertDeposit_UnsupportedVault() public {
        MockVault unsupportedVault = new MockVault(asset);

        vm.startPrank(user);
        asset.approve(address(unsupportedVault), 1000);
        uint256 shares = unsupportedVault.deposit(1000, user);

        unsupportedVault.approve(address(collateralManager), shares);
        vm.expectRevert("CollateralManager: vault not supported");
        collateralManager.depositCollateral(IERC4626(address(unsupportedVault)), shares);
        vm.stopPrank();
    }

    function test_RevertWithdraw_InsufficientCollateralization() public {
        vm.startPrank(user);
        asset.approve(address(vault), 10000);
        uint256 shares = vault.deposit(10000, user);

        vault.approve(address(collateralManager), shares);
        collateralManager.depositCollateral(IERC4626(address(vault)), shares);

        vm.expectRevert("CollateralManager: insufficient collateralization ratio");
        collateralManager.withdrawCollateral(IERC4626(address(vault)), shares);
        vm.stopPrank();
    }

    function test_RevertLiquidate_NotLiquidatable() public {
        address anotherUser = address(5);
        asset.mint(anotherUser, 20000);

        vm.startPrank(anotherUser);
        asset.approve(address(vault), 20000);
        uint256 anotherShares = vault.deposit(20000, anotherUser);
        vault.approve(address(collateralManager), anotherShares);
        collateralManager.depositCollateral(IERC4626(address(vault)), anotherShares);
        uint256 anotherDebt = collateralManager.userDebt(anotherUser);
        vm.stopPrank();

        vm.startPrank(user);
        asset.approve(address(vault), 10000);
        uint256 shares = vault.deposit(10000, user);

        vault.approve(address(collateralManager), shares);
        collateralManager.depositCollateral(IERC4626(address(vault)), shares);
        vm.stopPrank();

        uint256 debt = collateralManager.userDebt(user);

        vm.startPrank(anotherUser);
        stablecoin.transfer(liquidator, anotherDebt);
        vm.stopPrank();

        vm.startPrank(liquidator);
        stablecoin.approve(address(collateralManager), debt);

        vm.expectRevert("CollateralManager: position not liquidatable");
        collateralManager.liquidate(user, IERC4626(address(vault)), debt);
        vm.stopPrank();
    }
}
