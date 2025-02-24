// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./VRFManager.sol";

contract EthNumGuesser is VRFManager, Ownable {
  uint256 private dailyNumber;
  uint256 public lastGenerated; 
  uint256 public immutable maxNumber; // TODO: is this needed?
  uint256 public minimumGasPerGuess = 0.0001 ether;
  uint256 public ownerContribution;

  mapping(address => uint256) private lastGuessTime; 
  mapping(address => uint256) private userGuesses; 

  // events
  event NumberGenerated(uint256 timestamp);
  event GuessMade(address indexed player, uint256 guess, bool correct);
  event MinimumGasPerGuessUpdated(uint256 newGasPrice);
  event ContractFunded(address indexed owner, uint256 amount);

  constructor(address _vrfCoordinator, bytes32 _keyHash, uint256 _maxNumber) 
    VRFManager(_vrfCoordinator, _keyHash) 
    Ownable(msg.sender) 
  {
    require(_maxNumber > 1, "Max number must be greater than 1");
    maxNumber = _maxNumber;
  }

  function getContractBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function generateNewNumber() public onlyOwner {
    require(block.timestamp >= lastGenerated + 1 days, "Can only generate once per day");
    requestRandomNumber();
  }

  function _updateDailyNumber() internal override {
    require(randomNumber > 0, "Random number not set");
    dailyNumber = (randomNumber % maxNumber) + 1;
    lastGenerated = block.timestamp;
    emit NumberGenerated(lastGenerated);
  }

  function makeGuess(uint256 _guess) public payable {
    require(msg.value >= minimumGasPerGuess, "Insufficient ETH sent");
    require(block.timestamp >= lastGuessTime[msg.sender] + 1 days, "Can only guess once per 24 hours");
    require(_guess > 0 && _guess <= maxNumber, "Invalid guess");

    lastGuessTime[msg.sender] = block.timestamp;
    userGuesses[msg.sender] = _guess;

    bool correct = (_guess == dailyNumber);
    emit GuessMade(msg.sender, _guess, correct);
  }

  function setMinimumGasPerGuess(uint256 _newAmount) external onlyOwner {
    require(_newAmount > 0, "Minimum gas must be greater than zero");
    minimumGasPerGuess = _newAmount;
    emit MinimumGasPerGuessUpdated(_newAmount);
  }

  function fundContract() external payable onlyOwner {
    require(msg.value > 0, "Must send ETH to fund contract");
    ownerContribution += msg.value; // Track owner’s total contribution
    emit ContractFunded(msg.sender, msg.value);
  }

  // TODO: why do I need this?
  receive() external payable {}
}

