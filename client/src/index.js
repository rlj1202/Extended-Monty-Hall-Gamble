import { StrictMode } from "react";
import ReactDOM from "react-dom";
import { Web3ReactProvider } from "@web3-react/core";
import { Web3Provider } from "@ethersproject/providers";


import App from "./App/App";
import Login from "./Login/Login";




function getLibrary(provider) {
  const library = new Web3Provider(provider, "any");
  return library;
}

const rootElement = document.getElementById("root");
ReactDOM.render(
  <StrictMode>
    <Web3ReactProvider getLibrary={getLibrary}>
      <Login />
    </Web3ReactProvider>
  </StrictMode>,
  rootElement
);
