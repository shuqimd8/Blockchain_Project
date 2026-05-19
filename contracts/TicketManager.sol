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
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
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

    function mintTicket(string memory _eventName, string memory _seatNumber, uint256 _eventDate, uint256 _price) external onlyOrganizer {
        uint256 ticketId = ticketNFT.mintTicket(address(this), _eventName, _seatNumber, _eventDate);
        ticketPrices[ticketId] = _price;
        isForSale[ticketId] = true;
    }

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

    function transferTicket(address _to, uint256 _ticketId) external {
        require(ticketNFT.ownerOf(_ticketId) == msg.sender, "You are not the owner of this ticket");
        require(!ticketNFT.getTicket(_ticketId).isUsed, "Cannot transfer a used ticket");
        
        ticketNFT.transferFrom(msg.sender, _to, _ticketId);
        
        emit TicketTransferred(_ticketId, msg.sender, _to);
    }

    function verifyTicket(uint256 _ticketId) external {
        require(ticketNFT.ownerOf(_ticketId) != address(0), "Ticket does not exist");
        require(!ticketNFT.getTicket(_ticketId).isUsed, "Ticket has already been used");

        ticketNFT.markAsUsed(_ticketId);

        emit TicketVerified(_ticketId, msg.sender);
    }

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