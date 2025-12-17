// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Stablecoin} from "./Stablecoin.sol";

contract CollateralManager is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC4626;

    Stablecoin public stablecoin;
    uint256 public collateralizationRatio;
    uint256 public constant RATIO_PRECISION = 10000;
    uint256 public liquidationBonus;
    uint256 public constant BONUS_PRECISION = 10000;

    IERC4626[] public supportedVaults;
    mapping(IERC4626 vault => bool) public isSupportedVault;
    mapping(address user => mapping(IERC4626 vault => uint256 shares)) public collateralShares;
    mapping(address user => uint256 totalDebt) public userDebt;

    event CollateralDeposited(address indexed user, IERC4626 indexed vault, uint256 shares, uint256 stablecoinMinted);
    event CollateralWithdrawn(address indexed user, IERC4626 indexed vault, uint256 shares);
    event DebtRepaid(address indexed user, uint256 amount);
    event VaultAdded(IERC4626 indexed vault);
    event VaultRemoved(IERC4626 indexed vault);
    event PositionLiquidated(
        address indexed user,
        address indexed liquidator,
        IERC4626 indexed vault,
        uint256 debtRepaid,
        uint256 collateralSeized,
        uint256 bonus
    );
    event CollateralizationRatioUpdated(uint256 oldRatio, uint256 newRatio);
    event LiquidationBonusUpdated(uint256 oldBonus, uint256 newBonus);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _stablecoin, address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        stablecoin = Stablecoin(_stablecoin);
        collateralizationRatio = 15000;
        liquidationBonus = 500;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setCollateralizationRatio(uint256 newRatio) external onlyOwner {
        require(newRatio >= 10000, "CollateralManager: ratio must be at least 100%");
        require(newRatio <= 30000, "CollateralManager: ratio must be at most 300%");
        uint256 oldRatio = collateralizationRatio;
        collateralizationRatio = newRatio;
        emit CollateralizationRatioUpdated(oldRatio, newRatio);
    }

    function setLiquidationBonus(uint256 newBonus) external onlyOwner {
        require(newBonus <= 2000, "CollateralManager: bonus must be at most 20%");
        uint256 oldBonus = liquidationBonus;
        liquidationBonus = newBonus;
        emit LiquidationBonusUpdated(oldBonus, newBonus);
    }

    function addSupportedVault(IERC4626 vault) external onlyOwner {
        require(!isSupportedVault[vault], "CollateralManager: vault already supported");
        isSupportedVault[vault] = true;
        supportedVaults.push(vault);
        emit VaultAdded(vault);
    }

    function removeSupportedVault(IERC4626 vault) external onlyOwner {
        require(isSupportedVault[vault], "CollateralManager: vault not supported");
        isSupportedVault[vault] = false;
        emit VaultRemoved(vault);
    }

    function depositCollateral(IERC4626 vault, uint256 shares) external {
        require(shares > 0, "CollateralManager: shares must be greater than 0");
        require(isSupportedVault[vault], "CollateralManager: vault not supported");

        vault.safeTransferFrom(msg.sender, address(this), shares);

        collateralShares[msg.sender][vault] += shares;

        uint256 totalCollateralValue = getTotalCollateralValue(msg.sender);
        uint256 currentDebt = userDebt[msg.sender];
        uint256 availableCollateralValue = totalCollateralValue;
        uint256 requiredCollateralForDebt = (currentDebt * collateralizationRatio) / RATIO_PRECISION;

        if (availableCollateralValue > requiredCollateralForDebt) {
            uint256 excessCollateral = availableCollateralValue - requiredCollateralForDebt;
            uint256 stablecoinToMint = (excessCollateral * RATIO_PRECISION) / collateralizationRatio;

            if (stablecoinToMint > 0) {
                stablecoin.mint(msg.sender, stablecoinToMint);
                userDebt[msg.sender] += stablecoinToMint;
                emit CollateralDeposited(msg.sender, vault, shares, stablecoinToMint);
                return;
            }
        }

        emit CollateralDeposited(msg.sender, vault, shares, 0);
    }

    function withdrawCollateral(IERC4626 vault, uint256 shares) external {
        require(shares > 0, "CollateralManager: shares must be greater than 0");
        require(collateralShares[msg.sender][vault] >= shares, "CollateralManager: insufficient collateral");

        uint256 collateralValue = vault.convertToAssets(shares);
        uint256 totalCollateralValue = getTotalCollateralValue(msg.sender);
        uint256 currentDebt = userDebt[msg.sender];
        uint256 collateralValueAfter = totalCollateralValue - collateralValue;
        uint256 minRequiredCollateral = (currentDebt * collateralizationRatio) / RATIO_PRECISION;

        require(
            collateralValueAfter >= minRequiredCollateral, "CollateralManager: insufficient collateralization ratio"
        );

        collateralShares[msg.sender][vault] -= shares;
        vault.safeTransfer(msg.sender, shares);

        emit CollateralWithdrawn(msg.sender, vault, shares);
    }

    function repayDebt(uint256 amount) external {
        require(amount > 0, "CollateralManager: amount must be greater than 0");
        require(userDebt[msg.sender] >= amount, "CollateralManager: insufficient debt");

        IERC20(address(stablecoin)).safeTransferFrom(msg.sender, address(this), amount);
        stablecoin.burn(address(this), amount);
        userDebt[msg.sender] -= amount;

        emit DebtRepaid(msg.sender, amount);
    }

    function repayDebtWithPermit(address user, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
    {
        require(amount > 0, "CollateralManager: amount must be greater than 0");
        require(userDebt[user] >= amount, "CollateralManager: insufficient debt");

        IERC20Permit(address(stablecoin)).permit(user, address(this), amount, deadline, v, r, s);

        IERC20(address(stablecoin)).safeTransferFrom(user, address(this), amount);
        stablecoin.burn(address(this), amount);
        userDebt[user] -= amount;

        emit DebtRepaid(user, amount);
    }

    function getTotalCollateralValue(address user) public view returns (uint256) {
        uint256 totalValue = 0;
        uint256 length = supportedVaults.length;
        for (uint256 i = 0; i < length; i++) {
            IERC4626 vault = supportedVaults[i];
            if (!isSupportedVault[vault]) continue;
            totalValue += getCollateralValue(user, vault);
        }
        return totalValue;
    }

    function getCollateralValue(address user, IERC4626 vault) public view returns (uint256) {
        uint256 shares = collateralShares[user][vault];
        if (shares == 0) return 0;
        return vault.convertToAssets(shares);
    }

    function getHealthFactor(address user) public view returns (uint256) {
        uint256 totalCollateral = getTotalCollateralValue(user);
        uint256 debt = userDebt[user];
        if (debt == 0) return type(uint256).max;
        return (totalCollateral * RATIO_PRECISION) / debt;
    }

    function isLiquidatable(address user) public view returns (bool) {
        uint256 healthFactor = getHealthFactor(user);
        return healthFactor < collateralizationRatio;
    }

    function liquidate(address user, IERC4626 vault, uint256 debtToRepay) external {
        require(user != msg.sender, "CollateralManager: cannot liquidate own position");
        require(isLiquidatable(user), "CollateralManager: position not liquidatable");
        require(isSupportedVault[vault], "CollateralManager: vault not supported");
        require(collateralShares[user][vault] > 0, "CollateralManager: no collateral in this vault");
        require(debtToRepay > 0, "CollateralManager: debt to repay must be greater than 0");

        uint256 userDebtAmount = userDebt[user];
        uint256 actualDebtToRepay = debtToRepay > userDebtAmount ? userDebtAmount : debtToRepay;

        uint256 collateralValueToSeize = (actualDebtToRepay * (BONUS_PRECISION + liquidationBonus)) / BONUS_PRECISION;

        uint256 collateralSharesToSeize = vault.convertToShares(collateralValueToSeize);
        uint256 userCollateralShares = collateralShares[user][vault];
        if (collateralSharesToSeize > userCollateralShares) {
            collateralSharesToSeize = userCollateralShares;
            uint256 actualCollateralValue = vault.convertToAssets(collateralSharesToSeize);
            actualDebtToRepay = (actualCollateralValue * BONUS_PRECISION) / (BONUS_PRECISION + liquidationBonus);
        }

        require(actualDebtToRepay > 0, "CollateralManager: insufficient collateral for liquidation");

        IERC20(address(stablecoin)).safeTransferFrom(msg.sender, address(this), actualDebtToRepay);
        stablecoin.burn(address(this), actualDebtToRepay);

        userDebt[user] -= actualDebtToRepay;
        collateralShares[user][vault] -= collateralSharesToSeize;

        vault.safeTransfer(msg.sender, collateralSharesToSeize);

        uint256 actualCollateralValueSeized = vault.convertToAssets(collateralSharesToSeize);
        uint256 bonus =
            actualCollateralValueSeized > actualDebtToRepay ? actualCollateralValueSeized - actualDebtToRepay : 0;

        emit PositionLiquidated(user, msg.sender, vault, actualDebtToRepay, collateralSharesToSeize, bonus);
    }
}
