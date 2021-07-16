// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../Fakes/IRabbit.sol";
import "./IFairLaunch.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";	
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "hardhat/console.sol";

// FairLaunch is a smart contract for distributing Rabbit by asking user to stake the ERC20-based token.
contract FairLaunch is IFairLaunch {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  
    uint256 constant GLO_VAL = 1e12;
    
  // Info of each user.
  struct UserInfo {
    uint256 amount; // How many Staking tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
    uint256 bonusDebt; // Last block that user exec something to the pool.
    address fundedBy; // Funded by who?
    //
    // We do some fancy math here. Basically, any point in time, the amount of Rabbits
    // entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (user.amount * pool.accRabbitPerShare) - user.rewardDebt
    //
    // Whenever a user deposits or withdraws Staking tokens to a pool. Here's what happens:
    //   1. The pool's `accRabbitPerShare` (and `lastRewardBlock`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.
  }
  
// Info of each pool.
  struct PoolInfo {
    address stakeToken; // Address of Staking token contract.
    uint256 allocPoint; // How many allocation points assigned to this pool. Rabbits to distribute per block.
    uint256 lastRewardBlock; // Last block number that Rabbits distribution occurs.
    uint256 accRabbitPerShare; // Accumulated Rabbits per share, times 1e12. See below.
    uint256 accRabbitPerShareTilBonusEnd; // Accumated Rabbits per share until Bonus End.
  }
  
// The Rabbit TOKEN!
  address public rabbit;
  // Dev address.
  address public devaddr;
  // Rabbit tokens created per block.
  uint256 public rabbitPerBlock;
  // Bonus muliplier for early rabbit makers.
  uint256 public bonusMultiplier;
  // Block number when bonus rabbit period ends.
  uint256 public bonusEndBlock;

    // Info of each pool.
  PoolInfo[] public poolInfo;
  // Info of each user that stakes Staking tokens.
  mapping(uint256 => mapping(address => UserInfo)) override public userInfo;
  // Total allocation poitns. Must be the sum of all allocation points in all pools.
  uint256 public totalAllocPoint;
  // The block number when rabbit mining starts.
  uint256 public startBlock;

  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
  event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetDevAddress(address indexed devAddr);
    event SetRabbitPerBlock(uint256 indexed rabbitPerBlock);
    event ManualMint(address indexed to,uint256 indexed amount);
    
  constructor(
    address _rabbit,
    address _devaddr,
    uint256 _rabbitPerBlock,
    uint256 _startBlock,
    uint256 _bonusEndBlock
  ) public {
    bonusMultiplier = 0;
    totalAllocPoint = 0;
    rabbit = _rabbit;
    devaddr = _devaddr;
    rabbitPerBlock = _rabbitPerBlock;
    bonusEndBlock = _bonusEndBlock;
    startBlock = _startBlock;
  }
  
    // Update dev address by the previous dev.
  function setDev(address _devaddr) public   {
    require(_devaddr != address(0));
    devaddr = _devaddr;
    emit SetDevAddress(_devaddr);
  }
  
  function setRabbitPerBlock(uint256 _rabbitPerBlock) public {
    rabbitPerBlock = _rabbitPerBlock;
    emit SetRabbitPerBlock(_rabbitPerBlock);
  }
  
    // Set Bonus params. bonus will start to accu on the next block that this function executed
  // See the calculation and counting in test file.
  function setBonus(
    uint256 _bonusMultiplier,
    uint256 _bonusEndBlock
    ) public {
    require(_bonusEndBlock > block.number, "setBonus: bad bonusEndBlock");
    require(_bonusMultiplier > 1, "setBonus: bad bonusMultiplier");
    bonusMultiplier = _bonusMultiplier;
    bonusEndBlock = _bonusEndBlock;
  }

  // Add a new lp to the pool. Can only be called by the owner.
  function addPool(
    uint256 _allocPoint,
    address _stakeToken,
    bool _withUpdate
  ) public override {
    if (_withUpdate) {
      massUpdatePools();
    }
    require(_stakeToken != address(0), "add: not stakeToken addr");
    require(!isDuplicatedPool(_stakeToken), "add: stakeToken dup");
    uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
    totalAllocPoint = totalAllocPoint.add(_allocPoint);
    poolInfo.push(
      PoolInfo({
        stakeToken: _stakeToken,
        allocPoint: _allocPoint,
        lastRewardBlock: lastRewardBlock,
        accRabbitPerShare: 0,
        accRabbitPerShareTilBonusEnd: 0
      })
    );
  }
  
    // Update the given pool's rabbit allocation point. Can only be called by the owner.
  function setPool(
    uint256 _pid,
    uint256 _allocPoint,
    bool _withUpdate
  ) public override  {
    if (_withUpdate) {
      massUpdatePools();
    }
    totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
    poolInfo[_pid].allocPoint = _allocPoint;
  }
  
  function isDuplicatedPool(address _stakeToken) public view returns (bool) {
    uint256 length = poolInfo.length;
    for (uint256 _pid = 0; _pid < length; _pid++) {
      if(poolInfo[_pid].stakeToken == _stakeToken) return true;
    }
    return false;
  }
  
  function poolLength() external override view returns (uint256) {
    return poolInfo.length;
  }

  function manualMint(address _to, uint256 _amount) public  {
    IRabbit(address(rabbit)).mint(_to, _amount);
    emit ManualMint(_to,_amount);
  }
  
    // Return reward multiplier over the given _from to _to block.
  function getMultiplier(uint256 _lastRewardBlock, uint256 _currentBlock) public view returns (uint256) {
      require(_lastRewardBlock <= _currentBlock, "Block range exceeded!");
    if (_currentBlock <= bonusEndBlock) {
      return _currentBlock.sub(_lastRewardBlock).mul(bonusMultiplier);
    }
    if (_lastRewardBlock >= bonusEndBlock) {
      return _currentBlock.sub(_lastRewardBlock);
    }
    // This is the case where bonusEndBlock is in the middle of _lastRewardBlock and _currentBlock block.
    return bonusEndBlock.sub(_lastRewardBlock).mul(bonusMultiplier).add(_currentBlock.sub(bonusEndBlock));
  }
  
// View function to see pending RABBITs on frontend.
  function pendingRabbit(uint256 _pid, address _user) external override view returns (uint256) {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    uint256 accRabbitPerShare = pool.accRabbitPerShare;
    uint256 lpSupply = IERC20(pool.stakeToken).balanceOf(address(this));
    if (block.number > pool.lastRewardBlock && lpSupply != 0) {
      uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
      uint256 rabbitReward = multiplier.mul(rabbitPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
      accRabbitPerShare = accRabbitPerShare.add(rabbitReward.mul(GLO_VAL).div(lpSupply));
    }
    return user.amount.mul(accRabbitPerShare).div(GLO_VAL).sub(user.rewardDebt);
  }
  
    // Update reward vairables for all pools. Be careful of gas spending!
  function massUpdatePools() public {
    uint256 length = poolInfo.length;
    for (uint256 pid = 0; pid < length; ++pid) {
      updatePool(pid);
    }
  }

  // Update reward variables of the given pool to be up-to-date.
  function updatePool(uint256 _pid) public override {
    PoolInfo storage pool = poolInfo[_pid];
    if (block.number <= pool.lastRewardBlock) {
      return;
    }
    uint256 lpSupply = IERC20(pool.stakeToken).balanceOf(address(this));
    if (lpSupply == 0) {
      pool.lastRewardBlock = block.number;
      return;
    }
    uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
    uint256 rabbitReward = multiplier.mul(rabbitPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
    IRabbit(rabbit).mint(devaddr, rabbitReward.mul(20).div(100));
    IRabbit(rabbit).mint(address(this), rabbitReward);
    pool.accRabbitPerShare = pool.accRabbitPerShare.add(rabbitReward.mul(GLO_VAL).div(lpSupply));
    // update accRabbitPerShareTilBonusEnd
    if (block.number <= bonusEndBlock) {
      pool.accRabbitPerShareTilBonusEnd = pool.accRabbitPerShare;
    }
    if(block.number > bonusEndBlock && pool.lastRewardBlock < bonusEndBlock) {
      uint256 RabbitBonusPortion = bonusEndBlock.sub(pool.lastRewardBlock).mul(bonusMultiplier).mul(rabbitPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
      pool.accRabbitPerShareTilBonusEnd = pool.accRabbitPerShareTilBonusEnd.add(RabbitBonusPortion.mul(GLO_VAL).div(lpSupply));
    }
    pool.lastRewardBlock = block.number;
  }
  
    // Deposit Staking tokens to FairLaunchToken for Rabbit allocation.
  function deposit(address _for, uint256 _pid, uint256 _amount) public override {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_for];
    if (user.fundedBy != address(0)) require(user.fundedBy == msg.sender, "bad sof");
    require(pool.stakeToken != address(0), "deposit: not accept deposit");
    updatePool(_pid);
    if (user.amount > 0) _harvest(_for, _pid);
    if (user.fundedBy == address(0)) user.fundedBy = msg.sender;
    IERC20(pool.stakeToken).safeTransferFrom(address(msg.sender), address(this), _amount);
    user.amount = user.amount.add(_amount);
    user.rewardDebt = user.amount.mul(pool.accRabbitPerShare).div(GLO_VAL);
    user.bonusDebt = user.amount.mul(pool.accRabbitPerShareTilBonusEnd).div(GLO_VAL);


    emit Deposit(msg.sender, _pid, _amount);
  }

  // Withdraw Staking tokens from FairLaunchToken.
  function withdraw(address _for, uint256 _pid, uint256 _amount) public override {
    _withdraw(_for, _pid, _amount);
  }

  function withdrawAll(address _for, uint256 _pid) public override {
    _withdraw(_for, _pid, userInfo[_pid][_for].amount);
  }

  function _withdraw(address _for, uint256 _pid, uint256 _amount) internal {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_for];
    require(user.fundedBy == msg.sender, "only funder");
    require(user.amount >= _amount, "withdraw: not good");
    updatePool(_pid);
    _harvest(_for, _pid);
    user.amount = user.amount.sub(_amount);
    user.rewardDebt = user.amount.mul(pool.accRabbitPerShare).div(GLO_VAL);
    user.bonusDebt = user.amount.mul(pool.accRabbitPerShareTilBonusEnd).div(GLO_VAL);
    if (pool.stakeToken != address(0)) {
      IERC20(pool.stakeToken).safeTransfer(address(msg.sender), _amount);
    }
    emit Withdraw(msg.sender, _pid, user.amount);
  }

  // Harvest Rabbits earn from the pool.
  function harvest(uint256 _pid) public override {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    updatePool(_pid);
    _harvest(msg.sender, _pid);
    user.rewardDebt = user.amount.mul(pool.accRabbitPerShare).div(GLO_VAL);
    user.bonusDebt = user.amount.mul(pool.accRabbitPerShareTilBonusEnd).div(GLO_VAL);
  }

  function _harvest(address _to, uint256 _pid) internal {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_to];
    require(user.amount > 0, "nothing to harvest");
    uint256 pending = user.amount.mul(pool.accRabbitPerShare).div(GLO_VAL).sub(user.rewardDebt);
    require(pending <= IERC20(rabbit).balanceOf(address(this)), "wtf not enough Rabbit");
    safeRabbitTransfer(_to, pending);
  }

  // Withdraw without caring about rewards. EMERGENCY ONLY.
  function emergencyWithdraw(uint256 _pid) override public {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    uint256 amount = user.amount;
    user.amount = 0;
    user.rewardDebt = 0;
    IERC20(pool.stakeToken).safeTransfer(address(msg.sender), amount);
    emit EmergencyWithdraw(msg.sender, _pid, user.amount);
  }

    // Safe Rabbit transfer function, just in case if rounding error causes pool to not have enough Rabbits.
    function safeRabbitTransfer(address _to, uint256 _amount) internal {
        uint256 RabbitBal = IERC20(rabbit).balanceOf(address(this));
        if (_amount > RabbitBal) {
          IERC20(rabbit).transfer(_to, RabbitBal);
        } else {
          IERC20(rabbit).transfer(_to, _amount);
        }
    }

    function getBlock() view external returns(uint256){
        return block.number;
    }

	function getUserAmount(address user) override external view returns (uint256)
	{
		UserInfo storage user = userInfo[0][user];
		return user.amount;
	}
}