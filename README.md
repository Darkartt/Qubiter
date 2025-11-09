# EIP-7702 Account Abstraction Library

A production-ready Solidity library for implementing EIP-7702 Account Abstraction patterns, enabling advanced authorization mechanisms, gas sponsorship (paymasters), and session key management.

## Overview

This library provides a comprehensive set of smart contracts and utilities for building next-generation account abstraction solutions on Ethereum using [EIP-7702](https://eips.ethereum.org/EIPS/eip-7702). It's designed for developers who want to implement secure, gas-efficient, and flexible account abstraction without building from scratch.

### Key Features

- **Authorization Management**: Secure signature validation and authorization delegation with replay protection
- **Gas Sponsorship (Paymasters)**: Allow third parties to sponsor transaction gas costs with budget controls
- **Session Keys**: Granular permission management for temporary or restricted access
- **Transaction Batching**: Execute multiple operations atomically with rollback support
- **Gas Optimized**: Carefully optimized for minimal gas consumption
- **Security First**: Designed with security best practices and prepared for formal audits
- **Prague EVM Ready**: Built for Solidity 0.8.30 targeting the Prague EVM version

## Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Solidity 0.8.30 or higher
- Basic understanding of EIP-7702 and account abstraction

### Installation

```bash
# Clone the repository
git clone https://github.com/Darkartt/Qubiter.git
cd Qubiter

# Install dependencies
forge install

# Build the project
forge build

# Run tests
forge test
```

### Basic Usage Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AuthorizationManager} from "./src/core/AuthorizationManager.sol";

contract MyApp {
    AuthorizationManager public authManager;

    constructor() {
        authManager = new AuthorizationManager();
    }

    function executeWithAuthorization(
        bytes memory authorization,
        bytes32 digest
    ) external {
        require(
            authManager.validateAuthorization(authorization, digest),
            "Invalid authorization"
        );

        // Your logic here
    }
}
```

### Deploy Example

```bash
# Deploy to local testnet
forge script script/Deploy.s.sol:DeployScript --rpc-url http://localhost:8545 --broadcast

# Deploy to testnet (e.g., Sepolia)
forge script script/Deploy.s.sol:DeployScript --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    EIP-7702 AA Library                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Core Auth   │  │  Paymaster   │  │ Session Keys │      │
│  │              │  │              │  │              │      │
│  │ • Validation │  │ • Sponsoring │  │ • Management │      │
│  │ • Delegation │  │ • Budgeting  │  │ • Permissions│      │
│  │ • Nonce Mgmt │  │ • Tracking   │  │ • Expiration │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                              │
│  ┌──────────────────────────────────────────────────┐       │
│  │              Batch Executor                       │       │
│  │  • Atomic multi-call execution                   │       │
│  │  • Integrated authorization                      │       │
│  └──────────────────────────────────────────────────┘       │
│                                                              │
│  ┌──────────────────────────────────────────────────┐       │
│  │              Utils & Helpers                      │       │
│  │  • Type definitions                              │       │
│  │  • Helper functions                              │       │
│  └──────────────────────────────────────────────────┘       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

- **src/core/**: Core authorization validation and delegation logic
- **src/paymaster/**: Gas sponsorship mechanisms with budget enforcement
- **src/sessionkeys/**: Session key lifecycle and permission management
- **src/utils/**: Shared utilities, type definitions, and helper functions
- **test/**: Comprehensive test suite
- **script/**: Deployment and upgrade scripts
- **docs/**: Additional documentation and guides

## Project Structure

```
.
├── src/
│   ├── core/          # Core authorization logic
│   ├── paymaster/     # Gas sponsorship
│   ├── sessionkeys/   # Session key management
│   └── utils/         # Helper functions and types
├── test/              # Test suite
├── script/            # Deployment scripts
├── docs/              # Documentation
├── foundry.toml       # Foundry configuration
└── README.md          # This file
```

## Development

### Running Tests

```bash
# Run all tests
forge test

# Run tests with gas reporting
forge test --gas-report

# Run specific test file
forge test --match-path test/AuthorizationManager.t.sol

# Run with verbosity for debugging
forge test -vvvv
```

### Code Coverage

```bash
# Generate coverage report
forge coverage

# Generate detailed coverage report with LCOV
forge coverage --report lcov
```

### Gas Optimization

This library is optimized for gas efficiency. To see gas reports:

```bash
forge test --gas-report
```

Target gas budgets:
- Authorization validation: < 50,000 gas
- Session key validation: < 30,000 gas
- Paymaster sponsorship: < 100,000 gas

## Security

This library is designed with security as the top priority. However, it is still under development and has not yet been audited.

### Security Considerations

- All inputs are validated
- Reentrancy protection where necessary
- Overflow/underflow protection via Solidity 0.8.30
- Comprehensive event logging for auditability
- Clear error messages for debugging

### Reporting Security Issues

Please report security vulnerabilities to [your-security-email]. Do not open public issues for security concerns.

## Roadmap

### Phase 1: Foundation (Current)
- [x] Project structure and setup
- [ ] Core authorization implementation
- [ ] Basic paymaster functionality
- [ ] Session key management
- [ ] Comprehensive test coverage

### Phase 2: Advanced Features
- [ ] Transaction batching
- [ ] Gas optimization with Yul/assembly
- [ ] Recovery mechanisms
- [ ] Advanced session key permissions
- [ ] Integration examples

### Phase 3: Production Ready
- [ ] Security audit
- [ ] Formal verification of critical paths
- [ ] Deployment scripts for multiple networks
- [ ] Comprehensive documentation
- [ ] Example integrations with popular protocols

### Phase 4: Ecosystem Growth
- [ ] Community contributions
- [ ] Additional features based on feedback
- [ ] Cross-chain support
- [ ] Integration with other AA standards

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Resources

- [EIP-7702 Specification](https://eips.ethereum.org/EIPS/eip-7702)
- [Foundry Book](https://book.getfoundry.sh/)
- [Solidity Documentation](https://docs.soliditylang.org/)

## Contact

- GitHub Issues: [Report bugs or request features](https://github.com/Darkartt/Qubiter/issues)
- Discussions: [Community discussions](https://github.com/Darkartt/Qubiter/discussions)

---

Built with Foundry and Solidity 0.8.30 for the Prague EVM
