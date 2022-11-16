/*
  Try `truffle exec scripts/increment.js`, you should `truffle migrate` first.

  Learn more about Truffle external scripts: 
  https://trufflesuite.com/docs/truffle/getting-started/writing-external-scripts
*/

const ExtendedMontyHallGamble = artifacts.require("ExtendedMontyHallGamble");

module.exports = async function (callback) {
  const accounts = await web3.eth.getAccounts();

  const deployed = await ExtendedMontyHallGamble.deployed();

  const size = (await deployed.getSize()).toNumber();
  console.log(`Current number of doors: ${size}`);

  const balance = (await deployed.getBalance()).toNumber();
  console.log(`Current balance of the game: ${balance}`);

  const fee = (await deployed.getParticipatingFee()).toNumber();
  console.log(`Current fee of the game: ${fee}`);

  const rounds = (await deployed.getRound()).toNumber();
  console.log(`Rounds: ${rounds}`);

  console.log(`Participating`);
  await deployed
    .participate(0, { from: accounts[1], value: 100 })
    .catch((err) => console.log(`${err}`));

  const goats = await deployed.getGoats();
  console.log(goats);

  console.log(`Switching`);
  await deployed
    .switchDoor(2, { from: accounts[1] })
    .catch((err) => console.log(`${err}`));

  callback();
};
