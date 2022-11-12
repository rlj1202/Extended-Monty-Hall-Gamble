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
    address participant;
    DoorType doorType;
  }

  struct Participant {
    GamePhase inPhase;
    bool chosenDoor;
    uint doorIdx;
  }

  // TODO:
  event Test();

  address public gameHost;

  Door[] doors;
  address[] participants;
  mapping (address => Participant) addressToParticipants;

  GamePhase phase;

  uint participatingPhase;
  uint switchingPhase;

  constructor(uint size) payable {
    initGame(size);
    startGame();

    gameHost = msg.sender;
  }

  /// Initialize the game.
  /// @param size The number of doors
  function initGame(uint size) private {
    require(
      size >= 3,
      "The number of doors must be greater than or equal to 3."
    );

    // Delete all data in previous game.
    for (uint i = 0; i < participants.length; i++) {
      delete addressToParticipants[participants[i]];
    }
    delete participants;
    delete doors;

    // Reset all phase values.
    phase = GamePhase.INIT;

    participatingPhase = 0;
    switchingPhase = 0;

    // Recreate doors
    doors = new Door[](size);
  }

  function startGame() private {
    phase = GamePhase.PARTICIPATING;

    placeSportsCars();
  }

  function finalizeGame() private {
    require(phase == GamePhase.END);

    for (uint i = 0; i < doors.length; i++) {
      if (doors[i].doorType == DoorType.SPORTS_CAR && doors[i].participant != address(0x0)) {
        // TODO:

        uint test = address(this).balance;
      }
    }

    initGame(doors.length);
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
      // TODO:
      msg.value > 1 wei,
      "The participant must pay fee."
    );

    participants.push(msg.sender);

    chooseDoor(doorIdx);

    addressToParticipants[msg.sender].inPhase = GamePhase.PARTICIPATING;
    participatingPhase++;
    if (participatingPhase == doors.length / 3) {
      phase = GamePhase.SWITCHING;
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
      doors[prevDoorIdx].participant = address(0x0);
    }

    doors[doorIdx].participant = msg.sender;
    addressToParticipants[msg.sender].doorIdx = doorIdx;
    addressToParticipants[msg.sender].chosenDoor = true;
  }
}
