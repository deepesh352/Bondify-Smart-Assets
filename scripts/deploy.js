const { ethers } = require("hardhat");

async function main() {
  const BondifySmartAssets = await ethers.getContractFactory("BondifySmartAssets");
  const bondifySmartAssets = await BondifySmartAssets.deploy();

  await bondifySmartAssets.deployed();

  console.log("BondifySmartAssets contract deployed to:", bondifySmartAssets.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
