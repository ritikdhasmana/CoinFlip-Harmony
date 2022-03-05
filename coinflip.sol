// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;




/**
 * @title CoinFlip
   @author Ritik Dhasmana  (ritikdhasmana22@gmail.com)
 * @dev Betting game where users can place a bet on a particular outcome of a coin flip. Allows multiple user to place bet at the same time but no user can place a bet before finishing his/her current undecided bet. 
 */
contract CoinFlip{
    address _owner;



     /**
     * @dev Set contract deployer as owner
     */
    constructor(){
        _owner = msg.sender;
    }


    //event for when a user places a bet.
    event betPlaced(uint8 bet, address bettor, uint amount);

    //event for bet that a user wins.
    event betWon(uint8 bet, address bettor, uint amount);




    /**
     * @dev bet structure
     * @param bettor  address of user who places the bet
     * @param betAmount  amount placed on the bet
     * @param expectedOutcome bet placed by user, where bet = 0 or 1 representing heads or tails respectively 
     * @param actualOutcome , harmony vrf generated random outcome for this bet , where actualOutcome = 
     ** 0 meaning heads
     ** 1 meaning tails
     ** 2 meaning the bet is still undecided and hence no outcome
     */
    struct userBet{
        address bettor;
        uint betAmount;
        uint8 expectedOutcome;
        uint8 actualOutcome;
    }
    mapping(uint => userBet) public allBets; //all the bets palced , where key works as bet Id and userbet is the bet structure
    uint public totalBetCount=0; // total bet count
    uint public completedBetCount=0; // bets that have been completed 

    uint public userCount=0; // total users
    mapping(address => uint) public userId; // maps user with their id, helps with checking if a user is new user or not
    mapping(address => uint) public userBalance; //user balance
    mapping(address => bool) public isBetting; // checks if user currently has undecided bet or not

     /**
     * @dev place coin flip bet 
     * @param  bet   the side of coin user is betting on, where 0 means head and 1 means tails
     * @param amount the amount user wants to place on this bet
     */
    function placeBet(uint8 bet, uint amount) public {
        
        if(userId[msg.sender]==0){//checks if it is a new user
            userCount++;
            userId[msg.sender] = userCount;
            isBetting[msg.sender] = false;
            userBalance[msg.sender] = 100;
        }
        require(isBetting[msg.sender]==false, "User has an undecided bet!"); 
        require(userBalance[msg.sender]>=amount, "Insufficient balance!");
        
        userBalance[msg.sender] -= amount;
        isBetting[msg.sender] = true;

        totalBetCount++;
        allBets[totalBetCount] = userBet(msg.sender,amount, bet, 2); // new bet placed with 'actualOutcome' =2 as the outcome isn't decided yet

        emit betPlaced(bet, msg.sender, amount);
    }

     /**
     * @dev generates random number 'rand' and concludes all the currently undecided bets with win/loss and emits event if user wins a bet
     */
    function rewardBets() public {

        uint8 rand =uint8(uint(vrf())%2);// random number generated using harmony vrf, where vrf returns a byte32 which is typecasted to uint and then its modulus with 2 is taken as bet can only be 0 or 1..
        //uint is typecasted to uint8 as our bet structure uses uint8 for bets


        uint i = completedBetCount + 1;//current undecided bets start from completedBetcount + 1, as we conclude all bet at once , serial order is maintained 

        for(;i<=totalBetCount;i++){
            userBet storage curBet = allBets[i];
            if(curBet.actualOutcome==2){ //is outcome is undecided
                if(curBet.expectedOutcome==rand){//bet won
                    address bettor = curBet.bettor;
                    userBalance[bettor] += 2*curBet.betAmount;
                    isBetting[bettor] = false;
                    emit betWon(rand, bettor, curBet.betAmount);
                }
                // else bet lost, do nothing


                curBet.actualOutcome = rand; //set outcome (flagging current bet)
                completedBetCount ++; //increment completed bets
            }
        }
    }

 /**
     * @dev offcial harmony vrf implementation
     */
    function vrf() public view returns (bytes32 result) {
        uint[1] memory bn;
        bn[0] = block.number;
        assembly {
            let memPtr := mload(0x40)
            if iszero(staticcall(not(0), 0xff, bn, 0x20, memPtr, 0x20)) {
                invalid()
            }
            result := mload(memPtr)
        }
  }

}
