import { useEth } from "../contexts/EthContext";

import "./Door.css";

/** @type {(options: { phase: number, index: number, address: string, open: boolean, doorType: "0" | "1" | "2" }) => JSX.Element} */
const Door = ({ phase, index, address, open, doorType }) => {
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
      {doorType === "1" ? (
        <img className="door-image" src="/sports_car.webp" alt="Goat" />
      ) : doorType === "0" ? (
        <img className="door-image" src="/goat.jpg" alt="Sports Car" />
      ) : (
        false
      )}
      {value !== undefined && value !== 0 && (
        <div className="door-address">{address}</div>
      )}
    </div>
  );
};

export default Door;
