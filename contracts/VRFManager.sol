// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";

contract VRFManager is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface private immutable vrfCoordinator;
  bytes32 private immutable keyHash;
  uint32 private constant callbackGasLimit = 100000; // TODO: what is this?
  uint16 private constant requestConfirmations = 3; // TODO: what is this?
  uint32 private constant numWords = 1;

  uint256 internal randomNumber; 

  // events
  event RandomNumberRequested(uint256 requestId);
  event RandomNumberReceived(uint256 randomNumber); // TODO: does this emit the random number?

  constructor (address _vrfCoordinator, bytes32 _keyHash) VRFConsumerBaseV2(_vrfCoordinator) {
    vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
    keyHash = _keyHash;
  }

  function requestRandomNumber() internal {
    uint256 requestId = vrfCoordinator.requestRandomWords(
      keyHash,
      0, // direct funding
      requestConfirmations,
      callbackGasLimit,
      numWords
    );

    emit RandomNumberRequested(requestId);
  }

  function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
    randomNumber = randomWords[0];
    emit RandomNumberReceived(randomNumber);
  }

  function _updateDailyNumber() internal virtual {}
}