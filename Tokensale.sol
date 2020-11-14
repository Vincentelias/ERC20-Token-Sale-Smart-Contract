pragma solidity ^0.4.21;


// Simple interface to sell any type of token
interface IERC20Token {
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract TokenSale {
    IERC20Token public tokenContract;
    uint256 public price;
    address owner;

    // Token decimals
    uint256 decimals;

    uint256 public tokensSold;

    event Sold(address buyer, uint256 amount);

    constructor(IERC20Token _tokenContract, uint256 _price, uint256 _decimals) public {
        owner = msg.sender;
        tokenContract = _tokenContract;
        price = _price;
        decimals = _decimals;
    }

    // Safe multiply to protect against integer overflows
    function safeMultiply(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        } else {
            uint256 c = a * b;
            assert(c / a == b);
            return c;
        }
    }

    function buyTokens(uint256 numberOfTokens) public payable {

        //the ETH value of the transaction should be the the same as token price * numberOfTokens
        require(msg.value == safeMultiply(numberOfTokens, price));

        uint256 scaledAmount = safeMultiply(numberOfTokens,
            uint256(10) ** decimals);

        require(tokenContract.balanceOf(this) >= scaledAmount);

        emit Sold(msg.sender, numberOfTokens);
        tokensSold += numberOfTokens;

        require(tokenContract.transfer(msg.sender, scaledAmount));
    }

    //Owner can always remove liquidity from the contract
    function retrieveLiquidity() public {
        require(msg.sender == owner);
        msg.sender.transfer(address(this).balance);
    }


    function endSale() public {
        require(msg.sender == owner);

        // Send unsold tokens to the owner.
        require(tokenContract.transfer(owner, tokenContract.balanceOf(this)));

        msg.sender.transfer(address(this).balance);
    }
}