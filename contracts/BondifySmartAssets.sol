--------------------------------------------------------
    --------------------------------------------------------
    struct BondToken {
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        mapping(address => uint256) balance;
    }

    BOND SERIES
    interest rate in basis points (e.g., 500 = 5%)
        uint256 maturity;           total principal issued
        BondToken token;            --------------------------------------------------------
    --------------------------------------------------------
    address public owner;
    IERC20 public collateral;  --------------------------------------------------------
    --------------------------------------------------------
    event BondSeriesCreated(
        uint256 indexed id,
        uint256 interestBps,
        uint256 maturity,
        string name,
        string symbol
    );

    event BondPurchased(
        uint256 indexed id,
        address indexed buyer,
        uint256 principal,
        uint256 tokensMinted
    );

    event BondRedeemed(
        uint256 indexed id,
        address indexed redeemer,
        uint256 principal,
        uint256 interest,
        uint256 payout
    );

    MODIFIERS
    --------------------------------------------------------
    --------------------------------------------------------
    constructor(address _collateral) {
        owner = msg.sender;
        collateral = IERC20(_collateral);
    }

    CREATE A NEW BOND SERIES
    --------------------------------------------------------
    --------------------------------------------------------
    function _mint(BondToken storage t, address to, uint256 amount) internal {
        t.totalSupply += amount;
        t.balance[to] += amount;
    }

    function _burn(BondToken storage t, address from, uint256 amount) internal {
        require(t.balance[from] >= amount, "Not enough tokens");
        t.balance[from] -= amount;
        t.totalSupply -= amount;
    }

    BUY BONDS (MINT TOKENIZED BOND ASSETS)
    Move principal to contract
        collateral.transferFrom(msg.sender, address(this), principal);

        --------------------------------------------------------
    --------------------------------------------------------
    function redeemBonds(uint256 id, uint256 amount)
        external
        validSeries(id)
    {
        BondSeries storage s = series[id];
        require(block.timestamp >= s.maturity, "Not matured");

        _burn(s.token, msg.sender, amount);

        --------------------------------------------------------
    --------------------------------------------------------
    function bondBalance(uint256 id, address user)
        external
        view
        returns (uint256)
    {
        return series[id].token.balance[user];
    }

    function totalIssued(uint256 id)
        external
        view
        returns (uint256)
    {
        return series[id].totalIssued;
    }

    ADMIN
    // --------------------------------------------------------
    function updateOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}
// 
Contract End
// 
