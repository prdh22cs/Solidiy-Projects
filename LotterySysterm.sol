// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract LotterySystem{
 //entities - manager,players and winner
 address public manager;
 address payable[] public players;
 address payable public winner;

  constructor(){
      manager=msg.sender;
  }

  function participate() public payable{
      require(msg.value==1 ether,"Please pay 1 ether only");
      players.push(payable(msg.sender));
  }

  function getBalance() public view returns(uint){
      require(manager==msg.sender,"You are not the manager");
      return address(this).balance;
  }

  function random() internal view returns(uint){
      return uint(keccak256(abi.encodePacked(block.prevrandao,block.timestamp,players.length)));
  }

 function pickWinner() public {
    require(msg.sender == manager, "You are not the manager");
    require(players.length >= 3, "Players are less than 3");

    uint r = random();
    uint index = r % players.length;
    address payable selectedWinner = players[index];

    // EFFECTS (state changes first)
    delete players;
    winner = selectedWinner;

    // INTERACTION (send ETH last)
    (bool success, ) = selectedWinner.call{value: address(this).balance}("");
    require(success, "Transfer failed");
}


}