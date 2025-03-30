// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import "./VRFManager.sol";

// Define custom errors for gas efficiency and better error handling
error InsufficientETH(uint256 provided, uint256 required);
error InvalidGuess(uint256 guess, uint256 maxNumber);
error NotEnoughFunds(uint256 available, uint256 required);
error DailyNumberAlreadyGuessed(uint256 dailyNumber);
error InvalidGuessTime(uint256 lastGuessTime, uint256 currentTime);
error ContractNotFunded(uint256 available, uint256 required);
error GuessingClosed(uint256 timestamp);

// TODO: upgradability - @openzeppelin/contracts-upgradeable
// EthNumGuesser Contract
// - A decentralized game where players guess a daily number to win ETH rewards.
// - Uses Chainlink VRF for provably fair randomness.
// - Implements pausing, access control, and reentrancy protection.
contract EthNumGuesser is VRFManager, AutomationCompatible, Ownable, ReentrancyGuard, Pausable {
  uint256 private dailyNumber;
  uint256 public lastGenerated; 
  uint256 public constant maxNumber = 10000;
  uint256 public minGasPerGuess = 0.0001 ether;
  uint256 public minContractBalance = 0.5 ether;
  uint256 public ownerContribution;
  bool public dailyNumberGuessed;
  bool public upkeepPaused;

  mapping(address => uint256) private lastGuessTime; 
  mapping(address => uint256) private userGuesses;

  // events
  event NumberGenerated(uint256 timestamp);
  event GuessMade(address indexed player, uint256 guess);
  event MinGasPerGuessUpdated(uint256 newGasPrice);
  event ContractFunded(address indexed owner, uint256 amount);
  event DailyNumberGuessed(uint256 winningNumber, address winner);
  event WinningsDistributed(address indexed winner, uint256 amount);
  event OwnerWithdrawal(address indexed owner, uint256 amount);
  event UpkeepPaused();
  event UpkeepResumed();


  /**
   * @dev Constructor initializes the contract with VRF setup and ownership.
   */
  constructor(address _vrfCoordinator, bytes32 _keyHash) VRFManager(_vrfCoordinator, _keyHash) Ownable(msg.sender) {}

  /**
   * @dev Returns whether the daily number has been guessed.
   */
  function hasDailyNumberBeenGuessed() public view returns (bool) {
    return dailyNumberGuessed;
  }

  /**
   * @dev Returns the contract's current ETH balance.
   */
  function getContractBalance() public view returns (uint256) {
    return address(this).balance;
  }

  /**
   * @dev Generates a new random daily number using Chainlink VRF.
   * Can only be called by the owner once per day.
   */
  function generateNewNumber() public onlyOwner {
    if(dailyNumberGuessed || block.timestamp < lastGenerated + 1 days) {
      revert DailyNumberAlreadyGuessed(dailyNumber);
    }
    requestRandomNumber();
  }

  /**
   * @dev Internal function to update the daily number after VRF callback.
   */
  function _updateDailyNumber() internal override {
    require(randomNumber > 0, "Random number not set");
    dailyNumber = (randomNumber % maxNumber) + 1;
    dailyNumberGuessed = false;
    lastGenerated = block.timestamp;
    emit NumberGenerated(lastGenerated);
  }


  /**
   * @dev Checks whether guessing is allowed (i.e., funds are available, and the number is not guessed).
   */
  function canMakeGuess() public view returns (bool) {
    bool hasEnoughFunds = address(this).balance > minContractBalance;
    return !dailyNumberGuessed && hasEnoughFunds;
  }

  /**
   * @dev Allows the owner to pause the contract in case of emergency.
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @dev Allows the owner to unpause the contract.
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * @dev Allows a user to make a guess. Requires a minimum gas fee and ensures one guess per 24 hours.
   */
  function makeGuess(uint256 _guess) public payable whenNotPaused {
    if(dailyNumberGuessed) {
      revert GuessingClosed(block.timestamp);
    }
    
    if(msg.value < minGasPerGuess) {
      revert InsufficientETH(msg.value, minGasPerGuess);
    }

    if(block.timestamp < lastGuessTime[msg.sender] + 1 days) {
      revert InvalidGuessTime(lastGuessTime[msg.sender], block.timestamp);
    }

    if(_guess == 0 || _guess > maxNumber) {
      revert InvalidGuess(_guess, maxNumber);
    }

    lastGuessTime[msg.sender] = block.timestamp;
    userGuesses[msg.sender] = _guess;

    bool correct = (_guess == dailyNumber);
    if (correct) {
      dailyNumberGuessed = true;
      distributeWinnings(msg.sender);
      emit DailyNumberGuessed(dailyNumber, msg.sender);
    } else {
      emit GuessMade(msg.sender, _guess);
    }
  }

  /**
   * @dev Distributes winnings to the correct guesser based on the contract balance.
   */
  function distributeWinnings(address winner) internal nonReentrant {
    uint256 contractBalance = address(this).balance;
    if(contractBalance <= minContractBalance) {
      revert NotEnoughFunds(contractBalance, minContractBalance);
    }

    uint256 excessBalance = contractBalance - minContractBalance;
    uint256 payout;

    if (excessBalance >= 10 ether) {
      payout = (excessBalance * 50) / 100; // 50% of excess if high balance
    } else if (excessBalance >= 5 ether) {
      payout = (excessBalance * 45) / 100; // 45% of excess if medium balance
    } else {
      payout = (excessBalance * 40) / 100; // 40% of excess if low balance
    }

    payable(winner).transfer(payout);
    emit WinningsDistributed(winner, payout);
  }

  /**
   * @dev Allows the owner to update the minimum gas fee required per guess.
   */
  function setMinGasPerGuess(uint256 _newAmount) external onlyOwner {
    if(_newAmount <= 0) {
      revert InsufficientETH(_newAmount, 0.0001 ether);
    }
    minGasPerGuess = _newAmount;
    emit MinGasPerGuessUpdated(_newAmount);
  }

  /**
   * @dev Allows the owner to fund the contract.
   */
  function fundContract() external payable onlyOwner {
    if(msg.value == 0) {
      revert ContractNotFunded(address(this).balance, minContractBalance);
    }
    ownerContribution += msg.value; // Track owner’s total contribution
    emit ContractFunded(msg.sender, msg.value);
  }

  /**
   * @dev Allows the owner to withdraw only the funds they contributed.
   */
  function withdrawOwnerContribution(uint256 _amount) external onlyOwner nonReentrant {
    if (_amount > ownerContribution) {
      revert NotEnoughFunds(ownerContribution, _amount);
    }
    ownerContribution -= _amount;
    payable(owner()).transfer(_amount);
    emit OwnerWithdrawal(msg.sender, _amount);
  }

  /**
   * @dev Allows the owner to pause Chainlink Automation.
   */
  function pauseUpkeep() external onlyOwner {
    upkeepPaused = true;
    emit UpkeepPaused();
  }

  /**
   * @dev Allows the owner to resume Chainlink Automation.
   */
  function unpauseUpkeep() external onlyOwner {
    upkeepPaused = false;
    emit UpkeepResumed();
  }

  /**
   * @dev Chainlink Automation: Determines whether upkeep is needed (if 24 hours have passed).
   */
  function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory) {
    upkeepNeeded = (block.timestamp >= lastGenerated + 1 days) && !dailyNumberGuessed;

    // Return the value of upkeepNeeded along with an empty byte array (since no additional data is needed)
    return (upkeepNeeded, "");
  }

  /**
   * @dev Chainlink Automation: Performs upkeep by requesting a new random number.
   */
  function performUpkeep(bytes calldata) external override {
    if(!upkeepPaused && block.timestamp >= lastGenerated + 1 days && !dailyNumberGuessed) {
      requestRandomNumber();
    }
  }

  /**
   * @dev Allows the contract to receive ETH.
   */
  receive() external payable {}
}

