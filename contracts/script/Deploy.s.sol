// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {HelloWorld} from "../src/HelloWorld.sol";
import {Stablecoin} from "../src/Stablecoin.sol";
import {CollateralManager} from "../src/CollateralManager.sol";
import {Governor} from "../src/Governor.sol";

contract DeployScript is Script {
    address public deployer;
    HelloWorld public helloWorld;
    Stablecoin public stablecoin;
    CollateralManager public collateralManager;
    Governor public governor;

    function setUp() public {
        deployer = msg.sender;
    }

    function run() public {
        vm.startBroadcast();

        console.log("Deployer address:", deployer);
        console.log("Deploying contracts...");

        HelloWorld helloWorldImpl = new HelloWorld();
        console.log("HelloWorld implementation deployed at:", address(helloWorldImpl));

        bytes memory helloWorldInitData = abi.encodeCall(HelloWorld.initialize, (deployer));
        ERC1967Proxy helloWorldProxy = new ERC1967Proxy(address(helloWorldImpl), helloWorldInitData);
        helloWorld = HelloWorld(payable(address(helloWorldProxy)));
        console.log("HelloWorld proxy deployed at:", address(helloWorld));

        Stablecoin stablecoinImpl = new Stablecoin();
        console.log("Stablecoin implementation deployed at:", address(stablecoinImpl));

        bytes memory stablecoinInitData = abi.encodeCall(Stablecoin.initialize, (deployer));
        ERC1967Proxy stablecoinProxy = new ERC1967Proxy(address(stablecoinImpl), stablecoinInitData);
        stablecoin = Stablecoin(address(stablecoinProxy));
        console.log("Stablecoin proxy deployed at:", address(stablecoin));

        CollateralManager collateralManagerImpl = new CollateralManager();
        console.log("CollateralManager implementation deployed at:", address(collateralManagerImpl));

        bytes memory collateralManagerInitData =
            abi.encodeCall(CollateralManager.initialize, (address(stablecoin), deployer));
        ERC1967Proxy collateralManagerProxy =
            new ERC1967Proxy(address(collateralManagerImpl), collateralManagerInitData);
        collateralManager = CollateralManager(address(collateralManagerProxy));
        console.log("CollateralManager proxy deployed at:", address(collateralManager));

        stablecoin.setMinter(address(collateralManager));
        console.log("Stablecoin minter set to CollateralManager");

        Governor governorImpl = new Governor();
        console.log("Governor implementation deployed at:", address(governorImpl));

        bytes memory governorInitData = abi.encodeCall(
            Governor.initialize, (stablecoin, deployer, uint48(1 days), uint32(7 days), uint256(1000e18), uint256(4))
        );
        ERC1967Proxy governorProxy = new ERC1967Proxy(address(governorImpl), governorInitData);
        governor = Governor(payable(address(governorProxy)));
        console.log("Governor proxy deployed at:", address(governor));

        collateralManager.transferOwnership(address(governor));
        console.log("CollateralManager ownership transferred to Governor");

        stablecoin.transferOwnership(address(governor));
        console.log("Stablecoin ownership transferred to Governor");

        console.log("\n=== Deployment Summary ===");
        console.log("HelloWorld (proxy):", address(helloWorld));
        console.log("Stablecoin (proxy):", address(stablecoin));
        console.log("CollateralManager (proxy):", address(collateralManager));
        console.log("Governor (proxy):", address(governor));
        console.log("Initial Owner:", deployer);
        console.log("\nGovernance Parameters:");
        console.log("  Voting Delay: 1 day");
        console.log("  Voting Period: 7 days");
        console.log("  Proposal Threshold: 1000 STABLE");
        console.log("  Quorum: 4%");

        vm.stopBroadcast();
    }
}
