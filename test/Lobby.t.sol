// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Lobby} from "../src/Lobby.sol";

contract LobbyTest is Test {
    Lobby lobby;

    function setUp() public {
        lobby = new Lobby(address(this));
    }

    function testCreateLobby() public {
        lobby.createLobby(500, 0.05 ether);
        assertEq(lobby.lobbiesCount(), 1);
    }

    function testEnrollInLobby() public {
        lobby.createLobby(500, 0.05 ether);
        lobby.enrollInLobby(0);

        vm.expectRevert();
        lobby.enrollInLobby(0);

        assertEq(lobby.getLobbyUserCount(0), 1);
    }

    function testCancelLobby() public {
        lobby.createLobby(500, 0.05 ether);
        lobby.enrollInLobby(0);
        lobby.cancelLobby(0);
        assertTrue(lobby.getLobbyCanceled(0));
    }

    function testWithdrawDeposit() public {
        lobby.createLobby(500, 0.05 ether);
        lobby.enrollInLobby(0);
        lobby.withdrawDeposit(0);
        assertEq(lobby.getLobbyUserCount(0), 0);
    }

    function testDeposit() public {
        lobby.createLobby(500, 0.05 ether);
        lobby.enrollInLobby(0);
        lobby.deposit{value: 0.05 ether}(0);
        assertEq(lobby.getUserDepositedInLobby(0, address(this)), 0.05 ether);
    }

    function testStartGame() public {
        lobby.createLobby(500, 0.05 ether);
        lobby.enrollInLobby(0);
        lobby.deposit{value: 0.05 ether}(0);
        lobby.startGame(0);
        assertFalse(lobby.getLobbyCanceled(0));
    }

    receive() external payable {}
}
