import { ethers } from "hardhat";

async function main() {
  const [ owner ] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", owner.address);

  console.log("Account balance:", (await owner.getBalance()).toString());

  const task = await ethers.getContractFactory("Staking");
  const contract = await task.deploy();

  console.log("Contract address:", contract.address);
}


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
});