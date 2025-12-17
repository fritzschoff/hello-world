// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {
    ERC1967Proxy
} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Stablecoin} from "../src/Stablecoin.sol";
import {CollateralManager} from "../src/CollateralManager.sol";
import {Governor} from "../src/Governor.sol";

contract GovernorTest is Test {
    Stablecoin public stablecoin;
    CollateralManager public collateralManager;
    Governor public governor;

    address public owner = address(1);
    address public voter1 = address(2);
    address public voter2 = address(3);

    uint256 public constant VOTING_DELAY = 1 days;
    uint256 public constant VOTING_PERIOD = 7 days;
    uint256 public constant PROPOSAL_THRESHOLD = 1000e18;
    uint256 public constant QUORUM_NUMERATOR = 4;

    function setUp() public {
        vm.startPrank(owner);

        Stablecoin stablecoinImpl = new Stablecoin();
        bytes memory stablecoinInitData = abi.encodeCall(
            Stablecoin.initialize,
            (owner)
        );
        ERC1967Proxy stablecoinProxy = new ERC1967Proxy(
            address(stablecoinImpl),
            stablecoinInitData
        );
        stablecoin = Stablecoin(address(stablecoinProxy));

        CollateralManager managerImpl = new CollateralManager();
        bytes memory managerInitData = abi.encodeCall(
            CollateralManager.initialize,
            (address(stablecoin), owner)
        );
        ERC1967Proxy managerProxy = new ERC1967Proxy(
            address(managerImpl),
            managerInitData
        );
        collateralManager = CollateralManager(address(managerProxy));

        stablecoin.setMinter(address(collateralManager));

        Governor governorImpl = new Governor();
        bytes memory governorInitData = abi.encodeCall(
            Governor.initialize,
            (
                stablecoin,
                owner,
                uint48(VOTING_DELAY),
                uint32(VOTING_PERIOD),
                PROPOSAL_THRESHOLD,
                QUORUM_NUMERATOR
            )
        );
        ERC1967Proxy governorProxy = new ERC1967Proxy(
            address(governorImpl),
            governorInitData
        );
        governor = Governor(payable(address(governorProxy)));

        vm.stopPrank();
        
        vm.startPrank(address(collateralManager));
        stablecoin.mint(voter1, 10000e18);
        stablecoin.mint(voter2, 5000e18);
        vm.stopPrank();
        
        vm.roll(block.number + 1);
        
        vm.prank(voter1);
        stablecoin.delegate(voter1);
        
        vm.prank(voter2);
        stablecoin.delegate(voter2);
        
        vm.roll(block.number + 1);
    }

    function test_Propose(uint256 newRatio) public {
        vm.assume(newRatio >= 10000 && newRatio <= 30000);
        
        vm.startPrank(voter1);

        address[] memory targets = new address[](1);
        targets[0] = address(collateralManager);

        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(
            CollateralManager.setCollateralizationRatio.selector,
            newRatio
        );

        uint256 proposalId = governor.propose(
            targets,
            values,
            calldatas,
            "Set new collateralization ratio"
        );
        vm.stopPrank();

        assertGt(proposalId, 0);
        assertEq(uint256(governor.state(proposalId)), 0);
    }

    function test_Vote(uint256 newRatio) public {
        vm.assume(newRatio >= 10000 && newRatio <= 30000);

        vm.roll(block.number + 1);

        vm.startPrank(voter1);

        address[] memory targets = new address[](1);
        targets[0] = address(collateralManager);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(
            CollateralManager.setCollateralizationRatio.selector,
            newRatio
        );

        uint256 proposalId = governor.propose(
            targets,
            values,
            calldatas,
            "Proposal"
        );
        vm.stopPrank();

        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + 1);

        vm.prank(voter1);
        governor.castVote(proposalId, 1);

        vm.prank(voter2);
        governor.castVote(proposalId, 1);

        (
            uint256 againstVotes,
            uint256 forVotes,
            uint256 abstainVotes
        ) = governor.proposalVotes(proposalId);
        assertEq(forVotes, 15000e18);
    }

    function test_ExecuteProposal(uint256 newRatio) public {
        vm.assume(newRatio >= 10000 && newRatio <= 30000);

        vm.roll(block.number + 1);

        vm.startPrank(voter1);

        address[] memory targets = new address[](1);
        targets[0] = address(collateralManager);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(
            CollateralManager.setCollateralizationRatio.selector,
            newRatio
        );

        uint256 proposalId = governor.propose(
            targets,
            values,
            calldatas,
            "Proposal"
        );
        vm.stopPrank();

        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + 1);

        vm.prank(voter1);
        governor.castVote(proposalId, 1);

        vm.prank(voter2);
        governor.castVote(proposalId, 1);

        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + 1);

        require(
            uint256(governor.state(proposalId)) == 4,
            "Proposal must be in Succeeded state"
        );

        uint256 oldRatio = collateralManager.collateralizationRatio();

        governor.execute(
            targets,
            values,
            calldatas,
            keccak256(bytes("Proposal"))
        );

        assertEq(collateralManager.collateralizationRatio(), newRatio);
    }

    function test_RevertPropose_BelowThreshold() public {
        address smallHolder = address(4);
        vm.prank(address(collateralManager));
        stablecoin.mint(smallHolder, 500e18);
        
        vm.startPrank(smallHolder);
        stablecoin.delegate(smallHolder);

        address[] memory targets = new address[](1);
        targets[0] = address(collateralManager);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(
            CollateralManager.setCollateralizationRatio.selector,
            20000
        );

        vm.expectRevert();
        governor.propose(targets, values, calldatas, "Proposal");
        vm.stopPrank();
    }

    function test_Quorum(uint256 voter1Amount, uint256 voter2Amount) public {
        vm.assume(voter1Amount >= PROPOSAL_THRESHOLD);
        vm.assume(voter2Amount > 0);
        vm.assume(voter1Amount <= 100000e18);
        vm.assume(voter2Amount <= 100000e18);
        
        address voter3 = address(4);
        vm.startPrank(address(collateralManager));
        stablecoin.mint(voter1, voter1Amount);
        stablecoin.mint(voter2, voter2Amount);
        stablecoin.mint(voter3, 1000e18);
        vm.stopPrank();
        
        vm.roll(block.number + 1);
        
        vm.prank(voter1);
        stablecoin.delegate(voter1);
        
        vm.prank(voter2);
        stablecoin.delegate(voter2);
        
        vm.roll(block.number + 1);
        
        vm.startPrank(voter1);

        address[] memory targets = new address[](1);
        targets[0] = address(collateralManager);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(
            CollateralManager.setCollateralizationRatio.selector,
            20000
        );

        uint256 proposalId = governor.propose(
            targets,
            values,
            calldatas,
            "Proposal"
        );
        vm.stopPrank();

        vm.warp(block.timestamp + VOTING_DELAY + 1);

        vm.prank(voter1);
        governor.castVote(proposalId, 1);

        vm.prank(voter2);
        governor.castVote(proposalId, 1);

        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + 1);

        uint256 totalSupply = stablecoin.totalSupply();
        uint256 quorum = (totalSupply * QUORUM_NUMERATOR) / 100;
        uint256 votes = voter1Amount + voter2Amount;
        uint256 proposalState = uint256(governor.state(proposalId));

        if (votes >= quorum && proposalState == 4) {
            governor.execute(
                targets,
                values,
                calldatas,
                keccak256(bytes("Proposal"))
            );
        } else {
            vm.expectRevert();
            governor.execute(
                targets,
                values,
                calldatas,
                keccak256(bytes("Proposal"))
            );
        }
    }
}
