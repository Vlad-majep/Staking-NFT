import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { LendingProtocol} from "../typechain-types";

describe("LendingProtocol", function() {
    async function deploy() {
      const [ owner, user2 ] = await ethers.getSigners();
      const LendingFactory = await ethers.getContractFactory("LendingProtocol");
      const lending : LendingProtocol = await LendingFactory.deploy();
      await lending.deployed();
      const token = await (await ethers.getContractFactory("MCSToken")).deploy(owner.address)

      return { lending, owner, user2 , token}
    }

    it("should have an deposit()", async function() {
      const { lending , owner, token } = await loadFixture(deploy);
      expect(await token.approve(lending.address,  1000))
      expect(await lending.deposit(token.address,  1000))

      expect(await token.balanceOf(owner.address)).to.eq(0)
      expect(await lending.tokenSupply(token.address)).to.eq(1000)
      expect(await lending.userCollateral(token.address, owner.address)).to.eq(1000)
      expect(await lending.totalCollateral(token.address)).to.eq(1000)
    });
});