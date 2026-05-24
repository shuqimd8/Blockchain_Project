const hre = require("hardhat");

async function main() {
  console.log("Deploying TicketManager only...");

  // 使用昨天已部署的 TicketNFT 地址
  const nftAddress = "0x67B4175345720CF3542C7181b8856EC65b48d267";
  console.log("Using existing TicketNFT at:", nftAddress);

  // 只部署 TicketManager
  const TicketManager = await hre.ethers.getContractFactory("TicketManager");
  const ticketManager = await TicketManager.deploy(nftAddress);
  await ticketManager.waitForDeployment();
  const managerAddress = await ticketManager.getAddress();
  
  console.log("TicketManager deployed to:", managerAddress);

  // 设置 minter
  const TicketNFT = await hre.ethers.getContractFactory("TicketNFT");
  const ticketNFT = TicketNFT.attach(nftAddress);
  
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