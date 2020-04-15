const Migrations = artifacts.require("Migrations");
var myNFT = artifacts.require("myNFT");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
  deployer.link(Migrations, myNFT);
  deployer.deploy(myNFT);
};


// const Migrations = artifacts.require("Migrations");
// var myToken = artifacts.require("myToken");

// module.exports = function(deployer) {
//   deployer.deploy(Migrations);
//   deployer.link(Migrations, myToken);
//   deployer.deploy(myToken);
// };
