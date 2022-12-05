// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract ExtendedMontyHallGamble {
  enum DoorType {
    GOAT,
    SPORTS_CAR,
    UNKNOWN
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
    bool open;
  }

  struct Participant {
    GamePhase inPhase;
    bool chosenDoor;
    uint doorIdx;
  }

  event GameStarted(uint round);
  event ParticipatingCompleted(uint round);
  event SwitchingCompleted(uint round);
  event DoorChosen(address participant, uint doorIdx);
  event GameWinner(uint round, address winner, uint reward);
  event GameEnded(Door[] doors);

  address gameHost;
  uint participatingFee;

  Door[] doors;
  address payable[] participants;
  mapping (address => Participant) addressToParticipants;

  uint round;
  GamePhase phase;

  uint participantNum;
  uint switchedNum;

  /// @param size The number of doors.
  /// @param _participatingFee The fee is needed to participate in the game.
  constructor(uint size, uint _participatingFee) payable {
    require(
      size >= 3,
      "The number of doors must be greater than or equal to 3."
    );

    for (uint i = 0; i < size; i++) {
      doors.push(Door(payable(address(0x0)), DoorType.GOAT, false));
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

    participantNum = 0;
    switchedNum = 0;
  }

  function startGame() private {
    phase = GamePhase.PARTICIPATING;

    placeSportsCars();

    emit GameStarted(round);
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

    emit GameEnded(doors);

    round++;

    initGame();
    startGame();
  }

  function genPermutation(uint len) private view returns (uint[] memory) {
    uint[] memory permutation = new uint[](len);

    for (uint i = 0; i < permutation.length; i++) {
      permutation[i] = i;
    }

    for (uint256 i = 0; i < len - 1; i++) {
        uint256 a = uint256(keccak256(abi.encodePacked(block.timestamp, gameHost, i))) % (len - i);

        uint256 temp = permutation[a];
        permutation[a] = permutation[len - i - 1];
        permutation[len - i - 1] = temp;
    }

    return permutation;
  }

  function placeSportsCars() private {
    uint[] memory permutation = genPermutation(doors.length);

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

  /// Returns the number of rounds of the game.
  function getRound() external view returns (uint) {
    return round;
  }

  /// Returns information of doors.
  function getDoors() external view returns (Door[] memory) {
    Door[] memory results = new Door[](doors.length);

    for (uint i = 0; i < doors.length; i++) {
      results[i].participant = doors[i].participant;
      results[i].open = doors[i].open;

      if (phase == GamePhase.END || doors[i].open) {
        results[i].doorType = doors[i].doorType;
      } else {
        results[i].doorType = DoorType.UNKNOWN;
      }
    }

    return results;
  }

  /// Returns occupation information of doors.
  // function getDoors() external view returns (address[] memory) {
  //   address[] memory occupations = new address[](doors.length);

  //   for (uint i = 0; i < doors.length; i++) {
  //     occupations[i] = doors[i].participant;
  //   }

  //   return occupations;
  // }

  /// Returns goats locations
  // function getGoats() external view returns (bool[] memory) {
  //   bool[] memory goats = new bool[](doors.length);

  //   for (uint i = 0; i < doors.length; i++) {
  //     goats[i] = doors[i].open;
  //   }

  //   return goats;
  // }

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
    participantNum++;
    if (participantNum == doors.length / 3) {
      phase = GamePhase.SWITCHING;
      
      startSwitching();

      emit ParticipatingCompleted(round);
    }
  }

  function startSwitching() private {
    require(phase == GamePhase.SWITCHING, "The game is not on switching phase.");

    // Decide goat locations to open to public
    uint[] memory freeGoats = new uint[](doors.length);
    uint goats_len = 0;

    for (uint i = 0; i < doors.length; i++) {
      if (doors[i].participant != address(0x0)) continue;
      if (doors[i].doorType != DoorType.GOAT) continue;

      freeGoats[goats_len++] = i;
    }

    uint[] memory perm = genPermutation(goats_len);

    for (uint i = 0; i < doors.length / 3; i++) {
      doors[freeGoats[perm[i]]].open = true;
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
    switchedNum++;
    if (switchedNum == doors.length / 3) {
      phase = GamePhase.END;

      emit SwitchingCompleted(round);

      finalizeGame();
    }
  }

  function chooseDoor(uint doorIdx) private {
    require(
      doors[doorIdx].participant == address(0x0) || doors[doorIdx].participant == msg.sender,
      "The door the participant choose must be equal as previous or be empty."
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

    emit DoorChosen(msg.sender, doorIdx);
  }
}
