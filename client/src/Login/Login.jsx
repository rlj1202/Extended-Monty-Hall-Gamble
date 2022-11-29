import { useWeb3React } from "@web3-react/core";
import { injected } from "../lib/connectors";
import { isNoEthereumObject } from "../lib/errors";


import "./Login.css";

export default function Login() {
    const { chainId, account, active, activate, deactivate } = useWeb3React();
    const handleConnect = () => {
        if (active) {
            deactivate();
            return;
        }
        activate(injected, (error) => {
            if (isNoEthereumObject(error))
                window.open("https://metamask.io/download.html");
        });
    };
    return (
        <div>
            <nav class="navbar navbar-dark bg-dark">
                <div class="container">
                    <a class="navbar-brand" href="#">Extended Monty-Hall Gamble</a>
                </div>
            </nav>
            <div className="Login">
                <button class="btn btn-primary" type="Login" onClick={handleConnect}>
                    {active ? "Logout" : "Login"}
                </button>
            </div>
        </div>
    );
}
