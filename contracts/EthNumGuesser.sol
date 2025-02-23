// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract EthNumGuesser is Ownable {
  uint256 private dailyNumber; // the number to be guessed
  uint256 private lastGenerated; // timestamp when last number was generated
  uint256 private immutable maxNumber; // TODO: is this needed?

  mapping(address => uint256) private lastGuessTime; // stores last guess timestamps
  mapping(address => uint256) private userGuesses; //

  // events
  event NumberGenerated(uint256 timestamp);
  event GuessMade(address indexed player, uint256 guess, bool correct);

  constructor(uint256 _maxNumber) Ownable(msg.sender) {
    maxNumber = _maxNumber;
    generateNewNumber();
  }

  // generate a new daily number (Owenr-only)
  function generateNewNumber() public onlyOwner {
    require(block.timestamp >= lastGenerated + 1 days, "Can only generate once per day");
    dailyNumber = _pseudoRandomNumber();
    lastGenerated = block.timestamp;
    emit NumberGenerated(block.timestamp);
  }

  // Guessing function (Users call this) 
  function makeGuess(uint256 _guess) public {
    require(block.timestamp >= lastGuessTime[msg.sender] + 1 days, "Can only guess once per 24 hours");
    require(_guess > 0 && _guess <= maxNumber, "Invalid guess");

    lastGuessTime[msg.sender] = block.timestamp; // Update last guess timestamp
    userGuesses[msg.sender] = _guess; // Stores user's last guess

    bool correct = (_guess == dailyNumber);
    emit GuessMade(msg.sender, _guess, correct);
  }

  function withdrawalDonatedFundsOnly() external onlyOwner {
    // FIXME: the owner should only be able to withdrawal their additions, need to create a tracker for their contributions
    // payable(owner()).transfer(address(this).balance);
  }

  // TODO: why do I need this?
  receive() external payable {}

  // FIXME: Generate pseudo-random number (Temporary, Not Secure)
  function _pseudoRandomNumber() private view returns (uint256) {
    return (uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender))) % maxNumber) + 1;
  }
}

