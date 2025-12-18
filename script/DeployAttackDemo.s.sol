// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {MockERC20} from "../test/InflationAttack.t.sol";
import {VulnerableVault} from "../src/VulnerableVault.sol";
import {Attacker} from "../src/Attacker.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployAttackDemoScript is Script {
    function run() public {
        vm.startBroadcast();

        console.log("Deploying ERC-4626 Inflation Attack Demo...");

        MockERC20 asset = new MockERC20();
        console.log("MockERC20 deployed at:", address(asset));

        VulnerableVault vault = new VulnerableVault(IERC20(address(asset)));
        console.log("VulnerableVault deployed at:", address(vault));

        Attacker attacker = new Attacker(vault);
        console.log("Attacker deployed at:", address(attacker));

        asset.mint(msg.sender, 1000000 * 1e6);
        console.log("Minted 1,000,000 USDT to deployer");

        console.log("\n=== Deployment Summary ===");
        console.log("Asset (MockERC20):", address(asset));
        console.log("Vault (VulnerableVault):", address(vault));
        console.log("Attacker:", address(attacker));
        console.log("\nSet these in your .env.local:");
        console.log("NEXT_PUBLIC_ASSET_ADDRESS=", address(asset));
        console.log("NEXT_PUBLIC_VAULT_ADDRESS=", address(vault));
        console.log("NEXT_PUBLIC_ATTACKER_ADDRESS=", address(attacker));

        vm.stopBroadcast();
    }
}
