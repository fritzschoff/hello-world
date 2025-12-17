// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {CollateralManager} from "../src/CollateralManager.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

contract AddVaultScript is Script {
    function run() public {
        address collateralManagerAddress = vm.envAddress(
            "COLLATERAL_MANAGER_ADDRESS"
        );
        address vaultAddress = vm.envAddress("VAULT_ADDRESS");

        CollateralManager collateralManager = CollateralManager(
            collateralManagerAddress
        );
        IERC4626 vault = IERC4626(vaultAddress);

        vm.startBroadcast();

        console.log("Adding vault to CollateralManager...");
        console.log("CollateralManager:", address(collateralManager));
        console.log("Vault:", address(vault));

        collateralManager.addSupportedVault(vault);

        console.log("Vault added successfully!");

        vm.stopBroadcast();
    }
}
