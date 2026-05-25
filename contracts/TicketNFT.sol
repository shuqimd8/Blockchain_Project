// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TicketNFT
 * @author Jasmine & Shuqi - QUT IFB452 Blockchain Project
 * @notice Implements ERC-721 compliant NFT tickets for event management
 * @dev Custom ERC-721 implementation with enumerable extension for ticket tracking
 * 
 * Design Rationale:
 * - Custom implementation over OpenZeppelin to demonstrate understanding of ERC-721 internals
 * - Enumerable extension allows off-chain indexing of all tickets owned by an address
 * - Manager role separation enables marketplace contract to mint tickets (TicketManager.sol)
 */
contract TicketNFT {
    string public name = "EventTicket";
    string public symbol = "TIX";
    
    uint256 private _tokenIdCounter;
    
    /// @notice Ticket metadata structure stored on-chain
    /// @dev On-chain storage chosen over IPFS to enable offline venue verification
    struct Ticket {
        uint256 ticketId;      // Unique identifier matching ERC-721 tokenId
        string eventName;      // Event title (e.g., "Rock Concert 2026")
        string seatNumber;     // Physical seat assignment (e.g., "A1", "B12")
        uint256 eventDate;     // Unix timestamp of event start time
        bool isUsed;           // Marked true after venue entry to prevent re-use
    }
    
    // Core ERC-721 storage
    mapping(uint256 => Ticket) private tickets;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    
    // Enumerable extension storage (allows listing all tickets per owner)
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;
    
    /// @notice Address authorized to mint tickets (TicketManager contract)
    address public manager;
    
    /// @notice Emitted when ticket ownership is transferred
    /// @param from Previous owner (address(0) for minting)
    /// @param to New owner
    /// @param tokenId Unique ticket identifier
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    
    /// @notice Emitted when approval is granted for a specific ticket
    /// @param owner Current ticket owner
    /// @param approved Address authorized to transfer this ticket
    /// @param tokenId Unique ticket identifier
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    
    /// @notice Emitted when operator approval is set for all tickets
    /// @param owner Ticket owner granting approval
    /// @param operator Address being approved/revoked as operator
    /// @param approved True if approved, false if revoked
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    /// @notice Emitted when a ticket is marked as used at venue entry
    /// @param ticketId Unique ticket identifier
    event TicketUsed(uint256 indexed ticketId);
    
    /// @notice Restricts function access to the manager contract
    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can call this");
        _;
    }
    
    /// @notice Initializes contract with deployer as initial manager
    constructor() {
        manager = msg.sender;
    }
    
    /// @notice Updates the manager address (typically set to TicketManager contract)
    /// @dev Used during deployment: deploy TicketNFT first, then call setManager() with TicketManager address
    /// @param _manager New manager address
    function setManager(address _manager) external onlyManager {
        manager = _manager;
    }
    
    /// @notice Mints a new ticket NFT with event metadata
    /// @dev Only callable by manager contract. Increments tokenId counter for each mint.
    /// @param to Address that will receive the ticket (buyer or marketplace contract)
    /// @param _eventName Name of the event
    /// @param _seatNumber Assigned seat identifier
    /// @param _eventDate Unix timestamp of event start time
    /// @return tokenId The unique identifier of the minted ticket
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
    
    /// @notice Internal minting function following ERC-721 standard
    /// @dev Updates ownership, balances, and enumerable mappings
    /// @param to Recipient address (cannot be zero address)
    /// @param tokenId Unique ticket identifier
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "Cannot mint to zero address");
        require(_owners[tokenId] == address(0), "Token already minted");
        
        _owners[tokenId] = to;
        _balances[to]++;
        
        _addTokenToOwnerEnumeration(to, tokenId);
        _addTokenToAllTokensEnumeration(tokenId);
        
        emit Transfer(address(0), to, tokenId);
    }
    
    /// @notice Transfers ticket ownership (ERC-721 standard function)
    /// @dev Caller must be owner or approved operator
    /// @param from Current ticket owner
    /// @param to New ticket owner
    /// @param tokenId Unique ticket identifier
    function transferFrom(address from, address to, uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Transfer not authorized");
        _transfer(from, to, tokenId);
    }
    
    /// @notice Internal transfer function with enumerable updates
    /// @dev CRITICAL: Enumeration updates happen BEFORE balance changes to maintain consistency
    /// @param from Current owner
    /// @param to New owner
    /// @param tokenId Unique ticket identifier
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
    
    /// @notice Approves another address to transfer a specific ticket
    /// @dev Caller must be owner or approved operator
    /// @param to Address being approved (use address(0) to revoke)
    /// @param tokenId Unique ticket identifier
    function approve(address to, uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Approve not authorized");
        _approve(to, tokenId);
    }
    
    /// @notice Internal approval function
    /// @param to Address being approved
    /// @param tokenId Unique ticket identifier
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }
    
    /// @notice Sets operator approval for all caller's tickets
    /// @dev Used by marketplaces to manage user's tickets
    /// @param operator Address being approved as operator
    /// @param approved True to approve, false to revoke
    function setApprovalForAll(address operator, bool approved) external {
        require(operator != msg.sender, "Cannot approve yourself");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    /// @notice Checks if an address is approved operator for an owner
    /// @param owner Ticket owner address
    /// @param operator Potential operator address
    /// @return True if operator is approved
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    
    /// @notice Returns the approved address for a specific ticket
    /// @param tokenId Unique ticket identifier
    /// @return Approved address (address(0) if none)
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_owners[tokenId] != address(0), "Token does not exist");
        return _tokenApprovals[tokenId];
    }
    
    /// @notice Checks if an address is authorized to transfer a ticket
    /// @dev Returns true if spender is owner, approved for this ticket, or operator
    /// @param spender Address to check authorization
    /// @param tokenId Unique ticket identifier
    /// @return True if authorized
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
    
    /// @notice Marks a ticket as used after venue entry
    /// @dev Only manager can call. Prevents ticket reuse and transfers after use.
    /// @param tokenId Unique ticket identifier
    function markAsUsed(uint256 tokenId) external onlyManager {
        require(_owners[tokenId] != address(0), "Token does not exist");
        require(!tickets[tokenId].isUsed, "Ticket already used");
        tickets[tokenId].isUsed = true;
        emit TicketUsed(tokenId);
    }
    
    /// @notice Returns the owner of a ticket (ERC-721 standard)
    /// @param tokenId Unique ticket identifier
    /// @return Owner address
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Token does not exist");
        return owner;
    }
    
    /// @notice Returns the number of tickets owned by an address (ERC-721 standard)
    /// @param owner Address to query
    /// @return Number of tickets owned
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "Balance query for zero address");
        return _balances[owner];
    }
    
    /// @notice Retrieves full ticket metadata
    /// @param tokenId Unique ticket identifier
    /// @return Ticket struct containing all metadata
    function getTicket(uint256 tokenId) external view returns (Ticket memory) {
        require(_owners[tokenId] != address(0), "Token does not exist");
        return tickets[tokenId];
    }
    
    /// @notice Returns total number of tickets minted (Enumerable extension)
    /// @return Total supply of tickets
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }
    
    /// @notice Returns ticket ID owned by address at specific index (Enumerable extension)
    /// @dev Used for off-chain enumeration of user's tickets
    /// @param owner Address to query
    /// @param index Index in owner's token list (0 to balanceOf(owner)-1)
    /// @return tokenId at that index
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "Owner index out of bounds");
        return _ownedTokens[owner][index];
    }
    
    /// @notice Returns ticket ID at global index (Enumerable extension)
    /// @param index Global index (0 to totalSupply()-1)
    /// @return tokenId at that index
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "Global index out of bounds");
        return _allTokens[index];
    }
    
    // Enumerable internal functions - FIXED VERSION
    
    /// @notice Adds ticket to owner's enumerable list
    /// @dev Called during minting and transfers
    /// @param to New owner address
    /// @param tokenId Ticket being added
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = _balances[to];  // Use _balances directly
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }
    
    /// @notice Removes ticket from owner's enumerable list
    /// @dev Called during transfers. Uses swap-and-pop pattern for gas efficiency.
    /// @param from Previous owner address
    /// @param tokenId Ticket being removed
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // FIXED: Use _balances[from] directly (already decremented in _transfer)
        uint256 lastTokenIndex = _balances[from];
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        
        // Swap with last token and pop
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }
        
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }
    
    /// @notice Adds ticket to global enumerable list
    /// @dev Called during minting
    /// @param tokenId Ticket being added
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }
}
