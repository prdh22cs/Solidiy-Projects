// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MyERC20 {

  
    // TOKEN DETAILS
  

    string public name = "MyToken";
    string public symbol = "MTK";
    uint8 public decimals = 18;

    uint256 public totalSupply;
    uint256 public immutable maxSupply;

    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

  
    // EVENTS
  

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

  
    // MODIFIER
  

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

  
    // CONSTRUCTOR
  

    constructor(uint256 _initialSupply, uint256 _maxSupply) {
        owner = msg.sender;

        maxSupply = _maxSupply * 10 ** decimals;

        uint256 initial = _initialSupply * 10 ** decimals;

        require(initial <= maxSupply, "Initial exceeds max supply");

        totalSupply = initial;
        balanceOf[msg.sender] = initial;

        emit Transfer(address(0), msg.sender, initial);
    }

  
    // TRANSFER
  

    function transfer(address _to, uint256 _amount) public returns (bool) {
        require(balanceOf[msg.sender] >= _amount, "Insufficient balance");
        require(_to != address(0), "Invalid address");

        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;

        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

  
    // APPROVE
  

    function approve(address _spender, uint256 _amount) public returns (bool) {
        require(_spender != address(0), "Invalid address");

        allowance[msg.sender][_spender] = _amount;

        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

  
    // TRANSFER FROM
  

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public returns (bool) {

        require(balanceOf[_from] >= _amount, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _amount, "Allowance exceeded");
        require(_to != address(0), "Invalid address");

        balanceOf[_from] -= _amount;
        balanceOf[_to] += _amount;
        allowance[_from][msg.sender] -= _amount;

        emit Transfer(_from, _to, _amount);
        return true;
    }

  
    // MINT (WITH MAX SUPPLY CHECK)
  

    function mint(address _to, uint256 _amount) public onlyOwner {

        uint256 amountWithDecimals = _amount * 10 ** decimals;

        require(totalSupply + amountWithDecimals <= maxSupply, "Max supply reached");

        totalSupply += amountWithDecimals;
        balanceOf[_to] += amountWithDecimals;

        emit Transfer(address(0), _to, amountWithDecimals);
    }

  
    // BURN
  

    function burn(uint256 _amount) public {
        require(balanceOf[msg.sender] >= _amount, "Insufficient balance");

        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;

        emit Transfer(msg.sender, address(0), _amount);
    }

  
    // OWNERSHIP TRANSFER
  

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");

        address oldOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(msg.sender, address(0));
    }
}
