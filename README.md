# 🎲 EthNumGuesser - Ethereum Number Guessing Game  

EthNumGuesser is a **smart contract-based number guessing game** deployed on the Ethereum blockchain.  
Players can submit guesses daily, and if they match the randomly generated number, they win a portion of the contract’s funds!  

The contract uses **Chainlink VRF** for generating random numbers and **Chainlink Automation** to manage automated upkeep.  

---

## 📌 **How It Works**  

1. **The contract generates a new random number** every 24 hours using Chainlink VRF.  
2. **Players submit a guess** by sending a small amount of ETH (`minGasPerGuess`).  
3. **If a player guesses correctly**, they win a **percentage of the contract balance** based on the total funds.  
4. **The owner can manage upkeep**, pause the game, and withdraw only their contributed funds.  

---

## ⚡ **Features**  

✅ **Fair Randomness** - Uses Chainlink VRF for secure, tamper-proof randomness.  
✅ **Automated Upkeep** - Chainlink Automation ensures daily updates.  
✅ **Custom Errors** - Efficient and gas-optimized error handling.  
✅ **Pausable** - The owner can pause the game in emergencies.  
✅ **Upkeep Control** - Prevents Chainlink from draining funds when unnecessary.  
✅ **Owner Contribution Withdrawal** - The owner can withdraw only their contributed funds.  

---

## 🚀 **Deployment Guide**  

### **1️⃣ Prerequisites**  
Before deploying the contract, make sure you have:  
- **Node.js & NPM** installed  
- **Hardhat** (for local development)  
- **A funded Ethereum wallet** (Metamask or similar)  
- **Access to Chainlink VRF & Automation**  

### **2️⃣ Install Dependencies**  
```sh
npm install

## 🎮 Player Functions

| 🔹 Function | 🔍 Description | 🔗 Example |
|------------|--------------|-------------|
| `makeGuess(uint256 _guess)` | Submit a guess (1-10,000) with ETH ≥ `minGasPerGuess`. | `contract.makeGuess(5000, { value: ethers.utils.parseEther("0.0001") })` |
| `canMakeGuess()` | Checks if guessing is allowed. | `contract.canMakeGuess()` |
| `getContractBalance()` | Returns the contract’s current ETH balance. | `contract.getContractBalance()` |

## 👑 Owner Functions  
The contract owner can manage game settings, fund the contract, control upkeep, and withdraw contributions.

| 🏗️ Function | 🔍 Description | 🔗 Example |
|------------|--------------|-------------|
| `generateNewNumber()` | Requests a new random number (only once per day). | `contract.generateNewNumber()` |
| `setMinGasPerGuess(uint256 _newAmount)` | Updates the minimum ETH required per guess. | `contract.setMinGasPerGuess(ethers.utils.parseEther("0.001"))` |
| `fundContract()` | Owner can add funds to the contract. | `contract.fundContract({ value: ethers.utils.parseEther("1") })` |
| `withdrawOwnerContribution(uint256 amount)` | Withdraws only the owner’s contributed funds. | `contract.withdrawOwnerContribution(ethers.utils.parseEther("0.5"))` |
| `pause()` | Pauses the contract, preventing guesses. | `contract.pause()` |
| `unpause()` | Resumes the game. | `contract.unpause()` |
| `transferOwnership(address newOwner)` | Transfers contract ownership. | `contract.transferOwnership("0xNewOwnerAddress")` |

## 🏆 Winnings & Payouts  
The winner's payout is dynamically adjusted based on contract funds.

| 💰 Contract Balance (ETH) | 🏅 Payout to Winner |
|---------------------------|---------------------|
| > 10 ETH                  | 50% of excess balance |
| 5 - 10 ETH                | 45% of excess balance |
| < 5 ETH                   | 40% of excess balance |

## 🎉 Happy Guessing! 🚀