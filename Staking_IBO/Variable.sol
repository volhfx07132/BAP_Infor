pragma solidity 0.6.12;

contract DALDALPool{
    address public BSCS_CASTLE_FACTORY;
    bool public hasUserLimit;
    bool public hasPoolLimit;
    bool public isInitialized;
    mapping(ERC20 => uint256) public accTokenPerShare;
    uint256 public stakingBlock;
    uint256 public stakingEndBlock;
    uint256 public unStakingBlock;
    uint256 public unStakingFee;
    uint256 public feePeriod;
    address public feeCollector;
    uint256 public bonusEndBlock;
    uint256 public startBlock;
    uint256 public lastRewardBlock;
    uint256 public poolLimitPerUser;
    uint256 public poolCap;
    bool private isRemovable;
    mapping(ERC20 => uint256) public rewardPerBlock;
    mapping(ERC20 => uint256) public PRECISION_FACTOR;
    ERC20[] public rewardTokens;
    ERC20 public stakedToken;
    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 amount;
        uint256 lastRewardBlock;
        mapping(ERC20 => uint256) rewardDebt;
    }

    bool public poolStakingStatus;

    struct UserStake(){
        address addr;
        uint256 amount;
        uint256 startStakeBlock;
        uint256 endStakeBlock;
    }
    mapping(address => UserStake[]) public stakeDetails;
    uint256 public lockingDuration; // number of block to lock

    constructor() public {
        BSCS_CASTLE_FACTORY = msg.sender;
        poolStakingStatus = true;
    }
    /*
       Unitialize contract
    */
    function initialize(
        ERC20 _stakedToken,
        ERC20[] memory _rewardTokens,
        uint256[] memory _rewardPerBlock,
        uint256[] memory _startEndBlocks,
        uint256[] memory _stakingBlocks,
        uint256 _unStakingBlock,
        uint256[] memory _feeSettings,
        address _feeCollector,
        uint256 _poolLimitPerUser,
        uint256 _poolCap,
        bool _isRemovable,
        address _admin
    ) external {
        require(!isInitialized, "Already initialized");
        require(msg.sender == BSCS_CASTLE_FACTORY, "Not factory");
        require(
            _rewardTokens.length == _rewardPerBlock.length,
            "Mismatch length"
        );

        require(address(_stakedToken) != address(0),"Invalid address");
        require(address(_feeCollector) != address(0),"Invalid address");
        require(address(_admin) != address(0),"Invalid address");

        // Make this contract initialized
        isInitialized = true;

        stakedToken = _stakedToken;
        rewardTokens = _rewardTokens;
        startBlock = _startEndBlocks[0];
        bonusEndBlock = _startEndBlocks[1];

        require(
            _stakingBlocks[0] < _stakingBlocks[1],
            "Staking block exceeds end staking block"
        );
        stakingBlock = _stakingBlocks[0];
        stakingEndBlock = _stakingBlocks[1];
        unStakingBlock = _unStakingBlock;
        unStakingFee = _feeSettings[0];
        feePeriod = _feeSettings[1];
        feeCollector = _feeCollector;
        isRemovable = _isRemovable;

        if (_poolLimitPerUser > 0) {
            hasUserLimit = true;
            poolLimitPerUser = _poolLimitPerUser;
        }
        if (_poolCap > 0) {
            hasPoolLimit = true;
            poolCap = _poolCap;
        }

        uint256 decimalsRewardToken;
        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            decimalsRewardToken = uint256(_rewardTokens[i].decimals());
            require(decimalsRewardToken < 30, "Must be inferior to 30");
            PRECISION_FACTOR[_rewardTokens[i]] = uint256(
                10**(uint256(30).sub(decimalsRewardToken))
            );
            rewardPerBlock[_rewardTokens[i]] = _rewardPerBlock[i];
        }

        // Set the lastRewardBlock as the startBlock
        lastRewardBlock = startBlock;

        // Transfer ownership to the admin address who becomes owner of the contract
        transferOwnership(_admin);
    }

    //getLastStakingBlock:: get lastStakingBlock information of user owner address (_user);
    //getFeeCollecto: get address feeCollector
    //getFeePeriod
    //getUnStakingFee: get unStakingFee
    //getStakingEndBlock: get Fee Staking Finish
    //getUnStakingFee => get StakingEndBlock;
    //getAllPreFactor => get all array PRECISION_FACTOR[_tokens[i]] of each other token
    //getAllAccTokenPerShared => get add value account token per share
    //getAllRewardPerBlocl => get all rewardPerBlock each other address token ERC20 provided
    //getUserDebtByToken: user address owner by user and all address of Token ERC20 => 
    //                    get token debt(number token reward for user)
    //getUserDebt: user address owner by user and all address of Token ERC20 => 
    //             get token debt(number token reward for user
    //             get All address of token rewardTokens
    //findElementPosition: find element of position: Find address token token inside to 
    //                     _array => true/false 
    //removeElement: remove address of token ERC20 inside _array => return true == delete and return false == not exits
    //removeRewardToken