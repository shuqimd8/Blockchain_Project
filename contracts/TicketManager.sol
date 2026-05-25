// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ITicketNFT
 * @notice Interface for TicketNFT contract
 * @dev Defines all external functions and structures needed by TicketManager
 */
interface ITicketNFT {
    /// @notice Ticket metadata structure mirroring TicketNFT.sol
    struct Ticket {
        uint256 ticketId;
        string eventName;
        string seatNumber;
        uint256 eventDate;
        bool isUsed;
    }

    function mintTicket(address to, string memory _eventName, string memory _seatNumber, uint256 _eventDate) external returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function markAsUsed(uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function getTicket(uint256 tokenId) external view returns (Ticket memory);
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

/**
 * @title TicketManager
 * @author Jasmine & Shuqi - QUT IFB452 Blockchain Project
 * @notice Manages ticket sales, transfers, and verification for events
 * @dev Interacts with TicketNFT contract via interface for separation of concerns
 * 
 * Design Rationale:
 * - Separate contract from TicketNFT enables business logic updates without affecting NFT standard
 * - Acts as escrow during initial sales (contract holds tickets until purchased)
 * - Manager contract is authorized to mint tickets (via TicketNFT.setManager())
 * - Payment handling implements checks-effects-interactions pattern for security
 */
contract TicketManager {
    /// @notice Address of the event organizer (contract deployer)
    /// @dev Only organizer can mint tickets and receive payments
    address public organizer;
    
    /// @notice Reference to the TicketNFT contract
    ITicketNFT public ticketNFT;

    /// @notice Mapping from ticket ID to sale price in wei
    /// @dev Price set during minting and fixed (no dynamic pricing in current version)
    mapping(uint256 => uint256) public ticketPrices;
    
    /// @notice Mapping from ticket ID to sale status
    /// @dev True = available for purchase, False = sold
    mapping(uint256 => bool) public isForSale;

    /// @notice Emitted when a ticket is purchased
    /// @param ticketId Unique ticket identifier
    /// @param buyer Address of the purchaser
    event TicketPurchased(uint256 indexed ticketId, address indexed buyer);
    
    /// @notice Emitted when a ticket is peer-to-peer transferred
    /// @param ticketId Unique ticket identifier
    /// @param from Previous owner
    /// @param to New owner
    event TicketTransferred(uint256 indexed ticketId, address indexed from, address indexed to);
    
    /// @notice Emitted when a ticket is verified at venue entry
    /// @param ticketId Unique ticket identifier
    /// @param staff Address of staff member who verified ticket
    event TicketVerified(uint256 indexed ticketId, address indexed staff);

    /// @notice Restricts function access to the organizer
    modifier onlyOrganizer() {
        require(msg.sender == organizer, "Only organizer can execute this");
        _;
    }

    /// @notice Initializes manager with reference to TicketNFT contract
    /// @dev Deploy sequence: 1) Deploy TicketNFT, 2) Deploy TicketManager with NFT address, 3) Call TicketNFT.setManager(this address)
    /// @param _ticketNFTAddress Address of deployed TicketNFT contract
    constructor(address _ticketNFTAddress) {
        organizer = msg.sender;
        ticketNFT = ITicketNFT(_ticketNFTAddress);
    }

    /// @notice Mints a new ticket and lists it for sale
    /// @dev Only organizer can call. Ticket is minted to this contract (escrow) until purchased.
    /// @param _eventName Name of the event
    /// @param _seatNumber Seat identifier (e.g., "A1", "VIP-5")
    /// @param _eventDate Unix timestamp of event start time
    /// @param _price Sale price in wei (e.g., 1000000000000000000 = 1 ETH)
    function mintTicket(string memory _eventName, string memory _seatNumber, uint256 _eventDate, uint256 _price) external onlyOrganizer {
        uint256 ticketId = ticketNFT.mintTicket(address(this), _eventName, _seatNumber, _eventDate);
        ticketPrices[ticketId] = _price;
        isForSale[ticketId] = true;
    }

    /// @notice Purchases a ticket from the initial sale
    /// @dev Implements escrow release: transfers NFT from contract to buyer, payment to organizer
    /// Gas cost: ~80,000 gas (~$2.40 at 30 gwei, $3000 ETH)
    /// Security: Uses checks-effects-interactions pattern to prevent reentrancy
    /// @param _ticketId Unique ticket identifier
    function buyTicket(uint256 _ticketId) external payable {
        require(isForSale[_ticketId], "Ticket is not for sale");
        require(ticketNFT.ownerOf(_ticketId) == address(this), "Ticket already sold");
        require(msg.value == ticketPrices[_ticketId], "Wrong funds sent");

        isForSale[_ticketId] = false;
        
        ticketNFT.transferFrom(address(this), msg.sender, _ticketId);
        (bool sent, ) = payable(organizer).call{value: msg.value}("");
        require(sent, "Payment failed");

        emit TicketPurchased(_ticketId, msg.sender);
    }

    /// @notice Transfers ticket ownership peer-to-peer (secondary market)
    /// @dev Caller must be current owner. Used tickets cannot be transferred.
    /// Design Decision: No platform fee on peer-to-peer transfers in current version.
    /// Future Enhancement: Add configurable royalty fee to organizer on resales.
    /// @param _to Recipient address
    /// @param _ticketId Unique ticket identifier
    function transferTicket(address _to, uint256 _ticketId) external {
        require(ticketNFT.ownerOf(_ticketId) == msg.sender, "You are not the owner of this ticket");
        require(!ticketNFT.getTicket(_ticketId).isUsed, "Cannot transfer a used ticket");
        
        ticketNFT.transferFrom(msg.sender, _to, _ticketId);
        
        emit TicketTransferred(_ticketId, msg.sender, _to);
    }

    /// @notice Marks a ticket as used after venue entry
    /// @dev Any address can call (venue staff). Once marked, ticket cannot be transferred.
    /// Design Decision: Open access for venue flexibility. Production would use access control.
    /// @param _ticketId Unique ticket identifier
    function verifyTicket(uint256 _ticketId) external {
        require(ticketNFT.ownerOf(_ticketId) != address(0), "Ticket does not exist");
        require(!ticketNFT.getTicket(_ticketId).isUsed, "Ticket has already been used");

        ticketNFT.markAsUsed(_ticketId);

        emit TicketVerified(_ticketId, msg.sender);
    }

    /// @notice Returns array of ticket IDs currently available for purchase
    /// @dev Iterates through first 1000 ticket IDs. Gas cost: O(n) iteration.
    /// Design Trade-off: Simple implementation vs gas efficiency.
    /// Production Enhancement: Use event logs + off-chain indexing (The Graph) instead.
    /// Gas Cost: ~300,000 gas for 100 tickets (~$9 at 30 gwei)
    /// @return Array of available ticket IDs
    function getAvailableTickets() public view returns (uint256[] memory) {
        uint256 totalTickets = 0;
        
        for (uint256 i = 0; i < 1000; i++) {
            if (isForSale[i] && ticketPrices[i] > 0) {
                totalTickets++;
            }
        }
        
        uint256[] memory availableTickets = new uint256[](totalTickets);
        uint256 currentIndex = 0;
        
        for (uint256 i = 0; i < 1000; i++) {
            if (isForSale[i] && ticketPrices[i] > 0) {
                availableTickets[currentIndex] = i;
                currentIndex++;
            }
        }
        
        return availableTickets;
    }
}
