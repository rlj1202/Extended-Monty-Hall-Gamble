import { useEth } from "../contexts/EthContext";

import "./Door.css";

const Door = ({ phase, index, address, open }) => {
  const {
    state: { artifact, web3, accounts, contract },
  } = useEth();

  const value = parseInt(address);

  async function chooseDoor() {
    if (phase === 1) {
      await contract.methods
        .participate(index)
        .send({ from: accounts[0], value: 100 });
    } else if (phase === 2) {
      await contract.methods
        .switchDoor(index)
        .send({ from: accounts[0], value: 0 });
      console.log("switchDoor");
    }
  }

  return (
    <div onClick={chooseDoor} className="door">
      {value !== undefined && value !== 0 && (
        <div className="door-address">{address}</div>
      )}
      {open && <img className="door-goat" src="/goat.jpg" alt="Goat" />}
    </div>
  );
};

export default Door;
