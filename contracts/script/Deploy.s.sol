// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Stablecoin} from "../src/Stablecoin.sol";
import {CollateralManager} from "../src/CollateralManager.sol";
import {Governor} from "../src/Governor.sol";
import {Treasury} from "../src/Treasury.sol";

contract DeployScript is Script {
    address public deployer;
    Stablecoin public stablecoin;
    CollateralManager public collateralManager;
    Governor public governor;
    Treasury public treasury;

    function setUp() public {
        deployer = msg.sender;
    }

    function run() public {
        vm.startBroadcast();

        console.log("Deployer address:", deployer);
        console.log("Deploying contracts...");

        Stablecoin stablecoinImpl = new Stablecoin();
        console.log("Stablecoin implementation deployed at:", address(stablecoinImpl));

        bytes memory stablecoinInitData = abi.encodeCall(Stablecoin.initialize, (deployer));
        ERC1967Proxy stablecoinProxy = new ERC1967Proxy(address(stablecoinImpl), stablecoinInitData);
        stablecoin = Stablecoin(address(stablecoinProxy));
        console.log("Stablecoin proxy deployed at:", address(stablecoin));
        console.log("Note: stablecoin variable now points to PROXY address");

        Treasury treasuryImpl = new Treasury();
        console.log("Treasury implementation deployed at:", address(treasuryImpl));

        bytes memory treasuryInitData = abi.encodeCall(Treasury.initialize, (deployer));
        ERC1967Proxy treasuryProxy = new ERC1967Proxy(address(treasuryImpl), treasuryInitData);
        treasury = Treasury(address(treasuryProxy));
        console.log("Treasury proxy deployed at:", address(treasury));

        CollateralManager collateralManagerImpl = new CollateralManager();
        console.log("CollateralManager implementation deployed at:", address(collateralManagerImpl));

        bytes memory collateralManagerInitData =
            abi.encodeCall(CollateralManager.initialize, (address(stablecoin), address(treasury), deployer));
        console.log("Initializing CollateralManager with Stablecoin PROXY address:", address(stablecoin));
        console.log("Initializing CollateralManager with Treasury PROXY address:", address(treasury));
        ERC1967Proxy collateralManagerProxy =
            new ERC1967Proxy(address(collateralManagerImpl), collateralManagerInitData);
        collateralManager = CollateralManager(address(collateralManagerProxy));
        console.log("CollateralManager proxy deployed at:", address(collateralManager));
        console.log("Note: collateralManager variable now points to PROXY address");

        console.log("Setting Stablecoin minter to CollateralManager PROXY:", address(collateralManager));
        stablecoin.setMinter(address(collateralManager));
        console.log("Stablecoin minter set to CollateralManager");

        Governor governorImpl = new Governor();
        console.log("Governor implementation deployed at:", address(governorImpl));

        bytes memory governorInitData = abi.encodeCall(
            Governor.initialize, (stablecoin, deployer, uint48(1 days), uint32(7 days), uint256(1000e18), uint256(4))
        );
        console.log("Initializing Governor with Stablecoin PROXY address:", address(stablecoin));
        ERC1967Proxy governorProxy = new ERC1967Proxy(address(governorImpl), governorInitData);
        governor = Governor(payable(address(governorProxy)));
        console.log("Governor proxy deployed at:", address(governor));
        console.log("Note: governor variable now points to PROXY address");

        console.log("Transferring CollateralManager ownership to Governor PROXY:", address(governor));
        collateralManager.transferOwnership(address(governor));
        console.log("CollateralManager ownership transferred to Governor");

        console.log("Transferring Stablecoin ownership to Governor PROXY:", address(governor));
        stablecoin.transferOwnership(address(governor));
        console.log("Stablecoin ownership transferred to Governor");

        console.log("Transferring Treasury ownership to Governor PROXY:", address(governor));
        treasury.transferOwnership(address(governor));
        console.log("Treasury ownership transferred to Governor");

        console.log("\n=== Deployment Summary ===");
        console.log("Stablecoin (proxy):", address(stablecoin));
        console.log("Treasury (proxy):", address(treasury));
        console.log("CollateralManager (proxy):", address(collateralManager));
        console.log("Governor (proxy):", address(governor));
        console.log("Initial Owner:", deployer);
        console.log("\nGovernance Parameters:");
        console.log("  Voting Delay: 1 day");
        console.log("  Voting Period: 7 days");
        console.log("  Proposal Threshold: 1000 STABLE");
        console.log("  Quorum: 4%");
        console.log("\nProtocol Parameters:");
        console.log("  Collateralization Ratio: 150%");
        console.log("  Liquidation Bonus: 5%");
        console.log("  Minting Fee: 0.5%");

        vm.stopBroadcast();
    }
}
