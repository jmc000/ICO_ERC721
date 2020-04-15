pragma solidity ^0.6.0;

import "./ERC721.sol";

contract myNFT is ERC721 {

    address public contractOwner;
    mapping (address => bool) registredBreeders;
    uint256 private nbOfAnimals = 0;

    constructor() public {
        contractOwner = msg.sender;
    }

    struct animal {
        address owner;
        uint256 animalId;
        string kindOfAnimal;
        string name;
        uint8 age;
        string color;
        bool pureRace;
    }

    //address[] public breederList;
    mapping (address => bool) breederList;  //put the address in argument and know immediatly if True or False
    //animal[] public animalList;
    mapping (uint => animal) public animalList; //then we can directly access to the animal thanks to his id

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "You are not the contract owner");
        _;
    }

    event newBreederRegistred(address _address);

    function registerBreeder(address to) public onlyOwner() {
        breederList[to] = true;
        registredBreeders[to] = true;
        emit newBreederRegistred(to);
    }

    modifier whiteListedBreeder(address _address) {
        require(breederList[_address] == true, "This address is not allowed.");
        _;
    }

    event newAnimalDeclared(uint _animalId);

    modifier animalIdExists(uint _id){
        require(_exists(_id) == false, "Token Id already exists.");
        _;
    }

    function declareAnimal  (uint256 _animalId,
                            string memory _kindOfAnimal,
                            string memory _name,
                            uint8 _age,
                            string memory _color,
                            bool _pureRace) public whiteListedBreeder(msg.sender) animalIdExists(_animalId) {

        nbOfAnimals++;  //one more animal
        animal memory _newAnimal;  //new animal
        _newAnimal.animalId = _animalId;  //initialasing animal's parameters
        _newAnimal.kindOfAnimal = _kindOfAnimal;
        _newAnimal.name = _name;
        _newAnimal.age = _age;
        _newAnimal.color = _color;
        _newAnimal.pureRace = _pureRace;
        //complete the mappings
        animalList[_animalId] = _newAnimal;
        _tokenOwner[_newAnimal.animalId] = msg.sender;
        //mint the token
        _safeMint(msg.sender, _animalId);
        //emit event
        emit newAnimalDeclared(_animalId);
    }

    event animalIsDead(uint _animalId);

    modifier onlyTokenOwner(uint tokenId) {
        require(_tokenOwner[tokenId] == msg.sender, "The address is not mathcing to the token owner.");
        _;
    }

    //the one who want to declare is animal dead has to be the owner of this animal
    function deadAnimal(uint tokenId) public onlyTokenOwner(tokenId){
        _burn(msg.sender, tokenId);
        emit animalIsDead(tokenId);
    }

    //need first to approve an address to declare the birth of an offspring
    //[msg.sender] said that [_address] can declare an offsrping of my [_animalId1] with his/her [_animalId2] (ie = true)
    mapping (address => mapping (address => mapping ( uint => mapping ( uint => bool)))) private _birthApprovals;

    function allowBirthDeclaration(address _otherAddress, uint _myTokenId, uint _otherTokenId) public onlyOwner(){
        _birthApprovals[msg.sender][_otherAddress][_myTokenId][_otherTokenId] = true;
    }

    modifier canDeclareBirthOf(address _otherAddress, uint _myTokenId, uint _otherTokenId) {
        require(_birthApprovals[msg.sender][_otherAddress][_myTokenId][_otherTokenId] == true,"You are not allowed.");
        _;
    }

    event offspringBorned(uint _animalId);

    function breedAnimal(address _otherAddress, uint _myTokenId, uint _otherTokenId,
                            uint256 _animalId,
                            string memory _kindOfAnimal,
                            string memory _name,
                            string memory _color) public
                                                    canDeclareBirthOf( _otherAddress, _myTokenId,  _otherTokenId) {
        //now we can declare the offsrping:
        //the boo pure race & the age are deduce automaticaly
        // bool _pureRace;
        // if (animalList[_myTokenId].kindOfAnimal != animalList[_otherTokenId].kindOfAnimal){
        //     _pureRace = true;
        // }
        // else {_pureRace = false;}

        declareAnimal(_animalId, _kindOfAnimal, _name,0, _color, false);
        //note that the owner of th offsrping is the one who declare him
        emit offspringBorned(_animalId);
    }


    //Auction
    //in solidity: 1 wei == 1 & 1 eth ==1e18

    struct auction {
        address payable owner;
        uint tokenId;
        uint256 auctionPrice;  //initial price in wei (1 wei = 1e-18 eth)
        address actualAuctioneer;
        uint256 deadline;
        bool exist;
    }

    mapping (uint => auction) auctionList;
    event newAuctionCreated( uint _tokenId);

    function createAuction(uint _tokenId, uint _initialWeiPrice) public onlyTokenOwner(_tokenId) {
        auction memory _newAuction;
        _newAuction.owner = msg.sender;
        _newAuction.tokenId = _tokenId;
        _newAuction.auctionPrice = _initialWeiPrice;
        _newAuction.deadline = now + 2*(1 days);
        _newAuction.exist = true;
        auctionList[_tokenId] = _newAuction;
        emit newAuctionCreated(_tokenId);
    }

    event newBid(uint _tokenId, address _address);

    function bidOnAuction(uint _tokenId, uint _weiPrice) public {
        require(auctionList[_tokenId].exist == true,"No auction for this token");
        require(now >= auctionList[_tokenId].deadline, "Auction closed, the time limit is exceeded");
        require(_weiPrice > auctionList[_tokenId].auctionPrice, "The auction price is insufficient");

        //if you still here your bid successed
        auctionList[_tokenId].auctionPrice = _weiPrice;
        auctionList[_tokenId].actualAuctioneer = msg.sender;
        //emit event of new bid
        emit newBid(_tokenId, msg.sender);
    }

    modifier onlyAuctionWinner(uint _tokenId, address _address){
        require(auctionList[_tokenId].actualAuctioneer == _address, "You are not the winner of the auction.");
        _;
    }

    event auctionWinner(uint _tokenId, address _address);

    // function pay(address _to, uint _weiPrice) public payable {
    //     if (msg.value <= _weiPrice) {
    //     revert();
    //     }
    //     _to.balance()+=msg.value;
    // }

    function transferAmount (address payable _to, uint _weiPrice) public payable {
        if (msg.value <= _weiPrice) {
            revert();
        }
        _to.transfer(msg.value);
    }

    function claimAuction(uint _tokenId) public onlyAuctionWinner(_tokenId, msg.sender) {
        //approve msg.sender to transger the token
        approve(msg.sender,_tokenId);
        //transfer money to the former owner
        transferAmount(auctionList[_tokenId].owner, auctionList[_tokenId].auctionPrice);
        //transfer the ownership of the token to the winner of the auction
        transferFrom(auctionList[_tokenId].owner, msg.sender, _tokenId);

        emit auctionWinner(_tokenId, msg.sender);
    }


    //fight

    struct fight{
        uint fightId;
        address from;
        uint animalId;
        address to;
        uint targetId;
        uint256 weiPriceBet;
        bool fightAccepted;
        bool exist;
    }

    uint nbOfFight = 0;

    mapping (uint => fight) fightList;


    event fightProposed(uint fightId, address _from, address _to, uint _animalId, uint _targetId, uint _weiBet);
    event fightAccepted(uint fightId);

    function proposeFight(address _to, uint _animalId, uint _targetId, uint256 _weiPriceBet) public payable onlyTokenOwner(_animalId) {
        //need to make sure that the money added to the function called is at least the wei amount bet
        if (msg.value <= _weiPriceBet) {
        revert();
        }
        
        nbOfFight++;
        fight memory _newFight;
        _newFight.fightId = nbOfFight;
        _newFight.from = msg.sender;
        _newFight.animalId = _animalId;
        _newFight.to = _to;
        _newFight.targetId = _targetId;
        _newFight.weiPriceBet = _weiPriceBet;
        _newFight.fightAccepted = false;
        _newFight.exist = true;

        fightList[_newFight.fightId] = _newFight;

        emit fightProposed(_newFight.fightId, msg.sender,_to,_animalId,_targetId,_weiPriceBet);
    }


    function agreeToFight(uint _fightId) public payable {
        //make sure that the fight exist
        require(fightList[_fightId].exist == true, "fightId not existing.");
        //make sure that the msg.sender is the correct _to address
        require(fightList[_fightId].to == msg.sender, "You are not allowed to accept this fight.");
        //need to make sure that the money added to the function called is at least the wei amount bet
        if (msg.value <= fightList[_fightId].weiPriceBet) {
        revert();
        }
        fightList[_fightId].fightAccepted = true;
        emit fightAccepted(_fightId);
    }


}