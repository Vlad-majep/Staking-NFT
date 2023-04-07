// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Staking is ReentrancyGuard {
  using SafeERC20 for IERC20;

// Interface for ERC20 and ERC721
  IERC20 public immutable rewardsToken;
  IERC721 public immutable nftCollection;


// Constructor to define token and NFT collection
  constructor() {
    rewardsToken = IERC20(0xCFd8C915F51B1ba99Ac1f80C57c2F33F8d9E7Dd4);
    nftCollection = IERC721(0xe06359D50700Aa9f37723BF3A89183bBf7F4a941);
  }

  struct StakedToken {
    address staker;
    uint tokenId;
  }

// Information about the Person who stakes
  struct Staker {
    // Amount of NFTs he stakes
    uint amountStaked;

    // What nfts does he stake 
    StakedToken[] stakedTokens;

    // Latest award count time 
    uint timeOfLastUpdate;

    // Calculated, but unclaimed rewards for the User. The rewards are 
    // calculated each time the user writes to the Smart Contract
    uint unclaimedRewards;
  }

  // How many tokens will be given per hour (wei)
  uint private rewardsPerHour = 10 ** 18 ;

  // Mapping that shows information about the address
  mapping (address => Staker) public stakers;

  // Mapping that binds the ID token to the address
  // To return it to its owner
  mapping (uint => address) public stakerAddress;

  function stake(uint _tokenId) external nonReentrant {
    // If the user already stakes nft then the rewards will be increased
    if(stakers[msg.sender].amountStaked > 0) {
      uint rewards = calculateRewards(msg.sender);
      stakers[msg.sender].unclaimedRewards += rewards;
    }

    // Check if the user has the given nft 
    require(
      nftCollection.ownerOf(_tokenId) == msg.sender, 
      "You don't own this token!"
      );

    // Transfer of the token from the owner to the smart contract
    nftCollection.transferFrom(msg.sender, address(this), _tokenId);

    // Create a token stake
    StakedToken memory stakedTokens = StakedToken(msg.sender, _tokenId);

    // Add the NFT token to the array
    stakers[msg.sender].stakedTokens.push(stakedTokens);

    // Add the number of staked NFTs to the owner
    stakers[msg.sender].amountStaked++;

    // Update token owner mapping
    stakerAddress[_tokenId] = msg.sender;

    // Update the time of the last staking update
    stakers[msg.sender] .timeOfLastUpdate = block.timestamp;
  }

  function withdraw(uint _tokenId) external nonReentrant {
    // Check if the sender has staked nft
    require(
      stakers[msg.sender].amountStaked > 0,
      "You don't have tokens staked"
    );

    // Check for token owner 
    require(stakerAddress[_tokenId] == msg.sender, "You don't own this token");

    // Looking for token ID from the list
    uint index = 0;
    for (uint i = 0; i < stakers[msg.sender].stakedTokens.length; i++) {
      if (stakers[msg.sender].stakedTokens[i].tokenId == _tokenId){
        index = i;
        break;
      }
    }

    // Remove this token from the list of staked nft
    stakers[msg.sender].stakedTokens[index].staker = address(0);

    // Decrease the number of nft staked
    stakers[msg.sender].amountStaked--;

    // Remove from mapping nft that no longer stakes
    stakerAddress[_tokenId] = address(0);

    // Send nft back to owner 
    nftCollection.transferFrom(address(this), msg.sender, _tokenId);
  }

  function claimRewards() external {
    uint rewards = calculateRewards(msg.sender) + stakers[msg.sender].unclaimedRewards;

    require(rewards > 0, "You have no rewards to claim");

    stakers[msg.sender].timeOfLastUpdate = block.timestamp;
    stakers[msg.sender].unclaimedRewards = 0;

    rewardsToken.safeTransfer(msg.sender, rewards);
  }

  function calculateRewards (address _staker) internal view returns(uint _rewards) {
    return (((
      ((block.timestamp - stakers[_staker].timeOfLastUpdate)
        * stakers[_staker].amountStaked)
      )* rewardsPerHour) / 3600 );
  }

  function avaibleRewards(address _staker) public view returns(uint) {
    uint rewards = calculateRewards(_staker) + stakers[_staker].unclaimedRewards;
    return rewards;
  }

  function getStakedTokens(address _user) public view returns(StakedToken[] memory){
    if (stakers[_user].amountStaked > 0) {
      StakedToken[] memory _stakedTokens = new StakedToken[](stakers[_user].amountStaked);
      uint _index = 0;

      for(uint j = 0; j < stakers[_user].stakedTokens.length; j++) {
        if (stakers[_user].stakedTokens[j].staker != address(0)) {
          _stakedTokens[_index] = stakers[_user].stakedTokens[j];
          _index++;
        }
      }

      return _stakedTokens;
    }

    else {
      return new StakedToken[](0);
    }
  }  
}