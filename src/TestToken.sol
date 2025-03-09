// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

contract TestToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() {
        name = "Test Token";
        symbol = "TEST";
        decimals = 18;
        // 铸造1000000个代币给部署者
        _mint(msg.sender, 1000000 * 10 ** decimals);
    }
    
    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "TestToken: mint to zero address");
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }
    
    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0), "TestToken: transfer to zero address");
        require(balanceOf[msg.sender] >= amount, "TestToken: insufficient balance");
        
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(to != address(0), "TestToken: transfer to zero address");
        require(balanceOf[from] >= amount, "TestToken: insufficient balance");
        require(allowance[from][msg.sender] >= amount, "TestToken: insufficient allowance");
        
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        
        emit Transfer(from, to, amount);
        return true;
    }
    
    // 允许任何人铸造代币(仅用于测试)
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    // 重载mint函数，方便测试时直接铸造给自己
    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}
