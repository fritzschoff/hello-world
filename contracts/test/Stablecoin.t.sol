// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {
    ERC1967Proxy
} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Stablecoin} from "../src/Stablecoin.sol";
import {
    IERC20Permit
} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

contract StablecoinTest is Test {
    Stablecoin public stablecoin;
    address public owner = address(1);
    address public minter = address(2);
    address public user = address(3);

    function setUp() public {
        vm.startPrank(owner);
        Stablecoin impl = new Stablecoin();
        bytes memory initData = abi.encodeCall(Stablecoin.initialize, (owner));
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        stablecoin = Stablecoin(address(proxy));
        stablecoin.setMinter(minter);
        vm.stopPrank();
    }

    function test_Initialize() public {
        assertEq(stablecoin.name(), "Stablecoin");
        assertEq(stablecoin.symbol(), "STABLE");
        assertEq(stablecoin.decimals(), 18);
        assertEq(stablecoin.owner(), owner);
    }

    function test_Mint(uint256 amount) public {
        vm.assume(amount > 0 && amount < type(uint128).max);
        vm.prank(minter);
        stablecoin.mint(user, amount);
        assertEq(stablecoin.balanceOf(user), amount);
        assertEq(stablecoin.totalSupply(), amount);
    }

    function test_MintFuzz(address to, uint256 amount) public {
        vm.assume(to != address(0) && to != address(stablecoin));
        vm.assume(amount > 0 && amount < type(uint128).max);
        vm.prank(minter);
        stablecoin.mint(to, amount);
        assertEq(stablecoin.balanceOf(to), amount);
    }

    function test_Burn(uint256 mintAmount, uint256 burnAmount) public {
        vm.assume(mintAmount > 0 && mintAmount < type(uint128).max);
        vm.assume(burnAmount > 0 && burnAmount <= mintAmount);

        vm.prank(minter);
        stablecoin.mint(user, mintAmount);

        vm.prank(minter);
        stablecoin.burn(user, burnAmount);

        assertEq(stablecoin.balanceOf(user), mintAmount - burnAmount);
        assertEq(stablecoin.totalSupply(), mintAmount - burnAmount);
    }

    function test_RevertMint_NotMinter() public {
        vm.expectRevert("Stablecoin: only minter can mint");
        stablecoin.mint(user, 1000);
    }

    function test_RevertBurn_NotMinter() public {
        vm.prank(minter);
        stablecoin.mint(user, 1000);

        vm.expectRevert("Stablecoin: only minter can burn");
        stablecoin.burn(user, 500);
    }

    function test_Permit(
        uint256 privateKey,
        uint256 amount,
        uint256 deadline
    ) public {
        vm.assume(privateKey > 0 && privateKey < type(uint256).max / 2);
        vm.assume(amount > 0 && amount < type(uint128).max);
        vm.assume(deadline > block.timestamp);

        address signer = vm.addr(privateKey);
        vm.prank(minter);
        stablecoin.mint(signer, amount);

        bytes32 domainSeparator = stablecoin.DOMAIN_SEPARATOR();
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                ),
                signer,
                address(this),
                amount,
                stablecoin.nonces(signer),
                deadline
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        stablecoin.permit(signer, address(this), amount, deadline, v, r, s);

        assertEq(stablecoin.allowance(signer, address(this)), amount);
    }

    function test_VotingPower(uint256 amount) public {
        vm.assume(amount > 0 && amount < type(uint128).max);
        
        vm.roll(block.number + 1);
        
        vm.prank(minter);
        stablecoin.mint(user, amount);
        
        vm.prank(user);
        stablecoin.delegate(user);
        
        vm.roll(block.number + 1);
        
        assertEq(stablecoin.getVotes(user), amount);
        assertEq(stablecoin.getPastVotes(user, block.number - 1), amount);
    }

    function test_Transfer_UpdatesVotingPower(
        uint256 amount1,
        uint256 amount2
    ) public {
        vm.assume(amount1 > 0 && amount1 < type(uint128).max);
        vm.assume(amount2 > 0 && amount2 < type(uint128).max);

        address recipient = address(4);

        vm.roll(block.number + 1);

        vm.prank(minter);
        stablecoin.mint(user, amount1);

        vm.prank(minter);
        stablecoin.mint(user, amount2);

        vm.prank(user);
        stablecoin.delegate(user);

        vm.roll(block.number + 1);

        vm.prank(user);
        stablecoin.transfer(recipient, amount1);

        vm.prank(recipient);
        stablecoin.delegate(recipient);

        vm.roll(block.number + 1);

        assertEq(stablecoin.getVotes(user), amount2);
        assertEq(stablecoin.getVotes(recipient), amount1);
    }
}
