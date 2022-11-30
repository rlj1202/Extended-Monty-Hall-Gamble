import { useWeb3React } from "@web3-react/core";
import { injected } from "../lib/connectors";
import { isNoEthereumObject } from "../lib/errors";

import "./Login.css";

export default function Login() {
  const { chainId, account, active, activate, deactivate } = useWeb3React();

  const handleConnect = () => {
    if (active) {
      deactivate();
    } else {
      activate(injected, (error) => {
        if (isNoEthereumObject(error))
          window.open("https://metamask.io/download.html");
      });
    }
  };

  return (
    <div className="bg-dark">
      <nav className="navbar navbar-dark container d-flex flex-row align-items-center px-4">
        <a className="navbar-brand" href="/">
          Extended Monty-Hall Gamble
        </a>

        <button
          className="btn btn-primary"
          type="button"
          onClick={handleConnect}
        >
          {active ? "Logout" : "Login"}
        </button>
      </nav>
    </div>
  );
}
