//SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./sSENnonOFT.sol"; // Import the sSen contract
import "./libraries/ReentrancyGuard.sol";

contract SenecaRewards is ReentrancyGuard {
    using BoringERC20 for IERC20;

    IERC20 public rewardToken; // The token to be used for rewards (e.g., WETH)
    sSen public stakingContract; // Instance of your sSen contract
    address public owner;

    mapping(uint256 => uint256) public dailyDeposits; // Mapping of day to total tokens deposited
    mapping(address => uint256) public lastClaimedDay; // Mapping of user to the last day they claimed a reward
    mapping(uint256 => mapping(address => bool)) private hasClaimed; // Mapping of day and user to boolean for whether they have claimed for that day

    mapping(uint256 => uint256) public rewardDepositTimestamps; // Timestamps of reward deposits per day
    mapping(uint256 => mapping(address => bool)) private ineligibleForDay;
    mapping(uint256 => uint256) public totalIneligibleSharesPerDay;
    mapping(uint256 => mapping(address => uint256)) public userEligibleRewards; // Mapping of day and user to the amount of reward eligible for.


    bool public halted = false;

    uint256 public constant COOLDOWN_PERIOD = 1 minutes;
    uint256 public startTime; // Timestamp of the first deposit
    uint256 public DURATION = 86400; // Define a day in seconds
    mapping(uint256 => uint256) public activeShares; // Active shares per day


    event RewardClaimed(address indexed user, uint256 day, uint256 amount);
    event RewardsDeposited(uint256 day, uint256 amount);


    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    modifier whenNotHalted() {
        require(!halted, "Contract is halted");
        _;
    }

    constructor(IERC20 _rewardToken, sSen _stakingContract) public {
        rewardToken = _rewardToken;
        stakingContract = _stakingContract;
        owner = msg.sender; 
    }

    receive() external payable {}

    function depositRewards(uint256 amount) external onlyOwner {
        if (startTime == 0) {
            startTime = block.timestamp;
        }
        uint256 currentDay = getCurrentDay();
        rewardToken.safeTransferFrom(msg.sender, address(this), amount);
        dailyDeposits[currentDay] += amount;
        rewardDepositTimestamps[currentDay] = block.timestamp;
        updateActiveShares(currentDay);
        
        address[] memory stakers = stakingContract.loopThroughAllStakers();
        uint256 totalEligibleShares = 0;

        for (uint i = 0; i < stakers.length; i++) {
            if (stakingContract.overCooldownPeriod(stakers[i])) {
                totalEligibleShares += stakingContract.userShares(stakers[i]);
            }
        }

        // Calculate and store eligible reward for each staker
        for (uint i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            if (stakingContract.overCooldownPeriod(staker)) {
                uint256 userShares = stakingContract.userShares(staker);
                uint256 eligibleReward = (amount * userShares) / totalEligibleShares;
                userEligibleRewards[currentDay][staker] += eligibleReward;
            }
        }

        emit RewardsDeposited(currentDay, amount);
    }

    // Function to calculate the current day based on the elapsed time
    function getCurrentDay() public view returns (uint256) {
        if (startTime == 0) {
            return 0; // If no deposit has been made yet
        }
        return (block.timestamp - startTime) / DURATION;
    }

    function claimReward(uint256 day) external nonReentrant whenNotHalted {
        require(dailyDeposits[day] > 0, "No rewards deposited for this day");
        require(!hasClaimed[day][msg.sender], "Reward already claimed for this day");
        require(day <= getCurrentDay(), "Cannot claim for future days");

        uint256 reward = userEligibleRewards[day][msg.sender];

        hasClaimed[day][msg.sender] = true;
        lastClaimedDay[msg.sender] = day;
        rewardToken.safeTransfer(msg.sender, reward);

        emit RewardClaimed(msg.sender, day, reward);
    }

    function calculateReward(uint256 day, uint256 userShares) private view returns (uint256) {
        uint256 dailyReward = dailyDeposits[day];
        uint256 totalIneligibleShares = totalIneligibleSharesPerDay[day];
        uint256 eligibleShares = activeShares[day] - totalIneligibleShares;

        if (eligibleShares == 0) {
            return 0; // Prevent division by zero
        }
        return (dailyReward * userShares) / eligibleShares;
    }

    function claimAllRewards() external nonReentrant whenNotHalted {
        uint256 currentDay = getCurrentDay();
        uint256 totalReward = 0;

        // Check if there are any rewards to be claimed
        bool hasRewardsToClaim = false;
        for (uint256 day = lastClaimedDay[msg.sender]; day <= currentDay; day++) {
            if (!hasClaimed[day][msg.sender] && dailyDeposits[day] > 0 && stakingContract.overCooldownPeriod(msg.sender)) {
                uint256 reward = userEligibleRewards[day][msg.sender];
                if (reward > 0) {
                    hasRewardsToClaim = true;
                    break;
                }
            }
        }

        // Revert if no rewards to claim
        require(hasRewardsToClaim, "No rewards to claim");

        // Claim rewards logic
        for (uint256 day = lastClaimedDay[msg.sender]; day <= currentDay; day++) {
            if (!hasClaimed[day][msg.sender] && dailyDeposits[day] > 0 && stakingContract.overCooldownPeriod(msg.sender)) {
                uint256 reward = userEligibleRewards[day][msg.sender];
                if (reward > 0) {
                    totalReward += reward;
                    hasClaimed[day][msg.sender] = true;
                    emit RewardClaimed(msg.sender, day, reward);
                }
            }
        }

        if (totalReward > 0) {
            rewardToken.safeTransfer(msg.sender, totalReward);
        }
        lastClaimedDay[msg.sender] = currentDay;
    }

    function updateActiveShares(uint256 day) private {
        uint256 totalActiveShares = 0;
        uint256 totalIneligibleShares = 0;

        address[] memory stakers = stakingContract.loopThroughAllStakers();

        for (uint i = 0; i < stakers.length; i++) {
            uint256 userShares = stakingContract.userShares(stakers[i]);
            if (stakingContract.overCooldownPeriod(stakers[i])) {
                totalActiveShares += userShares;
            } else {
                totalIneligibleShares += userShares;
            }
        }
        activeShares[day] = totalActiveShares;
        totalIneligibleSharesPerDay[day] = totalIneligibleShares;
        uint256 totalSharesForDay = totalActiveShares + totalIneligibleShares;
        activeShares[day] = totalSharesForDay;
    }

    function getEligibleReward(address user) public view returns (uint256 totalReward) {
        uint256 currentDay = getCurrentDay();
        totalReward = 0;

        for (uint256 day = lastClaimedDay[user]; day <= currentDay; day++) {
            if(!hasClaimed[day][user]){
                totalReward += userEligibleRewards[day][user];
            }
        }
        return totalReward;
    }

    function halt() public onlyOwner {
        halted = true;
    }

    function resume() public onlyOwner {
        halted = false;
    }

    function rescueRewardTokens() public onlyOwner {
        require(halted, "Contract is not halted");
        uint256 balance = rewardToken.balanceOf(address(this));
        rewardToken.safeTransfer(owner, balance);
    }

    function withdrawStuckEth(address toAddr) external onlyOwner {
        (bool success, ) = toAddr.call{
            value: address(this).balance
        } ("");
        require(success);
    }

    function transferOwnership(address newAddress) public onlyOwner {
        owner = newAddress;
    }

    function updateDuration(uint256 newDuration) public onlyOwner {
        DURATION = newDuration;
    }

}
