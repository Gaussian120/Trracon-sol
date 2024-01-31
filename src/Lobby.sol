// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "forge-std/console.sol";

/**
    * @author Iwaki Hiroto
    * @title Lobby system
    * @notice   Create a lobby system where a user can enroll in a game round.
                Limit the maximum number of players to 500 per lobby.
                Implement a deposit function to accept 0.05 testnet ETH.
                Ensure proper handling of overflows (more than 500 players) and underflows (lobby cancelation).
                Maintain a record of enrolled players and their deposits.
                Bonus: Add a feature for refunding deposits if a lobby is canceled or a player withdraws before the game starts.
                Ensure ETH is stored safely in vault
 */
contract Lobby is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    // Lobby details
    struct LobbyDetails {
        uint256 lobbyId;
        uint256 maxPlayers;
        uint256 depositAmount;
        address owner;
        EnumerableSet.AddressSet enrolledPlayers;
        bool isCanceled;
    }

    // Adjust MAX_PLAYERS according to needs
    uint256 PUBLIC_LOBBY_MAX_PLAYERS = 500;

    uint256 PUBLIC_DEPOSIT_AMOUNT = 0.05 ether;

    // Mapping of lobbyId to LobbyDetails
    mapping(uint256 => LobbyDetails) lobbies;

    // Users Deposited Amount
    mapping(uint256 => mapping(address => uint256)) userDepositedAmount;

    uint256 public lobbiesCount;

    // Event emitted when a new lobby is created
    event LobbyCreated(
        uint256 lobbyId,
        uint256 maxPlayers,
        uint256 depositAmount
    );

    // Event emitted when a player enrolls in a lobby
    event PlayerEnrolled(uint256 lobbyId, address playerAddress);

    // Event emitted when a lobby is canceled
    event LobbyCanceled(uint256 lobbyId);

    // Event emitted when a player withdraws their deposit
    event PlayerWithdrew(uint256 lobbyId, address playerAddress);

    // Event emitted when a player start the game in Lobby
    event PlayerStartGame(uint256 lobbyId, address playerAddress);

    // Error when registered user enroll to the lobby
    error AlreadyRegistered();

    // Error not registered user try to deposit
    error NotRegistered();

    constructor(address initialOwner) Ownable(initialOwner) {}

    // Create a new lobby
    function createLobby(
        uint256 _maxPlayers, // will be 500
        uint256 _depositAmount // will be 0.05 ETH
    ) external {
        require(
            _maxPlayers == PUBLIC_LOBBY_MAX_PLAYERS,
            "Maximum players is not invalid"
        );
        require(
            _depositAmount == PUBLIC_DEPOSIT_AMOUNT,
            "Deposit amount is not invalid"
        );
        require(lobbiesCount + 1 <= type(uint256).max, "Overflow lobbies");

        // EnumerableSet.AddressSet memory enrolledPlayers;

        uint256 lobbyId = lobbiesCount;
        // lobbies[lobbyId] = new LobbyDetails;
        lobbies[lobbyId].lobbyId = lobbyId;
        lobbies[lobbyId].maxPlayers = _maxPlayers;
        lobbies[lobbyId].depositAmount = _depositAmount;
        lobbies[lobbyId].isCanceled = false;
        lobbies[lobbyId].owner = msg.sender;

        lobbiesCount++;

        emit LobbyCreated(lobbyId, _maxPlayers, _depositAmount);
    }

    // Enroll in a lobby
    function enrollInLobby(uint256 _lobbyId) external {
        LobbyDetails storage lobby = lobbies[_lobbyId];
        require(!lobby.isCanceled, "Lobby is canceled");
        require(
            lobby.enrolledPlayers.length() < lobby.maxPlayers,
            "Lobby is full"
        );

        // if already registered user try to enroll, it should be reverted
        if (lobby.enrolledPlayers.contains(msg.sender)) {
            revert AlreadyRegistered();
        }

        lobby.enrolledPlayers.add(msg.sender);

        emit PlayerEnrolled(_lobbyId, msg.sender);
    }

    // deposit in lobby
    function deposit(uint256 _lobbyId) external payable {
        LobbyDetails storage lobby = lobbies[_lobbyId];
        require(!lobby.isCanceled, "Lobby is canceled");
        require(msg.value == lobby.depositAmount, "Incorrect deposit amount");

        // Only registered user can deposit
        if (!lobby.enrolledPlayers.contains(msg.sender)) {
            revert NotRegistered();
        }

        require(msg.value == lobby.depositAmount, "Incorrect deposit amount");

        userDepositedAmount[_lobbyId][msg.sender] += msg.value;
    }

    // Cancel a lobby
    function cancelLobby(uint256 _lobbyId) external {
        LobbyDetails storage lobby = lobbies[_lobbyId];
        require(
            msg.sender == lobby.owner,
            "Only the lobby creator can cancel the lobby"
        );

        lobby.isCanceled = true;

        emit LobbyCanceled(_lobbyId);
    }

    // Withdraw deposit
    function withdrawDeposit(uint256 _lobbyId) external {
        LobbyDetails storage lobby = lobbies[_lobbyId];

        // Only registered user can deposit
        if (!lobby.enrolledPlayers.contains(msg.sender)) {
            revert NotRegistered();
        }

        lobby.enrolledPlayers.remove(msg.sender);

        // Send deposit back to player
        payable(msg.sender).transfer(userDepositedAmount[_lobbyId][msg.sender]);

        emit PlayerWithdrew(_lobbyId, msg.sender);
    }

    // Withdraw deposit
    function startGame(uint256 _lobbyId) external {
        LobbyDetails storage lobby = lobbies[_lobbyId];
        require(!lobby.isCanceled, "Lobby is canceled");
        require(
            userDepositedAmount[_lobbyId][msg.sender] >= PUBLIC_DEPOSIT_AMOUNT,
            "Not enough money"
        );
        // Only registered user can start
        if (!lobby.enrolledPlayers.contains(msg.sender)) {
            revert NotRegistered();
        }

        emit PlayerStartGame(_lobbyId, msg.sender);
    }

    // get user deposited amounts in lobby
    function getUserDepositedInLobby(
        uint256 _lobbyId,
        address user
    ) external view returns (uint256) {
        return userDepositedAmount[_lobbyId][user];
    }

    // get user enrolled user count in lobby
    function getLobbyUserCount(
        uint256 _lobbyId
    ) external view returns (uint256) {
        LobbyDetails storage lobby = lobbies[_lobbyId];
        return lobby.enrolledPlayers.length();
    }

    // get user enrolled user count in lobby
    function getLobbyCanceled(uint256 _lobbyId) external view returns (bool) {
        LobbyDetails storage lobby = lobbies[_lobbyId];
        return lobby.isCanceled;
    }
}
