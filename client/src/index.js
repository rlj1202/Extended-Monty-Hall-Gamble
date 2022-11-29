import { StrictMode } from "react";
import ReactDOM from "react-dom";
import { Web3ReactProvider } from "@web3-react/core";
import { Web3Provider } from "@ethersproject/providers";

import 'bootstrap'
import 'bootstrap/dist/css/bootstrap.min.css'

import App from "./App/App";
import Login from "./Login/Login"

function getLibrary(provider) {
  const library = new Web3Provider(provider, "any");
  return library;
}

const rootElement = document.getElementById("root");
ReactDOM.render(
  <StrictMode>
      <Web3ReactProvider getLibrary={getLibrary}>
        <Login />
        <App />
      </Web3ReactProvider>
  </StrictMode>,
  rootElement
);
