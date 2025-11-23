// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Bondify Smart Assets
 * @dev Smart contract for tokenizing and managing bonds as digital assets
 */
contract BondifySmartAssets {
    
    struct Bond {
        uint256 bondId;
        address issuer;
        string bondName;
        uint256 faceValue;
        uint256 couponRate; // In basis points (e.g., 500 = 5%)
        uint256 maturityDate;
        uint256 issueDate;
        uint256 totalSupply;
        uint256 availableSupply;
        bool isActive;
    }
    
    struct BondHolder {
        uint256 quantity;
        uint256 purchaseDate;
        uint256 lastCouponClaim;
    }
    
    // State variables
    uint256 private bondCounter;
    mapping(uint256 => Bond) public bonds;
    mapping(uint256 => mapping(address => BondHolder)) public bondHoldings;
    mapping(address => uint256[]) private userBonds;
    
    // Events
    event BondIssued(uint256 indexed bondId, address indexed issuer, string bondName, uint256 faceValue);
    event BondPurchased(uint256 indexed bondId, address indexed buyer, uint256 quantity);
    event CouponClaimed(uint256 indexed bondId, address indexed holder, uint256 amount);
    event BondRedeemed(uint256 indexed bondId, address indexed holder, uint256 quantity);
    event BondTransferred(uint256 indexed bondId, address indexed from, address indexed to, uint256 quantity);
    
    /**
     * @dev Function 1: Issue a new bond
     * @param _bondName Name of the bond
     * @param _faceValue Face value of each bond unit
     * @param _couponRate Annual coupon rate in basis points
     * @param _maturityDate Maturity date as Unix timestamp
     * @param _totalSupply Total number of bond units to issue
     */
    function issueBond(
        string memory _bondName,
        uint256 _faceValue,
        uint256 _couponRate,
        uint256 _maturityDate,
        uint256 _totalSupply
    ) external returns (uint256) {
        require(_faceValue > 0, "Face value must be greater than 0");
        require(_maturityDate > block.timestamp, "Maturity date must be in the future");
        require(_totalSupply > 0, "Total supply must be greater than 0");
        
        bondCounter++;
        
        bonds[bondCounter] = Bond({
            bondId: bondCounter,
            issuer: msg.sender,
            bondName: _bondName,
            faceValue: _faceValue,
            couponRate: _couponRate,
            maturityDate: _maturityDate,
            issueDate: block.timestamp,
            totalSupply: _totalSupply,
            availableSupply: _totalSupply,
            isActive: true
        });
        
        emit BondIssued(bondCounter, msg.sender, _bondName, _faceValue);
        return bondCounter;
    }
    
    /**
     * @dev Function 2: Purchase bonds
     * @param _bondId ID of the bond to purchase
     * @param _quantity Number of bond units to purchase
     */
    function purchaseBond(uint256 _bondId, uint256 _quantity) external payable {
        Bond storage bond = bonds[_bondId];
        require(bond.isActive, "Bond is not active");
        require(_quantity > 0, "Quantity must be greater than 0");
        require(_quantity <= bond.availableSupply, "Insufficient bond supply");
        require(msg.value >= bond.faceValue * _quantity, "Insufficient payment");
        
        if (bondHoldings[_bondId][msg.sender].quantity == 0) {
            userBonds[msg.sender].push(_bondId);
        }
        
        bondHoldings[_bondId][msg.sender].quantity += _quantity;
        bondHoldings[_bondId][msg.sender].purchaseDate = block.timestamp;
        bondHoldings[_bondId][msg.sender].lastCouponClaim = block.timestamp;
        
        bond.availableSupply -= _quantity;
        
        payable(bond.issuer).transfer(msg.value);
        
        emit BondPurchased(_bondId, msg.sender, _quantity);
    }
    
    /**
     * @dev Function 3: Claim coupon payment
     * @param _bondId ID of the bond
     */
    function claimCoupon(uint256 _bondId) external {
        Bond storage bond = bonds[_bondId];
        BondHolder storage holder = bondHoldings[_bondId][msg.sender];
        
        require(holder.quantity > 0, "No bonds held");
        require(bond.isActive, "Bond is not active");
        require(block.timestamp < bond.maturityDate, "Bond has matured");
        
        uint256 timeElapsed = block.timestamp - holder.lastCouponClaim;
        require(timeElapsed >= 365 days, "Coupon not yet claimable");
        
        uint256 couponAmount = (bond.faceValue * holder.quantity * bond.couponRate) / 10000;
        holder.lastCouponClaim = block.timestamp;
        
        payable(msg.sender).transfer(couponAmount);
        
        emit CouponClaimed(_bondId, msg.sender, couponAmount);
    }
    
    /**
     * @dev Function 4: Redeem matured bonds
     * @param _bondId ID of the bond to redeem
     */
    function redeemBond(uint256 _bondId) external {
        Bond storage bond = bonds[_bondId];
        BondHolder storage holder = bondHoldings[_bondId][msg.sender];
        
        require(holder.quantity > 0, "No bonds to redeem");
        require(block.timestamp >= bond.maturityDate, "Bond has not matured yet");
        
        uint256 redemptionAmount = bond.faceValue * holder.quantity;
        uint256 quantity = holder.quantity;
        
        holder.quantity = 0;
        
        payable(msg.sender).transfer(redemptionAmount);
        
        emit BondRedeemed(_bondId, msg.sender, quantity);
    }
    
    /**
     * @dev Function 5: Transfer bonds to another address
     * @param _bondId ID of the bond
     * @param _to Recipient address
     * @param _quantity Number of bonds to transfer
     */
    function transferBond(uint256 _bondId, address _to, uint256 _quantity) external {
        require(_to != address(0), "Invalid recipient address");
        BondHolder storage senderHolding = bondHoldings[_bondId][msg.sender];
        require(senderHolding.quantity >= _quantity, "Insufficient bond balance");
        
        if (bondHoldings[_bondId][_to].quantity == 0) {
            userBonds[_to].push(_bondId);
        }
        
        senderHolding.quantity -= _quantity;
        bondHoldings[_bondId][_to].quantity += _quantity;
        bondHoldings[_bondId][_to].purchaseDate = block.timestamp;
        bondHoldings[_bondId][_to].lastCouponClaim = block.timestamp;
        
        emit BondTransferred(_bondId, msg.sender, _to, _quantity);
    }
    
    /**
     * @dev Function 6: Get bond details
     * @param _bondId ID of the bond
     */
    function getBondDetails(uint256 _bondId) external view returns (
        address issuer,
        string memory bondName,
        uint256 faceValue,
        uint256 couponRate,
        uint256 maturityDate,
        uint256 availableSupply,
        bool isActive
    ) {
        Bond memory bond = bonds[_bondId];
        return (
            bond.issuer,
            bond.bondName,
            bond.faceValue,
            bond.couponRate,
            bond.maturityDate,
            bond.availableSupply,
            bond.isActive
        );
    }
    
    /**
     * @dev Function 7: Get bondholder balance
     * @param _bondId ID of the bond
     * @param _holder Address of the bondholder
     */
    function getBondBalance(uint256 _bondId, address _holder) external view returns (uint256) {
        return bondHoldings[_bondId][_holder].quantity;
    }
    
    /**
     * @dev Function 8: Calculate pending coupon
     * @param _bondId ID of the bond
     * @param _holder Address of the bondholder
     */
    function calculatePendingCoupon(uint256 _bondId, address _holder) external view returns (uint256) {
        Bond memory bond = bonds[_bondId];
        BondHolder memory holder = bondHoldings[_bondId][_holder];
        
        if (holder.quantity == 0) return 0;
        
        uint256 timeElapsed = block.timestamp - holder.lastCouponClaim;
        if (timeElapsed < 365 days) return 0;
        
        return (bond.faceValue * holder.quantity * bond.couponRate) / 10000;
    }
    
    /**
     * @dev Function 9: Get all bonds owned by an address
     * @param _holder Address of the bondholder
     */
    function getUserBonds(address _holder) external view returns (uint256[] memory) {
        return userBonds[_holder];
    }
    
    /**
     * @dev Function 10: Deactivate a bond (only issuer)
     * @param _bondId ID of the bond to deactivate
     */
    function deactivateBond(uint256 _bondId) external {
        Bond storage bond = bonds[_bondId];
        require(msg.sender == bond.issuer, "Only issuer can deactivate");
        require(bond.isActive, "Bond is already inactive");
        
        bond.isActive = false;
    }
    
    /**
     * @dev Get total number of bonds issued
     */
    function getTotalBonds() external view returns (uint256) {
        return bondCounter;
    }
    
    /**
     * @dev Fallback function to receive Ether
     */
    receive() external payable {}
}