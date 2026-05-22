const hre = require("hardhat");

async function main() {
  console.log("Deploying contracts...");

  const TicketNFT = await hre.ethers.getContractFactory("TicketNFT");
  const ticketNFT = await TicketNFT.deploy();
  await ticketNFT.waitForDeployment();
  const nftAddress = await ticketNFT.getAddress();
  
  console.log("TicketNFT deployed to:", nftAddress);

  const TicketManager = await hre.ethers.getContractFactory("TicketManager");
  const ticketManager = await TicketManager.deploy(nftAddress);
  await ticketManager.waitForDeployment();
  const managerAddress = await ticketManager.getAddress();
  
  console.log("TicketManager deployed to:", managerAddress);

  const setMinterTx = await ticketNFT.setTicketManager(managerAddress);
  await setMinterTx.wait();
  console.log("TicketManager set as minter");

  console.log("\n=== Deployment Complete ===");
  console.log("TicketNFT:", nftAddress);
  console.log("TicketManager:", managerAddress);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});