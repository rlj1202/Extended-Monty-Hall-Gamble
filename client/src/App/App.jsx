import { EthProvider, useEth } from "../contexts/EthContext";
import "./App.css";
import React, { useEffect, useRef, useState } from "react";
import { useCallback } from "react";

import Door from "../Door/Door";

/**
 * @typedef Door
 * @property {string} doorType
 * @property {boolean} open
 * @property {string} participant
 */

const Main = () => {
  const {
    state: { artifact, web3, active, accounts, networkID, contract },
  } = useEth();

  const loggingRef = useRef();

  const [size, setSize] = useState(0);
  /** @type {[Door[], React.Dispatch<React.SetStateAction<Door[]>> ]} */
  const [doors, setDoors] = useState([]);
  const [phase, setPhase] = useState(0);
  const [balanace, setBalance] = useState(0);
  const [rounds, setRounds] = useState(0);
  const [fee, setFee] = useState(0);

  const [gameEnded, setGameEnded] = useState(false);
  /** @type {[Door[], React.Dispatch<React.SetStateAction<Door[]>> ]} */
  const [lastDoors, setLastDoors] = useState([]);
  const [reward, setReward] = useState(0);

  const fetchData = useCallback(async () => {
    if (!contract) return;
    if (!accounts) return;

    console.log("Fetch data...");

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
  }, [contract, accounts]);

  const refresh = useCallback(async () => {
    fetchData();
    setGameEnded(false);
  }, [fetchData]);

  const log = (msg) => {
    if (!loggingRef) return;
    if (!loggingRef.current) return;

    loggingRef.current.textContent += JSON.stringify(msg);
  };

  useEffect(() => {
    if (!contract) return;
    if (!accounts) return;

    fetchData();

    contract.events.ParticipatingCompleted({}, (error, event) => {
      console.log(event);
      log(event);
      fetchData();
    });
    contract.events.SwitchingCompleted({}, (error, event) => {
      console.log(event);
      log(event);
      fetchData();
    });
    contract.events.DoorChosen({}).on("data", (event) => {
      console.log(event);
      log(event);
      fetchData();
    });
    contract.events.GameWinner({}).on("data", (event) => {
      console.log(event);
      log(event);

      /** @type {{ reward: number, round: number, winner: string }} */
      const { reward, round, winner } = event.returnValues;

      if (accounts && accounts[0] === winner) {
        // You are the winner!!!
        setReward(reward);
      }

      fetchData();
    });
    contract.events.GameEnded({}).on("data", (event) => {
      console.log(event);
      log(event);

      /** @type {Door[]} */
      const doors = event.returnValues.doors;
      setLastDoors(doors);
      setGameEnded(true);
    });
  }, [contract, accounts, fetchData, active]);

  return (
    <div>
      <div>Account: {accounts && accounts[0]}</div>
      <div>{networkID}</div>
      <div>doors: {size}</div>
      <div>max # of participants: {Math.floor(size / 3)}</div>
      <div>phase: {phase}</div>
      <div>balance: {balanace} wei</div>
      <div>fee: {fee} wei</div>
      <div>rounds: {rounds}</div>
      {gameEnded && reward > 0 && <div>You earned {reward} wei!</div>}
      {gameEnded && <button onClick={refresh}>Restart Game</button>}
      <div className="doors">
        {!gameEnded
          ? doors.map((info, index) => (
              <Door
                phase={phase}
                index={index}
                address={info.participant}
                open={info.open}
                doorType={info.doorType}
                key={index}
              />
            ))
          : lastDoors.map((info, index) => (
              <Door
                phase={3}
                index={index}
                address={info.participant}
                open={info.open}
                doorType={info.doorType}
                key={index}
              />
            ))}
      </div>
      <textarea
        className="logging"
        placeholder="Logging..."
        readOnly
        ref={loggingRef}
      ></textarea>
    </div>
  );
};

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
