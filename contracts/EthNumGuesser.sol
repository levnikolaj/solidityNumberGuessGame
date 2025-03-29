// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import "./VRFManager.sol";

contract EthNumGuesser is VRFManager, AutomationCompatible, Ownable {
  uint256 private dailyNumber;
  uint256 public lastGenerated; 
  uint256 public immutable maxNumber; // TODO: is this needed?
  uint256 public minGasPerGuess = 0.0001 ether;
  uint256 public minContractBalance = 1 ether;
  uint256 public ownerContribution;
  bool public dailyNumberGuessed;

  mapping(address => uint256) private lastGuessTime; 
  mapping(address => uint256) private userGuesses;

  // events
  event NumberGenerated(uint256 timestamp);
  event GuessMade(address indexed player, uint256 guess, bool correct);
  event MinGasPerGuessUpdated(uint256 newGasPrice);
  event ContractFunded(address indexed owner, uint256 amount);
  event DailyNumberGuessed(uint256 winningNumber, address winner);
  event WinningsDistributed(address indexed winner, uint256 amount);

  constructor(address _vrfCoordinator, bytes32 _keyHash, uint256 _maxNumber) VRFManager(_vrfCoordinator, _keyHash) Ownable(msg.sender) {
    require(_maxNumber > 1, "Max number must be greater than 1");
    maxNumber = _maxNumber;
  }

  function hasDailyNumberBeenGuessed() public view returns (bool) {
    return dailyNumberGuessed;
  }

  function getContractBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function generateNewNumber() public onlyOwner {
    require(block.timestamp >= lastGenerated + 1 days, "Can only generate once per day");
    require(!dailyNumberGuessed, "Wait for previous game to reset");
    requestRandomNumber();
  }

  function _updateDailyNumber() internal override {
    require(randomNumber > 0, "Random number not set");
    dailyNumber = (randomNumber % maxNumber) + 1;
    dailyNumberGuessed = false;
    lastGenerated = block.timestamp;
    emit NumberGenerated(lastGenerated);
  }

  function canMakeGuess() public view returns (bool) {
    return !dailyNumberGuessed;
  }

  function makeGuess(uint256 _guess) public payable {
    if (dailyNumberGuessed) {
      revert("Daily number has already been guessed"); // saving gas
    }

    require(msg.value >= minGasPerGuess, "Insufficient ETH sent");
    require(block.timestamp >= lastGuessTime[msg.sender] + 1 days, "Can only guess once per 24 hours");
    require(_guess > 0 && _guess <= maxNumber, "Invalid guess");

    lastGuessTime[msg.sender] = block.timestamp;
    userGuesses[msg.sender] = _guess;

    bool correct = (_guess == dailyNumber);
    if (correct) {
      dailyNumberGuessed = true;
      emit DailyNumberGuessed(dailyNumber, msg.sender);
    }

    emit GuessMade(msg.sender, _guess, correct);
  }

  function distributeWinnings(address winner) internal {
    uint256 contractBalance = address(this).balance;
    require(contractBalance > minContractBalance, "Not enough funds");

    uint256 excessBalance = contractBalance - minContractBalance;
    uint256 payout = (excessBalance * 40) / 100; // 40% of excess balance

    payable(winner).transfer(payout);
    emit WinningsDistributed(winner, payout);
  }

  function setMinGasPerGuess(uint256 _newAmount) external onlyOwner {
    require(_newAmount > 0, "Minimum gas must be greater than zero");
    minGasPerGuess = _newAmount;
    emit MinGasPerGuessUpdated(_newAmount);
  }

  function fundContract() external payable onlyOwner {
    require(msg.value > 0, "Must send ETH to fund contract");
    ownerContribution += msg.value; // Track owner’s total contribution
    emit ContractFunded(msg.sender, msg.value);
  }

  function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory) {
    upkeepNeeded = (block.timestamp >= lastGenerated + 1 days) && !dailyNumberGuessed;
  }

  function performUpkeep(bytes calldata) external override {
    if(block.timestamp >= lastGenerated + 1 days && !dailyNumberGuessed) {
      requestRandomNumber();
    }
  }

  receive() external payable {}
}

