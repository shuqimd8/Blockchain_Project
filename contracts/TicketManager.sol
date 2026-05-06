// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITicketNFT {
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
}

contract TicketManager {
    address public organizer;
    ITicketNFT public ticketNFT;

    mapping(uint256 => uint256) public ticketPrices;
    mapping(uint256 => bool) public isForSale;

    event TicketPurchased(uint256 indexed ticketId, address indexed buyer);
    event TicketTransferred(uint256 indexed ticketId, address indexed from, address indexed to);
    event TicketVerified(uint256 indexed ticketId, address indexed staff);

    modifier onlyOrganizer() {
        require(msg.sender == organizer, "Only organizer can execute this");
        _;
    }

    constructor(address _ticketNFTAddress) {
        organizer = msg.sender;
        ticketNFT = ITicketNFT(_ticketNFTAddress);
    }

    // Creates new ticket via NFT contract and sets it for sale
    function mintTicket(string memory _eventName, string memory _seatNumber, uint256 _eventDate, uint256 _price) external onlyOrganizer {
        // Mint to this manager contract initially
        uint256 ticketId = ticketNFT.mintTicket(address(this), _eventName, _seatNumber, _eventDate);
        ticketPrices[ticketId] = _price;
        isForSale[ticketId] = true;
    }

    // Users purchase available tickets
    function buyTicket(uint256 _ticketId) external payable {
        require(isForSale[_ticketId], "Ticket is not for sale");
        require(ticketNFT.ownerOf(_ticketId) == address(this), "Ticket already sold");
        require(msg.value == ticketPrices[_ticketId], "Wrong funds sent");

        isForSale[_ticketId] = false;
        
        // Transfer the NFT from the contract to the buyer
        ticketNFT.transferFrom(address(this), msg.sender, _ticketId);
        payable(organizer).transfer(msg.value);

        emit TicketPurchased(_ticketId, msg.sender);
    }

    // Users transfer tickets directly using this wrapper function
    function transferTicket(uint256 _ticketId, address _to) external {
        require(ticketNFT.ownerOf(_ticketId) == msg.sender, "You are not the owner of this ticket");
        require(!ticketNFT.getTicket(_ticketId).isUsed, "Cannot transfer a used ticket");
        
        ticketNFT.transferFrom(msg.sender, _to, _ticketId);
        
        emit TicketTransferred(_ticketId, msg.sender, _to);
    }

    // Venue staff verify tickets at the gate
    function verifyTicket(uint256 _ticketId) external {
        require(ticketNFT.ownerOf(_ticketId) != address(0), "Ticket does not exist");
        require(!ticketNFT.getTicket(_ticketId).isUsed, "Ticket has already been used");

        // Mark the ticket as used inside the NFT contract
        ticketNFT.markAsUsed(_ticketId);

        emit TicketVerified(_ticketId, msg.sender);
    }
}
