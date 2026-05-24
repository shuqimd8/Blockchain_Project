const hre = require("hardhat");

async function main() {
  console.log("Setting TicketManager as authorized minter...");
  
  const nftAddress = "0x67B4175345720CF3542C7181b8856EC65b48d267";
  const managerAddress = "0x4F8B2f05AacDD8E96310bFd59aCC76a46f1fe149";

  console.log("TicketNFT:", nftAddress);
  console.log("TicketManager:", managerAddress);

  const [deployer] = await hre.ethers.getSigners();
  console.log("Using account:", deployer.address);

  const TicketNFT = await hre.ethers.getContractFactory("TicketNFT");
  const ticketNFT = await TicketNFT.attach(nftAddress);
  
  console.log("\nSending transaction...");
  
  // 改这里！
  const tx = await ticketNFT.setManager(managerAddress);
  
  console.log("Transaction hash:", tx.hash);
  console.log("Waiting for confirmation...");
  
  await tx.wait();
  
  console.log("\n SUCCESS!");
  console.log("TicketManager is now authorized!");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});