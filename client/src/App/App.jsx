import { EthProvider, useEth } from "../contexts/EthContext";
import "./App.css";
import { useEffect, useState } from "react";
import { useCallback } from "react";

import Door from "../Door/Door";

function Main() {
  const {
    state: { artifact, web3, accounts, networkID, contract },
  } = useEth();

  const [size, setSize] = useState(0);
  const [doors, setDoors] = useState([]);
  const [phase, setPhase] = useState(0);
  const [balanace, setBalance] = useState(0);
  const [rounds, setRounds] = useState(0);
  const [fee, setFee] = useState(0);
  const [goats, setGoats] = useState([]);

  const fetchData = useCallback(async () => {
    if (!contract) return;
    if (!accounts) return;

    setSize(await contract.methods.getSize().call({ from: accounts[0] }));
    setDoors(await contract.methods.getDoors().call({ from: accounts[0] }));
    setPhase(
      parseInt(await contract.methods.getPhase().call({ from: accounts[0] }))
    );
    setBalance(await contract.methods.getBalance().call({ from: accounts[0] }));
    setRounds(await contract.methods.getRound().call({ from: accounts[0] }));
    setFee(
      await contract.methods.getParticipatingFee().call({ from: accounts[0] })
    );
    setGoats(await contract.methods.getGoats().call({ from: accounts[0] }));
  }, [contract, accounts]);

  useEffect(() => {
    if (!contract) return;
    if (!accounts) return;

    fetchData();

    contract.events.ParticipatingCompleted({}, (error, event) => {
      console.log(event);
      fetchData();
    });
    contract.events.SwitchingCompleted({}, (error, event) => {
      console.log(event);
      fetchData();
    });
    contract.events.DoorChosen({}).on("data", (event) => {
      console.log(event);
      fetchData();
    });
    contract.events.GameWinner({}).on("data", (event) => {
      console.log(event.returnValues);
    });
  }, [contract, accounts, fetchData]);

  return (
    <div>
      <div>Account: {accounts && accounts[0]}</div>
      <div>{networkID}</div>
      <div>doors: {size}</div>
      <div>phase: {phase}</div>
      <div>balance: {balanace}</div>
      <div>fee: {fee}</div>
      <div>rounds: {rounds}</div>
      <div className="doors">
        {doors.map((address, index) => (
          <Door
            phase={phase}
            index={index}
            address={address}
            open={goats[index]}
            key={index}
          />
        ))}
      </div>
    </div>
  );
}

const App = () => {
  return (
    <EthProvider>
      <div id="App">
        <div className="container">
          <h1>Extended Monty-Hall Gamble</h1>
          <hr />
          <Main />
        </div>
      </div>
    </EthProvider>
  );
};

export default App;
