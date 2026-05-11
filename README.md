# Blockchain_Project

## How to Run and Deploy Contracts

This project contains two smart contracts (`TicketManager.sol` and `TicketNFT.sol`) located in the `contracts` folder. You can test and run them using **Remix Desktop IDE** and **Ganache**.

### Step 1: Start Ganache
1. Open the Ganache application.
2. Click on **Quickstart** to spin up a local Ethereum blockchain.
3. Note the **RPC Server** address (usually `http://127.0.0.1:7545` or `8545`) and keep Ganache running in the background.

### Step 2: Open Contracts in Remix Desktop IDE
1. Open the Remix Desktop application.
2. From the main screen or **File Explorer** on the left sidebar, click on **Open Folder** and select this project's root directory.
3. Your `contracts` folder and its contents should now be visible in the workspace.

### Step 3: Connect Remix Desktop to Ganache
1. In Remix Desktop, click on the **Deploy & Run Transactions** icon on the left sidebar.
2. Under the **ENVIRONMENT** dropdown, select **Custom HTTP Server URL**.
3. If prompted, enter the Ganache RPC Server URL from Step 1 (e.g., `http://127.0.0.1:7545`).
4. You should now see the test accounts (with 100 ETH each) from your Ganache instance loaded in the **ACCOUNT** dropdown.

### Step 4: Compile the Contracts
1. In Remix Desktop's file explorer, open `contracts/TicketNFT.sol`.
2. Go to the **Solidity Compiler** tab on the left sidebar.
3. Click **Compile TicketNFT.sol**.
4. Repeat the process for `contracts/TicketManager.sol`.

### Step 5: Deploy and Test
1. Go back to the **Deploy & Run Transactions** tab.
2. Select `TicketNFT` from the **CONTRACT** dropdown and click **Deploy**.
3. Once deployed, find the `TicketNFT` contract under **Deployed Contracts** at the bottom left and copy its contract address (using the copy icon).
4. Select `TicketManager` from the **CONTRACT** dropdown.
5. Paste the copied `TicketNFT` address into the deployment parameter input field next to the **Deploy** button, then click **Deploy**.
6. Expand the deployed `TicketManager` contract to interact with its functions (like creating events, buying tickets, etc.). You can watch Ganache to see the transactions being processed live!

## How to Test External Functions

To simulate a real-world scenario, you can use the test accounts provided by Ganache. In the Remix **ACCOUNT** dropdown, assume the first account (Index 0) is the **Organizer**, the second account (Index 1) is **User A**, and the third account (Index 2) is **User B**.

### 1. Mint a Ticket (`mintTicket`)
*Only the Organizer can mint tickets and put them up for sale.*
1. Ensure the **ACCOUNT** dropdown is set to the **Organizer** (Index 0).
2. Expand the `TicketManager` contract under **Deployed Contracts**.
3. Locate the `mintTicket` function. Expand its inputs using the down arrow.
4. Enter test data:
   - `_eventName`: `"Rock Concert"`
   - `_seatNumber`: `"A1"`
   - `_eventDate`: `1735689600` *(Any Unix timestamp)*
   - `_price`: `1000000000000000000` *(This equals 1 ETH in Wei)*
5. Click **transact**.
6. *Verification:* You can check the ticket exists by calling `isForSale` with the ticket ID `1`. It should return `true`.

### 2. Buy a Ticket (`buyTicket`)
*A user pays the exact price to purchase an available ticket.*
1. Change the **ACCOUNT** dropdown to **User A** (Index 1).
2. Scroll to the top of the left panel and find the **VALUE** input field. Keep the unit as **Ether** and type `1` (to match the 1 ETH price set earlier).
3. Back in the `TicketManager` contract panel, locate the `buyTicket` function.
4. Enter `_ticketId`: `1`
5. Click **transact**.
6. *Verification:* Call `isForSale` with ID `1` to see it is now `false`. Also, check **User A**'s account balance in the dropdown; it should be reduced by 1 ETH.

### 3. Transfer a Ticket (`transferTicket`)
*The current owner can transfer an unused ticket to another address.*
1. Keep the **ACCOUNT** dropdown on **User A** (Index 1), as they currently own Ticket 1.
2. Copy the address of **User B** (Index 2) from the account dropdown.
3. Locate the `transferTicket` function in the `TicketManager` contract.
4. Enter:
   - `_from`: *Paste User A's Address"*
   - `_to`: *"Paste User B's Address"*
   - `_ticketId`: `1`
5. Click **transact**.
6. *Verification:* You can check the new owner through the `TicketNFT` deployed contract using the `ownerOf` function with ID `1`.

### 4. Verify a Ticket (`verifyTicket`)
*At the gate, the ticket is scanned and marked as used so it cannot be transferred or used again.*
1. Any account can call this, representing the venue staff.
2. Locate the `verifyTicket` function in `TicketManager`.
3. Enter `_ticketId`: `1`
4. Click **transact**.
5. *Verification:* If you look at the `TicketNFT` contract and query `getTicket` with ID `1`, the `isUsed` property will now be set to `true`. If someone tries to call `transferTicket` on ID `1` again, the transaction will fail.

## Contribution
### Jasmine
- Smart contract interactions
- Backend development

### Shuqi
- Methodology
- PPT slides
- BPMN diagram
- Payment transfer backend fixes

## BPMN Diagram
![BPMN Diagram](bpmn.drawio.png)
