const { time, loadFixture,} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("PodShip", function () {

  describe("Deployment", function () {

    it("Should set the right owner", async function () {
      const { PodShip, owner } = await loadFixture(deployOneYearLockFixture);

      expect(await PodShip.owner()).to.equal(owner.address);
    });
    
  });

});
