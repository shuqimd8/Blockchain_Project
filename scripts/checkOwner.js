const hre = require("hardhat");

async function main() {
  const nftAddress = "0x67B4175345720CF3542C7181b8856EC65b48d267";
  
  const TicketNFT = await hre.ethers.getContractFactory("TicketNFT");
  const ticketNFT = await TicketNFT.attach(nftAddress);
  
  const manager = await ticketNFT.manager();
  console.log("Current manager:", manager);
  
  const [deployer] = await hre.ethers.getSigners();
  console.log("Your account:", deployer.address);
  
  if (manager.toLowerCase() === deployer.address.toLowerCase()) {
    console.log("You are the manager!");
  } else {
    console.log("You are NOT the manager!");
    console.log("You need to use the account:", manager);
  }
}

main().catch(console.error);