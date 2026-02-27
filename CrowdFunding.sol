// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract CrowdFunding{
    mapping(address => uint) public contributors;
    address public manager;
    uint public minimumContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noOfContributors;

    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address => bool) voters;
    }

    mapping(uint => Request) public requests;
    uint public numRequests;

    constructor(uint _target, uint _deadline){
        target = _target;
        deadline = block.timestamp + _deadline;
        minimumContribution = 100 wei;
        manager = msg.sender; 
    }

    function sendEth() public payable{
        require(block.timestamp < deadline,"Deadline has passed!!!!");
        require(msg.value >= minimumContribution,"Minimum Contributioon is not met");

        if(contributors[msg.sender] == 0){
            noOfContributors++;
        }
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }
    
    function refund() public {
    require(block.timestamp > deadline, "Deadline not reached yet");
    require(raisedAmount < target, "Target achieved, refund not allowed");
    require(contributors[msg.sender] > 0, "No contribution found");

    uint amount = contributors[msg.sender];
    contributors[msg.sender] = 0; // state change before transfer (important!)

    (bool success, ) = payable(msg.sender).call{value: amount}("");
    require(success, "Refund failed");
}

modifier onlyManager(){
    require(msg.sender == manager,"Only manager can access or call this function");
    _;
}

function createRequests(string memory _description, address payable _recipient, uint _value ) public onlyManager{
    Request storage newRequest= requests[numRequests];
    numRequests++;
    newRequest.description= _description;
    newRequest.recipient= _recipient;
    newRequest.value= _value;
    newRequest.completed= false;
    newRequest.noOfVoters = 0;
}

function voteRequest(uint _requestNo) public{
    require(contributors[msg.sender] > 0,"You must be a contributor");
    Request storage thisRequest = requests[_requestNo];
    require(thisRequest.voters[msg.sender] == false,"You have already voted");
    thisRequest.voters[msg.sender] = true;
    thisRequest.noOfVoters++;
}

function makePayment(uint _requestNo) public onlyManager {
    require(raisedAmount >= target, "Target not reached");

    Request storage thisRequest = requests[_requestNo];

    require(!thisRequest.completed, "The request has been completed");
    require(thisRequest.noOfVoters > noOfContributors / 2,"Majority does not support");

    thisRequest.completed = true; // state change BEFORE transfer (important!)

    (bool success, ) = payable(thisRequest.recipient).call{
        value: thisRequest.value
    }("");

    require(success, "Payment failed");
}

}