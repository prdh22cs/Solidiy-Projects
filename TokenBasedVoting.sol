// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//ERC20 INTERFACE

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

//TOKEN GOVERNANCE CONTRACT

contract TokenBasedVoting {

//STATE
    address public owner;
    IERC20 public governanceToken;
    uint public proposalCount;

    struct Proposal {
        string title;
        string description;
        uint deadline;
        uint yesVotes;
        uint noVotes;
        bool executed;
    }

    mapping(uint => Proposal) public proposals;

    // proposalId => voter => voted?
    mapping(uint => mapping(address => bool)) public hasVoted;

  
//EVENTS


    event ProposalCreated(
        uint indexed proposalId,
        string title,
        uint deadline
    );

    event Voted(
        uint indexed proposalId,
        address indexed voter,
        uint weight,
        bool vote
    );

    event ProposalExecuted(
        uint indexed proposalId,
        bool passed
    );

  
//MODIFIERS
  

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier proposalExists(uint _id) {
        require(_id < proposalCount, "Invalid proposal");
        _;
    }

    modifier votingActive(uint _id) {
        require(
            block.timestamp < proposals[_id].deadline,
            "Voting ended"
        );
        _;
    }

    modifier votingEnded(uint _id) {
        require(
            block.timestamp >= proposals[_id].deadline,
            "Voting not ended"
        );
        _;
    }

  
//CONSTRUCTOR
  

    constructor(address _tokenAddress) {
        owner = msg.sender;
        governanceToken = IERC20(_tokenAddress);
    }

  
//CREATE PROPOSAL
  

    function createProposal(
        string memory _title,
        string memory _description,
        uint _duration
    ) public onlyOwner {

        require(_duration > 0, "Duration must be > 0");

        Proposal storage newProposal = proposals[proposalCount];

        newProposal.title = _title;
        newProposal.description = _description;
        newProposal.deadline = block.timestamp + _duration;
        newProposal.yesVotes = 0;
        newProposal.noVotes = 0;
        newProposal.executed = false;

        emit ProposalCreated(
            proposalCount,
            _title,
            newProposal.deadline
        );

        proposalCount++;
    }

  
//VOTE
  

    function vote(uint _id, bool _vote)
        public
        proposalExists(_id)
        votingActive(_id)
    {
        require(!hasVoted[_id][msg.sender], "Already voted");

        uint weight = governanceToken.balanceOf(msg.sender);
        require(weight > 0, "No voting power");

        Proposal storage proposal = proposals[_id];

        if (_vote) {
            proposal.yesVotes += weight;
        } else {
            proposal.noVotes += weight;
        }

        hasVoted[_id][msg.sender] = true;

        emit Voted(_id, msg.sender, weight, _vote);
    }

  
//EXECUTE PROPOSAL
  

    function executeProposal(uint _id)
        public
        proposalExists(_id)
        votingEnded(_id)
    {
        Proposal storage proposal = proposals[_id];

        require(!proposal.executed, "Already executed");

        proposal.executed = true;

        bool passed = proposal.yesVotes > proposal.noVotes;

        emit ProposalExecuted(_id, passed);
    }

  
//VIEW HELPER
  

    function getProposal(uint _id)
        public
        view
        proposalExists(_id)
        returns (
            string memory,
            string memory,
            uint,
            uint,
            uint,
            bool
        )
    {
        Proposal memory p = proposals[_id];
        return (
            p.title,
            p.description,
            p.deadline,
            p.yesVotes,
            p.noVotes,
            p.executed
        );
    }
}
