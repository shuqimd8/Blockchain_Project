// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TicketNFT {
    string public name = "EventTicket";
    string public symbol = "TIX";
    
    uint256 private _tokenIdCounter;
    
    struct Ticket {
        uint256 ticketId;
        string eventName;
        string seatNumber;
        uint256 eventDate;
        bool isUsed;
    }
    
    mapping(uint256 => Ticket) private tickets;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    
    // Enumerable mappings
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;
    
    address public manager;
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event TicketUsed(uint256 indexed ticketId);
    
    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can call this");
        _;
    }
    
    constructor() {
        manager = msg.sender;
    }
    
    function setManager(address _manager) external onlyManager {
        manager = _manager;
    }
    
    function mintTicket(
        address to,
        string memory _eventName,
        string memory _seatNumber,
        uint256 _eventDate
    ) external onlyManager returns (uint256) {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        
        tickets[tokenId] = Ticket({
            ticketId: tokenId,
            eventName: _eventName,
            seatNumber: _seatNumber,
            eventDate: _eventDate,
            isUsed: false
        });
        
        _mint(to, tokenId);
        
        return tokenId;
    }
    
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "Cannot mint to zero address");
        require(_owners[tokenId] == address(0), "Token already minted");
        
        _owners[tokenId] = to;
        _balances[to]++;
        
        _addTokenToOwnerEnumeration(to, tokenId);
        _addTokenToAllTokensEnumeration(tokenId);
        
        emit Transfer(address(0), to, tokenId);
    }
    
    function transferFrom(address from, address to, uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Transfer not authorized");
        _transfer(from, to, tokenId);
    }
    
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "Transfer from incorrect owner");
        require(to != address(0), "Transfer to zero address");
        
        _approve(address(0), tokenId);
        
        // CRITICAL: Do enumeration BEFORE changing balances!
        _removeTokenFromOwnerEnumeration(from, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
        
        // THEN update balances and ownership
        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;
        
        emit Transfer(from, to, tokenId);
    }
    
    function approve(address to, uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Approve not authorized");
        _approve(to, tokenId);
    }
    
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }
    
    function setApprovalForAll(address operator, bool approved) external {
        require(operator != msg.sender, "Cannot approve yourself");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_owners[tokenId] != address(0), "Token does not exist");
        return _tokenApprovals[tokenId];
    }
    
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
    
    function markAsUsed(uint256 tokenId) external onlyManager {
        require(_owners[tokenId] != address(0), "Token does not exist");
        require(!tickets[tokenId].isUsed, "Ticket already used");
        tickets[tokenId].isUsed = true;
        emit TicketUsed(tokenId);
    }
    
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Token does not exist");
        return owner;
    }
    
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "Balance query for zero address");
        return _balances[owner];
    }
    
    function getTicket(uint256 tokenId) external view returns (Ticket memory) {
        require(_owners[tokenId] != address(0), "Token does not exist");
        return tickets[tokenId];
    }
    
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }
    
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "Owner index out of bounds");
        return _ownedTokens[owner][index];
    }
    
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "Global index out of bounds");
        return _allTokens[index];
    }
    
    // Enumerable internal functions - FIXED VERSION
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = _balances[to];  // Use _balances directly
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }
    
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // FIXED: Use _balances[from] directly (already decremented in _transfer)
        uint256 lastTokenIndex = _balances[from];
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }
        
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }
    
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }
}