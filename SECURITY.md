# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in Credence, please report it responsibly via email to **security@credence.finance**. Do **not** open a public GitHub issue for security vulnerabilities.

Your report should include:

- Description of the vulnerability
- Steps to reproduce
- Affected contract(s) and function(s)
- Potential impact assessment

## Scope

The following are in scope for responsible disclosure:

| Component               | Path                                         |
| ----------------------- | -------------------------------------------- |
| BaseEscrow              | `src/core/BaseEscrow.sol`                    |
| DisputeEscrow           | `src/core/DisputeEscrow.sol`                 |
| TradeInfraEscrow        | `src/core/TradeInfraEscrow.sol`              |
| CentralizedTradeOracle  | `src/CentralizedTradeOracle.sol`             |
| ChainlinkTradeOracle    | `src/ChainlinkTradeOracle.sol`               |
| CredenceReceivable      | `src/CredenceReceivable.sol`                 |
| ProtocolArbiterMultisig | `src/governance/ProtocolArbiterMultisig.sol` |
| EscrowTypes             | `src/libraries/EscrowTypes.sol`              |
| ReputationLibrary       | `src/libraries/ReputationLibrary.sol`        |
| ITradeOracle            | `src/interfaces/ITradeOracle.sol`            |
| IReceivableMinter       | `src/interfaces/IReceivableMinter.sol`       |
| Deployment scripts      | `script/`                                    |

**Out of scope:** third-party dependencies (OpenZeppelin, Chainlink, forge-std), frontend and off-chain infrastructure, test files.

## Safe Harbor

We consider security research conducted consistent with this policy to be:

- Authorized with respect to any applicable anti-hacking laws
- Exempt from restrictions in our Terms of Service that would interfere with conducting security research
- Lawful, helpful, and conducted in good faith

We will not pursue legal action against individuals who discover and report vulnerabilities in good faith and in accordance with this policy.

## Disclosure Timeline

| Step                          | Timeline                                  |
| ----------------------------- | ----------------------------------------- |
| Acknowledgment of report      | Within 48 hours                           |
| Initial assessment            | Within 7 days                             |
| Fix development and testing   | Within 30 days (severity-dependent)       |
| Coordinated public disclosure | After fix is deployed, or 90 days maximum |

We ask reporters to allow us reasonable time to address issues before any public disclosure.

## Known Limitations

For known design limitations and trust assumptions, see the [Known Limitations](README.md#known-limitations) section of the README.

## Audit Status

Static analysis has been performed using [Aderyn](https://github.com/Cyfrin/aderyn). A formal third-party audit has not yet been conducted. See [README — Audit Status](README.md#audit-status).
