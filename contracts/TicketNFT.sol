// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TicketNFT {
    string public name = "Ticket";
    string public symbol = "TKT";

    struct Ticket {
        uint256 ticketId;
        string eventName;
        string seatNumber;
        uint256 eventDate;
        bool isUsed;
    }

    address public owner;
    address public manager;

    mapping(uint256 => Ticket) public tickets;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;

    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Minted(uint256 indexed ticketId, string eventName, string seatNumber, uint256 eventDate);

    modifier onlyOwnerOrManager() {
        require(msg.sender == owner || msg.sender == manager, "Not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setManager(address _manager) external {
        require(msg.sender == owner, "Only owner can set manager");
        manager = _manager;
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address tokenOwner = _owners[tokenId];
        require(tokenOwner != address(0), "Invalid token: does not exist");
        return tokenOwner;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        require(tokenOwner != address(0), "Invalid address");
        return _balances[tokenOwner];
    }

    function mintTicket(address to, string memory _eventName, string memory _seatNumber, uint256 _eventDate) external onlyOwnerOrManager returns (uint256) {
        require(to != address(0), "Cannot mint to zero address");

        totalSupply++;
        uint256 newTicketId = totalSupply;

        tickets[newTicketId] = Ticket({
            ticketId: newTicketId,
            eventName: _eventName,
            seatNumber: _seatNumber,
            eventDate: _eventDate,
            isUsed: false
        });

        _balances[to] += 1;
        _owners[newTicketId] = to;

        emit Transfer(address(0), to, newTicketId);
        emit Minted(newTicketId, _eventName, _seatNumber, _eventDate);

        return newTicketId;
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        require(_owners[tokenId] == from, "Not the owner");
        // Allow the owner themselves, or the manager contract to move the token
        require(msg.sender == from || msg.sender == manager, "Not authorized to transfer");
        require(to != address(0), "Transfer to zero address");

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function markAsUsed(uint256 tokenId) external {
        require(msg.sender == manager, "Only manager contract can update usage state");
        require(_owners[tokenId] != address(0), "Invalid token");
        tickets[tokenId].isUsed = true;
    }

    function getTicket(uint256 tokenId) external view returns (Ticket memory) {
        require(_owners[tokenId] != address(0), "Invalid token");
        return tickets[tokenId];
    }
}
