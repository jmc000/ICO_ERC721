const myNFT = artifacts.require('./myNFT.sol')
const assert = require('assert')

let contractInstance

contract('myNFT', (accounts) => {
    beforeEach(async () => {
        contractInstance = await myNFT.deployed()
    })

    it('should register a breeder, but only the contract owner can', async () => {
        await contractInstance.registerBreeder(web3.toHex('only the contract owner succeeded to register a breeder'))

    const newBreederRegistered = await contractInstance.registerBreeder(accounts[0],0)
    const breederContent = web3.toUtf8(newBreederRegistered[1])

    assert.equal(breederContent, 'only the contract owner succeeded to register a breeder','Failed')    
    })
})