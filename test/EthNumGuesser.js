const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("EthNumGuesser Contract", () => {
  let ethNumGuesser;
  let owner;
  let vrfCoordinator;
  let keyHash;

  beforeEach(async () => {
    // Deploy the contract before each test
    [owner] = await ethers.getSigners();

    vrfCoordinator = ethers.ZeroAddress;
    keyHash = ethers.encodeBytes32String("dummy-key-hash");

    // Deploy contract with VRF coordinator and key hash
    const EthNumGuesser = await ethers.getContractFactory("EthNumGuesser");
    ethNumGuesser = await EthNumGuesser.deploy(vrfCoordinator, keyHash);
  })

  describe("getContractBalance", () => {
    it("should return the correct contract balance", async () => {
      // Check the contract has 0 balance initially
      const initialBalance = await ethNumGuesser.getContractBalance();
      expect(initialBalance).to.equal(0);

      // Fund the contract 1 ether
      await ethNumGuesser.fundContract({value: ethers.parseUnits("1", "ether")});

      // Check contract balance after funding
      const newBalance = await ethNumGuesser.getContractBalance();
      expect(newBalance).to.equal(ethers.parseUnits("1", "ether"));
    });
  });
});