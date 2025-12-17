// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {
    ERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {
    ERC20PermitUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {
    ERC20VotesUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import {
    Initializable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {
    UUPSUpgradeable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {
    NoncesUpgradeable
} from "@openzeppelin/contracts-upgradeable/utils/NoncesUpgradeable.sol";

contract Stablecoin is
    Initializable,
    ERC20Upgradeable,
    ERC20PermitUpgradeable,
    ERC20VotesUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    address public minter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __ERC20_init("Stablecoin", "STABLE");
        __ERC20Permit_init("Stablecoin");
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == minter, "Stablecoin: only minter can mint");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(msg.sender == minter, "Stablecoin: only minter can burn");
        _burn(from, amount);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._update(from, to, value);
    }

    function nonces(
        address owner
    )
        public
        view
        override(ERC20PermitUpgradeable, NoncesUpgradeable)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}
