const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const { ethers } = require("hardhat");

module.exports = buildModule("EthNumGuesser", (m) => {
  const ethNumGuesser = m.contract("EthNumGuesser", [
    ethers.ZeroAddress, // Mock VRF Coordinator address
    ethers.encodeBytes32String("test"), // Mock Key Hash
    4 // Set maxNumber to 4 for testing
  ]);



  return { ethNumGuesser };
});