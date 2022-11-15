// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract ExtendedMontyHallGamble {
  enum DoorType {
    GOAT,
    SPORTS_CAR
  }

  enum GamePhase {
    INIT,
    PARTICIPATING,
    SWITCHING,
    END
  }

  struct Door {
    address payable participant;
    DoorType doorType;
  }

  struct Participant {
    GamePhase inPhase;
    bool chosenDoor;
    uint doorIdx;
  }

  event GameStarted();
  event ParticipatingCompleted();
  event SwitchingCompleted();
  event DoorChoosing(address who, uint doorIdx);
  event GameWinner(uint round, address winner, uint reward);

  address public gameHost;
  uint public participatingFee;

  Door[] doors;
  address payable[] participants;
  mapping (address => Participant) addressToParticipants;

  uint round;
  GamePhase phase;

  uint participatingPhase;
  uint switchingPhase;

  /// @param size The number of doors.
  /// @param _participatingFee The fee needed to participate in the game.
  constructor(uint size, uint _participatingFee) payable {
    require(
      size >= 3,
      "The number of doors must be greater than or equal to 3."
    );

    for (uint i = 0; i < size; i++) {
      doors.push(Door(payable(address(0x0)), DoorType.GOAT));
    }

    initGame();
    startGame();

    gameHost = msg.sender;
    participatingFee = _participatingFee;
  }

  /// Initialize the game.
  function initGame() private {
    // Delete all data in previous game.
    for (uint i = 0; i < participants.length; i++) {
      delete addressToParticipants[participants[i]];
    }
    delete participants;

    for (uint i = 0; i < doors.length; i++) {
      delete doors[i];
    }

    // Reset all phase values.
    phase = GamePhase.INIT;

    participatingPhase = 0;
    switchingPhase = 0;
  }

  function startGame() private {
    phase = GamePhase.PARTICIPATING;

    placeSportsCars();

    emit GameStarted();
  }

  function finalizeGame() private {
    require(phase == GamePhase.END, "The game is not on end phase.");

    uint winners = 0;

    for (uint i = 0; i < doors.length; i++) {
      if (doors[i].doorType != DoorType.SPORTS_CAR) continue;
      if (doors[i].participant == address(0x0)) continue;

      winners++;
    }

    if (winners > 0) {
      uint reward = address(this).balance / winners;

      for (uint i = 0; i < doors.length; i++) {
        if (doors[i].doorType != DoorType.SPORTS_CAR) continue;
        if (doors[i].participant == address(0x0)) continue;

        (bool sent, /* bytes memory data */) = doors[i].participant.call{ value: reward }("");
        require(sent, "Failed to send ether to winner.");

        emit GameWinner(round, doors[i].participant, reward);
      }
    }

    round++;

    initGame();
    startGame();
  }

  function placeSportsCars() private {
    uint[] memory permutation = new uint[](doors.length);

    for (uint i = 0; i < permutation.length; i++) {
      permutation[i] = i;
    }

    for (uint i = 0; i < permutation.length * 2; i++) {
      uint a = uint256(keccak256(abi.encodePacked(block.timestamp, gameHost, i * 2))) % permutation.length;
      uint b = uint256(keccak256(abi.encodePacked(block.timestamp, gameHost, i * 2 + 1))) % permutation.length;

      uint temp = permutation[a];
      permutation[a] = permutation[b];
      permutation[b] = temp;
    }

    for (uint i = 0; i < doors.length / 3; i++) {
      doors[permutation[i]].doorType = DoorType.SPORTS_CAR;
    }
  }

  /// Returns the number of doors of the game.
  function getSize() external view returns (uint) {
    return doors.length;
  }

  /// Returns the balance of the smart contract.
  function getBalance() external view returns (uint) {
    return address(this).balance;
  }

  /// Returns the participating fee of the game.
  function getParticipatingFee() external view returns (uint) {
    return participatingFee;
  }

  /// Returns the phase of the game.
  function getPhase() external view returns (GamePhase) {
    return phase;
  }

  // Returns occupation information of doors.
  function getDoors() external view returns (address[] memory) {
    address[] memory occupations = new address[](doors.length);

    for (uint i = 0; i < doors.length; i++) {
      occupations[i] = doors[i].participant;
    }

    return occupations;
  }

  /// Get participated in the game.
  /// @param doorIdx The index number of the door the participant chosen.
  function participate(uint doorIdx) external payable {
    require(
      phase == GamePhase.PARTICIPATING,
      "The game is not on participating phase."
    );

    require(
      gameHost != msg.sender,
      "The game host cannot participate in the game."
    );

    require(
      addressToParticipants[msg.sender].inPhase == GamePhase.INIT,
      "The participant has already participated in the game."
    );

    require(
      msg.value >= participatingFee,
      "The participant must pay fee."
    );

    participants.push(payable(msg.sender));

    chooseDoor(doorIdx);

    addressToParticipants[msg.sender].inPhase = GamePhase.PARTICIPATING;
    participatingPhase++;
    if (participatingPhase == doors.length / 3) {
      phase = GamePhase.SWITCHING;

      emit ParticipatingCompleted();
    }
  }

  /// Switch door if participant wants.
  /// Otherwise, choose same door index.
  function switchDoor(uint doorIdx) external {
    require(
      phase == GamePhase.SWITCHING,
      "The game is not on the switching phase."
    );

    require(
      addressToParticipants[msg.sender].inPhase == GamePhase.PARTICIPATING,
      "The participant must be in the participing phase."
    );

    chooseDoor(doorIdx);

    addressToParticipants[msg.sender].inPhase = GamePhase.SWITCHING;
    switchingPhase++;
    if (switchingPhase == doors.length / 3) {
      phase = GamePhase.END;
      finalizeGame();

      emit SwitchingCompleted();
    }
  }

  function chooseDoor(uint doorIdx) private {
    require(
      doors[doorIdx].participant == address(0x0) || doors[doorIdx].participant == msg.sender,
      "The door the participant chosen must be equal as previous or be empty."
    );

    require(
      0 <= doorIdx && doorIdx < doors.length,
      "The door index must be in range [0, # of doors)."
    );

    if (addressToParticipants[msg.sender].chosenDoor == true) {
      uint prevDoorIdx = addressToParticipants[msg.sender].doorIdx;
      doors[prevDoorIdx].participant = payable(address(0x0));
    }

    doors[doorIdx].participant = payable(msg.sender);
    addressToParticipants[msg.sender].doorIdx = doorIdx;
    addressToParticipants[msg.sender].chosenDoor = true;

    emit DoorChoosing(msg.sender, doorIdx);
  }
}
