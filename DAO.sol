//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
contract DAO
{
    struct proposal
    {
        uint id;
        string description;
        uint amount;
        address payable reciepient;
        uint votes ;
        uint end ;
        bool isExecuted;
    }
    mapping(address=>bool) private isInvestor;
    mapping(address=>uint) public numberOfShres;
    mapping(address=>mapping(uint=>bool)) public isVoted;
    mapping(uint=>proposal) public proposalList;
    address[] public investorList;
    uint public totalShares;
    uint public availableFund;
    uint public contibutionTimeEnd;
    uint public nextProposalId;
    uint public voteTime;
    uint public quorum ;
    address public manager;
    // constructor 
    constructor(uint _contibutionTimeEnd , uint _voteTime , uint _quorum )
    {
        contibutionTimeEnd = block.timestamp+_contibutionTimeEnd;
        voteTime = _voteTime;
        quorum = _quorum;
        manager = msg.sender;
    }
    // modifiers 
    modifier onlyInvestor()
    {
        require (isInvestor[msg.sender] == true  , "You are not an investor");
        _;
    }
    modifier onlyManager()
    {
        require(msg.sender == manager,"You are not a manager");
        _;
    }
    function contribution() external payable 
    {
        require (contibutionTimeEnd >= block.timestamp , "Time End");
        require(msg.value>0, "Send more than 0 ether");
        isInvestor[msg.sender] = true;
        numberOfShres[msg.sender] = numberOfShres[msg.sender]+msg.value;
        totalShares+=msg.value; // total share 
        availableFund+=msg.value;
        investorList.push(msg.sender);
    }
    function reedemShare(uint amt) external onlyInvestor()
    {
        require(amt <= numberOfShres[msg.sender], "Curr balance is less than amount entered by you ");
        require(availableFund>=amt , "not enough funds");
        numberOfShres[msg.sender] = numberOfShres[msg.sender]-amt;
        if(numberOfShres[msg.sender] == 0)
        {
            isInvestor[msg.sender] = false;
        }
        payable(msg.sender).transfer(amt);
        availableFund = availableFund-amt;
        totalShares = totalShares-amt ;
    }
    // transfer of inc=vestor share to other address
    function transfershare(uint amt , address to) public  onlyInvestor()
    {
        require(availableFund>=amt , "not enough funds");
        require(amt <= numberOfShres[msg.sender], "Curr balance is less than amount entered by you ");
        numberOfShres[msg.sender] = numberOfShres[msg.sender]-amt;
         if(numberOfShres[msg.sender] == 0)
        {
            isInvestor[msg.sender] = false;
        }
        numberOfShres[to]+=amt;
        isInvestor[to] = true;
        investorList.push(msg.sender);
    }
    function createProposal(string calldata description , uint amount , address payable reciepent) public 
    {
        require(amount <= availableFund , "Fund exceed " );
        proposalList[nextProposalId] = proposal(nextProposalId ,description , amount  , reciepent, 0 , block.timestamp+voteTime, false  );
        nextProposalId++;
    }
    function voteProposal(uint proposalId) public onlyInvestor()
    {
        // check double voting 
        proposal storage curr = proposalList[proposalId];
        require(isVoted[msg.sender][proposalId]== false , "already voted");
        require(curr.end >= block.timestamp , "voting time ended");
        require(curr.isExecuted == false , "this is already xcuted brother ");
        isVoted[msg.sender][proposalId]=true;
        curr.votes+= numberOfShres[msg.sender];
    }
    function exceuteProposal(uint ProposalId) public onlyManager()
    {
        
        proposal storage curr = proposalList[ProposalId];
        require(((curr.votes*100)/totalShares)>=quorum , "Majority dosent exists ");
        curr.isExecuted= true;
        availableFund-=curr.amount;
        _transfer(curr.amount, curr.reciepient);

    }
    function _transfer(uint amt , address payable to) private 
    {
        to.transfer(amt);  
    }
    function _proposalList() public  view returns(proposal[] memory )
    {
        proposal[] memory temp = new proposal[](nextProposalId-1); 
        for(uint i = 0 ; i<nextProposalId-1 ; i++)
        {
            temp[i] = proposalList[i];
        }
        return temp;
    }
}