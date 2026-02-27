// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract SnapshotVoting {

    ERC20Votes public governanceToken;
    address public owner;
    uint public proposalCount;

    struct Proposal {
        string title;
        uint snapshotBlock;
        uint deadline;
        uint yesVotes;
        uint noVotes;
        bool executed;
    }

    mapping(uint => Proposal) public proposals;
    mapping(uint => mapping(address => bool)) public hasVoted;

    event ProposalCreated(uint id, uint snapshotBlock, uint deadline);
    event Voted(uint id, address voter, uint weight);
    event Executed(uint id, bool passed);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _tokenAddress) {
        governanceToken = ERC20Votes(_tokenAddress);
        owner = msg.sender;
    }

    function createProposal(uint _duration) public onlyOwner {

        Proposal storage p = proposals[proposalCount];

        p.snapshotBlock = block.number;
        p.deadline = block.timestamp + _duration;

        emit ProposalCreated(proposalCount, p.snapshotBlock, p.deadline);

        proposalCount++;
    }

    function vote(uint _id, bool _vote) public {

        Proposal storage p = proposals[_id];

        require(block.timestamp < p.deadline, "Voting ended");
        require(!hasVoted[_id][msg.sender], "Already voted");

        uint weight = governanceToken.getPastVotes(
            msg.sender,
            p.snapshotBlock
        );

        require(weight > 0, "No voting power");

        if (_vote) {
            p.yesVotes += weight;
        } else {
            p.noVotes += weight;
        }

        hasVoted[_id][msg.sender] = true;

        emit Voted(_id, msg.sender, weight);
    }

    function execute(uint _id) public {

        Proposal storage p = proposals[_id];

        require(block.timestamp >= p.deadline, "Voting active");
        require(!p.executed, "Already executed");

        p.executed = true;

        bool passed = p.yesVotes > p.noVotes;

        emit Executed(_id, passed);
    }
}
