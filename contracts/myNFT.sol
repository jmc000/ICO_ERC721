pragma solidity ^0.6.0;

import "./ERC721.sol";

contract myNFT is ERC721 {

    address public contractOwner;
    mapping (address => bool) registredBreeders;

    struct animal {
        uint256 animalId;
        string  kindOfAnimal;
        string name;
        uint8 age;
        string color;
        string bornIn;
        bool pureRace;
    }

    address[] public breederList;
    animal[] public animalList;

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "You are not the contract owner");
        _;
    }

    event newBreederRegistred(address _addresse);

    function registerBreeder(address to) public onlyOwner() {
        breederList.push(to);
        registredBreeders[to] = true;
        emit newBreederRegistred(to);
    }


}