# Multi-Chain NFT Ticket System

A blockchain-based event ticketing system demonstrating scalability through Layer 1 and Layer 2 deployment. Built with Solidity smart contracts and deployed on Ethereum Sepolia and Polygon Amoy testnets.

## Project Overview

This system implements a decentralized NFT ticketing platform that allows:
- **Event organizers** to mint and sell tickets as NFTs
- **Users** to purchase, transfer, and verify ticket ownership
- **Venues** to validate tickets at entry
- **Multi-chain deployment** showcasing blockchain scalability strategies

## Live Demo

**Website**: [https://blockchain-project-22zs.vercel.app](https://blockchain-project-22zs.vercel.app)

**Prerequisites**:
- MetaMask browser extension
- Test tokens from faucets:
  - Sepolia ETH: https://sepoliafaucet.com
  - Polygon Amoy MATIC: https://faucet.polygon.technology

---

## Technology Stack

### Smart Contracts
- **Language**: Solidity 0.8.20
- **Framework**: Hardhat
- **Standards**: ERC-721 (NFT), OpenZeppelin libraries
- **Networks**: 
  - Sepolia Testnet (Ethereum Layer 1)
  - Polygon Amoy Testnet (Layer 2)

### Frontend
- **Interface**: HTML5, CSS3, JavaScript (ES6)
- **Web3 Library**: ethers.js v5.7.2
- **Wallet Integration**: MetaMask
- **Deployment**: Vercel

---

## Smart Contracts Architecture

### TicketNFT.sol
Implements ERC-721 standard for ticket tokens with custom metadata:

```solidity
struct Ticket {
    string eventName;
    string seatNumber;
    uint256 eventDate;
    bool isUsed;
}
```

**Key Functions:**
- `mintTicket()`: Creates new ticket NFT (authorized manager only)
- `getTicket()`: Retrieves ticket metadata
- `markAsUsed()`: Validates ticket at venue entry
- `setTicketManager()`: Authorizes the manager contract
- `ownerOf()`: Returns current ticket owner

### TicketManager.sol
Manages ticket marketplace and access control:

**Key Functions:**
- `mintTicket()`: Creates tickets with pricing (organizer only)
- `buyTicket()`: Handles ticket purchases with payment
- `verifyTicket()`: Marks tickets as used (staff only)
- `getAvailableTickets()`: Returns purchasable tickets
- `transferTicket()`: Transfers ownership between users

### Design Rationale

#### Why Two Contracts?
**Separation of Concerns**: 
- **TicketNFT**: Core token logic (ERC-721 compliance, metadata storage)
- **TicketManager**: Business logic (sales, pricing, access control)

**Benefits**:
- Easier upgrades (can replace manager without affecting NFTs)
- Clear responsibility boundaries
- Gas optimization through simpler contracts
- Enhanced security through role separation

#### Why Multi-Chain?
**Scalability Demonstration**:

| Feature | Sepolia (L1) | Polygon Amoy (L2) |
|---------|--------------|-------------------|
| Transaction Speed | ~15 seconds | ~2 seconds |
| Gas Cost | Higher | 99% cheaper |
| Security | Ethereum security | Ethereum security (via checkpoints) |
| Best For | Development baseline | High-volume events |

---

## Deployed Contracts

### Sepolia Testnet (Layer 1)
- **TicketNFT**: `0xD05a9B838e2601b88d151584cF0bcA0D1AD1A31D`
- **TicketManager**: `0xcA3E042Ef1b5e3613137A055d2A39Bd31db67602`
- **Block Explorer**: https://sepolia.etherscan.io

### Polygon Amoy Testnet (Layer 2)
- **TicketNFT**: `0x67B4175345720CF3542C7181b8856EC65b48d267`
- **TicketManager**: `0x4F8B2f05AacDD8E96310bFd59aCC76a46f1fe149`
- **Block Explorer**: https://amoy.polygonscan.com

---

## Local Development Setup

### Prerequisites
- Node.js v16+ and npm
- MetaMask wallet
- Git

### Installation

```bash
# Clone repository
git clone https://github.com/strawberryshortcakeeee/Blockchain_Project.git
cd Blockchain_Project

# Install dependencies
npm install

# Create environment file
echo "PRIVATE_KEY=your_metamask_private_key" > .env
```

### Compile Contracts

```bash
npx hardhat compile
```

### Deploy to Testnets

```bash
# Deploy to Sepolia
npx hardhat run scripts/deploy.js --network sepolia

# Deploy to Polygon Amoy
npx hardhat run scripts/deploy.js --network polygonAmoy
```

---

## Local Testing with Remix & Ganache

For local development and testing before testnet deployment:

### Step 1: Start Ganache
1. Open Ganache application
2. Click **Quickstart** to create local blockchain
3. Note the RPC Server (usually `http://127.0.0.1:7545`)

### Step 2: Open in Remix Desktop
1. Open Remix Desktop IDE
2. Click **Open Folder** and select project directory
3. Navigate to `contracts/` folder

### Step 3: Connect to Ganache
1. In Remix, go to **Deploy & Run Transactions**
2. Under **ENVIRONMENT**, select **Custom HTTP Server URL**
3. Enter Ganache RPC URL from Step 1
4. Verify test accounts (100 ETH each) appear

### Step 4: Compile & Deploy
1. Open `contracts/TicketNFT.sol`
2. Go to **Solidity Compiler** tab
3. Click **Compile TicketNFT.sol**
4. Repeat for `contracts/TicketManager.sol`
5. Deploy **TicketNFT** first, copy its address
6. Deploy **TicketManager** with TicketNFT address as parameter

---

## Testing Functions

Assume Ganache accounts:
- **Account 0**: Organizer
- **Account 1**: User A  
- **Account 2**: User B

### 1. Mint a Ticket (Organizer Only)

```
Account: Organizer (Index 0)
Function: mintTicket
Parameters:
  _eventName: "Rock Concert"
  _seatNumber: "A1"
  _eventDate: 1735689600
  _price: 1000000000000000000 (1 ETH in Wei)
```

**Verify**: Call `isForSale(1)` → should return `true`

### 2. Buy a Ticket

```
Account: User A (Index 1)
Value: 1 ETH
Function: buyTicket
Parameters:
  _ticketId: 1
```

**Verify**: 
- Call `isForSale(1)` → should return `false`
- User A balance reduced by ~1 ETH

### 3. Transfer Ticket

```
Account: User A (Index 1)
Function: transferTicket
Parameters:
  _from: [User A's address]
  _to: [User B's address]
  _ticketId: 1
```

**Verify**: Call `ownerOf(1)` in TicketNFT → returns User B's address

### 4. Verify Ticket (Mark as Used)

```
Account: Any (staff)
Function: verifyTicket
Parameters:
  _ticketId: 1
```

**Verify**: Call `getTicket(1)` → `isUsed` field is `true`

---

## Live Website Usage

### For Users

1. **Connect Wallet**
   - Visit https://blockchain-project-22zs.vercel.app
   - Click "Connect MetaMask"
   - Select network (Sepolia or Polygon Amoy)

2. **Purchase Tickets**
   - Browse "Available Tickets" section
   - Click "Buy Ticket" on desired event
   - Confirm transaction in MetaMask

3. **View Owned Tickets**
   - Check "My Tickets" section
   - See ticket details and status

4. **Transfer Tickets**
   - Enter ticket ID and recipient address
   - Click "Transfer Ticket"
   - Confirm in MetaMask

### For Organizers

1. **Mint Tickets**
   - Connect with organizer wallet
   - Access "Mint New Ticket" section
   - Fill event details and price
   - Confirm transaction

### For Venues

1. **Verify Entry**
   - Access "Verify Ticket" section
   - Enter ticket ID from attendee
   - Click "Mark as Used"
   - Ticket becomes non-transferable

---

## Security Features

### Access Control
- **Role-Based Permissions**: Only deployer is organizer
- **Manager Authorization**: Only TicketManager can mint
- **Ownership Validation**: Transfer checks prevent unauthorized moves

### Input Validation
- Price must be positive
- Ticket ID must exist
- Exact payment amount required
- Used tickets cannot be transferred

### Attack Prevention
- **Reentrancy Protection**: Checks-effects-interactions pattern
- **Integer Overflow**: Solidity 0.8.20 built-in checks
- **Front-Running**: Price fixed at minting time

---

## Testing Results

### Manual Test Cases

| Test Case | Expected Result | Actual Result | Status |
|-----------|----------------|---------------|--------|
| Wallet connection (Sepolia) | Connected successfully | ✓ | Pass |
| Wallet connection (Amoy) | Connected successfully | ✓ | Pass |
| Mint ticket (organizer) | NFT created, listed for sale | ✓ | Pass |
| Mint ticket (non-organizer) | Transaction reverted | ✓ | Pass |
| Buy ticket (exact price) | Ownership transferred | ✓ | Pass |
| Buy ticket (wrong price) | Transaction reverted | ✓ | Pass |
| Transfer owned ticket | New owner recorded | ✓ | Pass |
| Transfer unowned ticket | Transaction reverted | ✓ | Pass |
| Verify ticket | Marked as used | ✓ | Pass |
| Transfer used ticket | Transaction reverted | ✓ | Pass |

### Gas Cost Comparison

| Operation | Sepolia (L1) | Polygon Amoy (L2) | Savings |
|-----------|--------------|-------------------|---------|
| Deploy TicketNFT | ~2,500,000 gas | ~2,500,000 gas | - |
| Deploy TicketManager | ~1,800,000 gas | ~1,800,000 gas | - |
| Mint Ticket | ~150,000 gas | ~150,000 gas | - |
| Buy Ticket | ~80,000 gas | ~80,000 gas | - |
| **Total Cost (USD)** | ~$5.00 | ~$0.05 | **99%** |

*Estimated at 30 gwei (Sepolia) vs 30 gwei (Amoy) with respective token prices*

---

## Limitations & Future Improvements

### Current Limitations
- Single organizer per deployment
- No refund mechanism
- Fixed pricing (no dynamic pricing/auctions)
- Testnet only (not production-ready)
- No secondary market royalties

### Proposed Enhancements
1. **Multi-Organizer Support**: Role-based access for multiple event creators
2. **Refund System**: Cancellation policy with automated refunds
3. **Secondary Market**: Peer-to-peer resale with organizer royalties
4. **Dynamic Pricing**: Price adjustments based on demand
5. **Mobile App**: Native iOS/Android applications
6. **QR Codes**: Generated tickets with scannable entry codes
7. **Event Analytics**: Dashboard for organizers
8. **Integration**: Real-world payment systems (Stripe, PayPal)

---

## BPMN Diagram

<img width="1019" height="1789" alt="bpmn drawio (1)" src="https://github.com/user-attachments/assets/fdc78308-e608-4a38-bf4b-a512be568183" />

The Business Process Model and Notation diagram illustrates the complete ticket lifecycle from minting through verification, including all stakeholder interactions and decision points.

---

## Project Structure

```
Blockchain_Project/
├── contracts/              # Smart contracts
│   ├── TicketNFT.sol      # ERC-721 implementation
│   ├── TicketManager.sol   # Marketplace logic
│   ├── TicketNFT.json     # Compiled ABI
│   └── TicketManager.json # Compiled ABI
├── scripts/
│   └── deploy.js          # Hardhat deployment script
├── hardhat.config.js      # Network configuration
├── index.html             # Frontend interface
├── package.json           # Dependencies
├── bpmn-diagram.png       # Process diagram
└── README.md              # Documentation
```

---

## Team Contributions

### Jasmine
- Smart contract development and interactions
- Backend payment transfer logic
- Contract testing and debugging

### Shuqi  
- Project methodology and documentation
- PPT presentation slides
- BPMN diagram creation
- Payment transfer backend fixes
- Multi-chain deployment

---

## Course Information

- **Course**: IFB452 - Blockchain and Cryptocurrency
- **Institution**: Queensland University of Technology
- **Semester**: 2026 Semester 1
- **Assessment**: Part 2 of Assessment 3 (45%)

---

## Submission Details

**Live Demonstration**: Week 13 Lab Session  
**Code Submission**: Friday 29/05/2026 11:59 PM  
**Video Demo**: 3-minute screen capture with voice-over

---

## Academic Integrity Statement

This project was developed independently without the use of AI coding assistants (ChatGPT, GitHub Copilot, etc.) in compliance with IFB452 academic integrity policies. All code was written by team members through independent research, official documentation, and course materials.

---

## License

This project is submitted as academic coursework at Queensland University of Technology and is not licensed for commercial use or redistribution.

---

## Acknowledgments

- OpenZeppelin for secure smart contract libraries
- Hardhat development framework
- Ethereum and Polygon developer communities
- QUT Trusted Networks Lab for guidance
- Course instructor and tutors for support

---

## References

1. OpenZeppelin ERC-721 Documentation
2. Ethereum Developer Documentation (ethereum.org)
3. Polygon PoS Architecture (polygon.technology)
4. Hardhat Documentation (hardhat.org)
5. Solidity Documentation (soliditylang.org)
