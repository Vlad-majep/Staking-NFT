// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Staking is ReentrancyGuard {
  using SafeERC20 for IERC20;

  // Интерфейс для ERC20 and ERC721
  IERC20 public immutable rewardsToken;
  IERC721 public immutable nftCollection;


  // Конструктор для определения токена и НФТ колекции 
  constructor() {
    rewardsToken = IERC20(0xCFd8C915F51B1ba99Ac1f80C57c2F33F8d9E7Dd4);
    nftCollection = IERC721(0xe06359D50700Aa9f37723BF3A89183bBf7F4a941);
  }

  struct StakedToken {
    address staker;
    uint tokenId;
  }

  // Информация о Человеке который стейкает 
  struct Staker {
    // Кол-во нфт которых он стейкает
    uint amountStaked;

    // Какие нфт он стейкает 
    StakedToken[] stakedTokens;

    // Последнее время подсчета наград 
    uint timeOfLastUpdate;

    // Calculated, but unclaimed rewards for the User. The rewards are 
    // calculated each time the user writes to the Smart Contract
    uint unclaimedRewards;
  }

  // Сколько будет даваться токенов в час (wei)
  uint private rewardsPerHour = 10 ** 18 ;

  // Мэпинг который показывает информацию о адресе 
  mapping (address => Staker) public stakers;

  // Мэпинг который привязывает токен Айди к адресу
  // Что бы вернуть его владельцу
  mapping (uint => address) public stakerAddress;

  function stake(uint _tokenId) external nonReentrant {
    // Если пользователь уже стейкает нфт то награды будут увеличены
    if(stakers[msg.sender].amountStaked > 0) {
      uint rewards = calculateRewards(msg.sender);
      stakers[msg.sender].unclaimedRewards += rewards;
    }

    // Проверка имеет ли пользователь данную нфт 
    require(
      nftCollection.ownerOf(_tokenId) == msg.sender, 
      "You don't own this token!"
      );

    // Перевод токена от владельца на смарт контракт 
    nftCollection.transferFrom(msg.sender, address(this), _tokenId);

    // Создаем стейк токена
    StakedToken memory stakedTokens = StakedToken(msg.sender, _tokenId);

    // Добавляем НФТ токен в масив 
    stakers[msg.sender].stakedTokens.push(stakedTokens);

    // Добавляем кол-во застейканых нфт владельцу
    stakers[msg.sender].amountStaked++;

    // Обновляем мепинг владельца токена 
    stakerAddress[_tokenId] = msg.sender;

    // Обновляем время последнего обновления стейкинга
    stakers[msg.sender] .timeOfLastUpdate = block.timestamp;
  }

  function withdraw(uint _tokenId) external nonReentrant {
    // Проверка есть ли у отправителя застейканые нфт
    require(
      stakers[msg.sender].amountStaked > 0,
      "You don't have tokens staked"
    );

    // Проверка на владельца токена 
    require(stakerAddress[_tokenId] == msg.sender, "You don't own this token");

    // Ищем айди токена из списка
    uint index = 0;
    for (uint i = 0; i < stakers[msg.sender].stakedTokens.length; i++) {
      if (stakers[msg.sender].stakedTokens[i].tokenId == _tokenId){
        index = i;
        break;
      }
    }

    // Удаляем этот токен из списка застейканых нфт
    stakers[msg.sender].stakedTokens[index].staker = address(0);

    // Уменьшаем кол-во нфт застейканых 
    stakers[msg.sender].amountStaked--;

    // Удаляем из мепинга нфт , что больше не стейкается
    stakerAddress[_tokenId] = address(0);

    // Отправка нфт назад владельцу 
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