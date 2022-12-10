const ExtendedMontyHallGamble = artifacts.require("ExtendedMontyHallGamble");

module.exports = function (deployer) {
  deployer.deploy(ExtendedMontyHallGamble, 3 * 2, 100);
};
