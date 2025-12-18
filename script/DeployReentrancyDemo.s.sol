// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {VulnerableDAO} from "../src/VulnerableDAO.sol";
import {ReentrancyAttacker} from "../src/ReentrancyAttacker.sol";
import {SecureDAO} from "../src/SecureDAO.sol";

contract DeployReentrancyDemoScript is Script {
    function run() public {
        vm.startBroadcast();

        console.log("Deploying Reentrancy Attack Demo (The DAO Hack)...");

        VulnerableDAO vulnerableDAO = new VulnerableDAO();
        console.log("VulnerableDAO deployed at:", address(vulnerableDAO));

        SecureDAO secureDAO = new SecureDAO();
        console.log("SecureDAO deployed at:", address(secureDAO));

        ReentrancyAttacker attacker = new ReentrancyAttacker(address(vulnerableDAO));
        console.log("ReentrancyAttacker deployed at:", address(attacker));

        console.log("\n=== Deployment Summary ===");
        console.log("VulnerableDAO:", address(vulnerableDAO));
        console.log("SecureDAO:", address(secureDAO));
        console.log("ReentrancyAttacker:", address(attacker));
        console.log("\nSet these in your .env.local:");
        console.log("NEXT_PUBLIC_VULNERABLE_DAO_ADDRESS=", address(vulnerableDAO));
        console.log("NEXT_PUBLIC_SECURE_DAO_ADDRESS=", address(secureDAO));
        console.log("NEXT_PUBLIC_ATTACKER_ADDRESS=", address(attacker));

        vm.stopBroadcast();
    }
}

