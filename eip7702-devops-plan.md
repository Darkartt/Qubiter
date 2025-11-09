# EIP-7702 Account Abstraction Utilities Library
## Comprehensive DevOps & Development Plan

**Project Name:** eip7702-lib  
**Target:** Production-ready Solidity library  
**Timeline:** 20 weeks (Phases 1-3)  
**Tech Stack:** Solidity 0.8.30, Foundry, OpenZeppelin Contracts, Yul assembly  

---

## PHASE 1: Foundation & MVP (Weeks 1-6)

### Week 1-2: Project Setup & Architecture

#### 1.1 Repository Setup

**PROMPT FOR SONNET 4.5:**
```
Create a production-ready Foundry project structure for an EIP-7702 Account 
Abstraction library. Include:

1. Directory structure with:
   - src/core/ (core authorization logic)
   - src/paymaster/ (gas sponsorship)
   - src/sessionkeys/ (session key management)
   - src/utils/ (helper functions)
   - test/ (test files)
   - script/ (deployment scripts)
   - docs/ (documentation)

2. foundry.toml with:
   - Solidity version 0.8.30
   - Optimizer enabled (runs: 200)
   - EVM version: Prague
   - Gas reports enabled
   - Optimizer settings optimized for gas

3. README.md template with:
   - Project overview
   - Installation instructions
   - Quick start example
   - Features list
   - Roadmap

4. .gitignore for Foundry projects

5. GitHub Actions workflow for:
   - Testing on push/PR
   - Gas reports
   - Coverage reports

Start with minimal, focused structure. Prioritize clarity over features.
```

#### 1.2 Core Dependencies & Interfaces

**PROMPT FOR SONNET 4.5:**
```
Create the foundational interfaces and abstract contracts for EIP-7702 
authorization. Generate:

1. IEIP7702Authorization.sol interface with:
   - Function signatures for delegation authorization
   - Events for authorization and revocation
   - Error definitions
   - Documentation for each function

2. IPaymaster.sol interface with:
   - Function signatures for gas sponsorship
   - Validation and execution hooks
   - Budget tracking functions
   - Events for sponsorship events

3. ISessionKey.sol interface with:
   - Session key creation and revocation
   - Permission checking
   - Expiration handling
   - Events for lifecycle management

4. Types.sol library defining:
   - Authorization struct (authority, delegatedTo, nonce, validUntil)
   - SessionKeyPolicy struct (permissions, dailyLimit, allowedTargets, expiration)
   - PaymasterBudget struct (sponsor, budget, spent, allowed)

Use solidity 0.8.30 features. Include detailed natspec documentation.
Keep interfaces minimal and focused. No implementation yet.
```

### Week 3-4: Core Authorization Implementation

#### 1.3 Authorization Mechanism

**PROMPT FOR SONNET 4.5:**
```
Implement the core EIP-7702 authorization validation logic in AuthorizationManager.sol:

1. Core functions:
   - validateAuthorization(bytes memory auth, bytes32 digest) -> bool
   - recoverAuthority(bytes memory auth, bytes32 digest) -> address
   - checkNonce(address authority, uint256 currentNonce) -> bool
   - isAuthorizationExpired(uint256 validUntil) -> bool

2. Security features:
   - Replay attack prevention via nonce tracking
   - Signature recovery using ecrecover
   - Expiration validation
   - Authorization contract verification
   - Event logging for all validations

3. Implementation requirements:
   - Use unchecked arithmetic where safe
   - Implement storage efficiently (pack variables)
   - Gas optimize critical paths
   - Include comprehensive error messages
   - Use immutable for constants

4. Testing hooks:
   - Create testable function variants
   - Avoid dependencies on msg.sender initially
   - Make nonce tracking flexible

Use Solidity 0.8.30. Prioritize correctness over optimization.
Target gas: <50,000 for complete authorization validation.
Include detailed natspec for security assumptions.
```

#### 1.4 Basic Authorization Tests

**PROMPT FOR SONNET 4.5:**
```
Create comprehensive unit tests for AuthorizationManager in test/AuthorizationManager.t.sol:

1. Test categories:
   - Valid authorization acceptance
   - Invalid signature rejection
   - Nonce tracking and replay prevention
   - Expiration validation
   - Edge cases (zero addresses, overflow, underflow)

2. Test structure:
   - setUp() function initializing test signers
   - Helper functions for creating valid authorizations
   - Each test independently validates one scenario
   - Use Foundry's vm. features for advanced scenarios

3. Coverage requirements:
   - Every code path exercised
   - All error conditions tested
   - Boundary conditions validated
   - Gas measurements included

4. Test data:
   - Use deterministic test addresses
   - Fixed private keys for reproducibility
   - Multiple signers (authority, attacker, validator)
   - Various message formats

Write tests as if teaching someone the function's behavior.
Make test names descriptive and self-documenting.
Target >95% code coverage.
```

### Week 5-6: Gas Sponsorship MVP

#### 1.5 Paymaster Implementation

**PROMPT FOR SONNET 4.5:**
```
Implement basic gas sponsorship (paymaster) functionality in Paymaster.sol:

1. Core features:
   - Sponsor registration (address, initial budget)
   - Budget tracking per sponsor
   - Expenditure recording
   - Refund mechanisms
   - Rate limiting

2. Key functions:
   - registerSponsor(address sponsor) payable
   - sponsorTransaction(address target, bytes calldata data) -> bool
   - updateBudget(address sponsor, uint256 newBudget)
   - getBudgetRemaining(address sponsor) -> uint256
   - revokeSponsorship(address sponsor)

3. Security mechanisms:
   - Budget enforcement (prevent overspend)
   - Whitelist validation (approved targets)
   - Gas limit caps per transaction
   - Event logging for all operations
   - Owner authorization checks

4. Gas optimization:
   - Batch budget updates
   - Efficient storage packing
   - Unchecked arithmetic where safe
   - Minimal storage writes per operation

5. Integration:
   - Works with AuthorizationManager
   - Composable with session keys
   - Testable in isolation

Include error handling, events, and comprehensive documentation.
Target gas: <100,000 for sponsorship validation and execution.
```

#### 1.6 Paymaster Tests

**PROMPT FOR SONNET 4.5:**
```
Create comprehensive tests for Paymaster.sol in test/Paymaster.t.sol:

1. Test scenarios:
   - Sponsor registration and budget allocation
   - Successful gas sponsorship
   - Budget exhaustion handling
   - Unauthorized sponsorship rejection
   - Whitelist enforcement
   - Gas cap validation
   - Batch budget updates

2. Integration tests:
   - Paymaster + AuthorizationManager interaction
   - Multiple sponsors competing for budgets
   - Concurrent transactions
   - Refund scenarios

3. Edge cases:
   - Zero budget
   - Overflow/underflow protection
   - Empty whitelist
   - Revoked sponsorship
   - Expired authorizations

4. Gas profiling:
   - Gas cost per operation
   - Comparison with naive implementation
   - Optimization recommendations

Include setup fixtures and reusable helper functions.
Test both success and failure paths.
Target >95% code coverage.
```

---

## PHASE 2: Advanced Features & Optimization (Weeks 7-12)

### Week 7-8: Session Key Implementation

#### 2.1 Session Key Manager

**PROMPT FOR SONNET 4.5:**
```
Implement session key management in SessionKeyManager.sol with sophisticated 
permission models:

1. Core structures:
   - SessionKey struct: sessionKeyAddress, permissions, dailyLimit, spent, expiration
   - Permission enum: SWAP (swap tokens), TRANSFER (transfer tokens), 
     APPROVE (approve spending), INTERACT (arbitrary calls)
   - Session tracking per EOA

2. Key functions:
   - createSessionKey(address EOA, address sessionKey, uint256 expiration, 
                      bytes permissions, uint256 dailyLimit) -> sessionId
   - revokeSessionKey(address EOA, uint256 sessionId)
   - validateSessionKeyCall(address EOA, uint256 sessionId, address target, 
                            bytes calldata data) -> bool
   - checkDailyLimit(address EOA, uint256 sessionId, uint256 amount) -> bool
   - getSessionKey(address EOA, uint256 sessionId) -> SessionKey
   - refreshDailyLimit(address EOA, uint256 sessionId) // daily reset

3. Permission validation:
   - Granular permission checking
   - Target whitelist support
   - Function selector validation
   - Call data analysis

4. Security:
   - Expiration enforcement
   - Daily limit tracking with daily reset
   - Revocation tracking
   - Permission escalation prevention
   - Event logging

5. Storage optimization:
   - Pack SessionKey struct efficiently
   - Use bitmaps for permission tracking
   - Efficient daily limit reset (time-based)

Gas target: <80,000 per session key creation, <30,000 for validation.
Include comprehensive documentation of permission system.
```

#### 2.2 Session Key Tests

**PROMPT FOR SONNET 4.5:**
```
Create comprehensive tests for SessionKeyManager in test/SessionKeyManager.t.sol:

1. Session key lifecycle tests:
   - Creation with various permissions
   - Expiration validation
   - Revocation and re-creation
   - Multiple sessions per EOA
   - Session ID tracking

2. Permission validation tests:
   - Swap permission only allows swaps
   - Transfer permission restricted to transfers
   - Whitelist enforcement
   - Function selector validation
   - Permission combinations

3. Daily limit tests:
   - Tracking daily spending
   - Limit enforcement
   - Daily reset at UTC boundaries
   - Partial spending and re-checks
   - Limit updates

4. Edge cases:
   - Expired session usage attempts
   - Revoked session usage attempts
   - Zero limits
   - Very high limits
   - Multiple rapid calls
   - Timezone boundary conditions

5. Integration tests:
   - SessionKey + PaymasterManager
   - SessionKey + AuthorizationManager
   - Complex permission combinations

Include helper functions for creating sessions with various permissions.
Test both success and failure paths thoroughly.
Target >95% code coverage.
```

### Week 9-10: Transaction Batching

#### 2.3 Batch Transaction Executor

**PROMPT FOR SONNET 4.5:**
```
Implement atomic transaction batching in BatchExecutor.sol:

1. Core features:
   - Execute multiple operations atomically
   - Rollback on any failure
   - Individual operation gas measurement
   - Return data capture per operation
   - Authorization validation for batch

2. Key functions:
   - executeBatch(Call[] calldata calls, uint256 gasBudget) 
     -> (bool[] results, bytes[] returnData)
   - executeWithFallback(Call[] calldata calls, 
                         address fallbackTarget, bytes calldata fallbackData)
   - estimateBatchGas(Call[] calldata calls) -> uint256
   - validateBatchAuthorization(Call[] calldata calls, 
                               bytes memory auth) -> bool

3. Call structure:
   - struct Call { address target, uint256 value, bytes data }
   - Support for delegatecalls vs calls
   - Optional fallback for partial failures

4. Gas efficiency:
   - Minimal storage operations
   - Efficient loop implementation
   - Unchecked arithmetic where safe
   - Memory optimization for return data

5. Security:
   - Reentrancy protection
   - Gas limit enforcement
   - Authorization validation per call
   - Event logging for batch execution
   - Revert message capture

6. Integration:
   - Works with Paymaster
   - Works with SessionKeys
   - Works with AuthorizationManager

Gas target: <200,000 for 3-call batch including authorization.
```

#### 2.4 Recovery and Safety Features

**PROMPT FOR SONNET 4.5:**
```
Implement emergency recovery mechanisms in RecoveryManager.sol:

1. Features:
   - Recover EOA control from compromised session keys
   - Emergency pause on suspicious activity
   - History tracking of all operations
   - Activity monitoring thresholds

2. Key functions:
   - initializeRecovery(address EOA, address recoveryKey)
   - executeRecovery(address EOA) -> bool
   - pauseAllSessions(address EOA, string reason)
   - resumeSessions(address EOA)
   - getActivityLog(address EOA, uint256 limit) -> Operation[]
   - detectAnomalies(address EOA) -> bool

3. Recovery triggers:
   - Multiple failed authorization attempts
   - Spending above threshold in short period
   - Session key activity outside normal patterns
   - Guardian approval required

4. Security:
   - Time delays for recovery execution
   - Multi-signature for recovery approval
   - Activity logging
   - Guardian patterns support

5. Storage:
   - Activity log (circular buffer or truncated history)
   - Recovery state tracking
   - Pause status

Simple, focused implementation. Don't over-engineer.
Include adequate documentation of recovery flow.
```

### Week 11-12: Optimization & Assembly

#### 2.5 Gas Optimization Pass

**PROMPT FOR SONNET 4.5:**
```
Optimize critical paths in the EIP-7702 library using Yul assembly:

1. Target functions for assembly optimization:
   - validateAuthorization (currently hottest path)
   - validateSessionKeyCall
   - checkDailyLimit
   - sponsorTransaction

2. Optimization opportunities:
   - Batch storage reads/writes
   - Efficient permission bitmap checking
   - TSTORE/TLOAD usage for temporary state
   - Memory layout optimization
   - Inline small functions

3. Implementation:
   - Create OptimizedValidation.sol with Yul implementations
   - Maintain high-level Solidity wrappers for readability
   - Include extensive comments explaining assembly
   - Keep fallback to Solidity if needed

4. Benchmarking:
   - Measure gas before/after optimization
   - Target 15-25% gas reduction for hot paths
   - Document improvements for each function
   - Create gas report comparing versions

5. Safety:
   - Formal verification of critical assembly blocks if possible
   - Comprehensive testing of assembly variants
   - Clear documentation of assembly assumptions
   - Revert to Solidity option if issues found

Only optimize proven bottlenecks. Maintain code readability.
Include extensive natspec explaining assembly.
```

#### 2.6 Assembly Tests & Benchmarks

**PROMPT FOR SONNET 4.5:**
```
Create tests validating assembly optimization correctness in test/optimization/:

1. Correctness tests:
   - Assembly variants produce identical results to Solidity
   - Edge cases handled identically
   - Return values correct
   - Error conditions properly reported

2. Gas benchmarks:
   - Compare assembly vs Solidity for each function
   - Create gas report summarizing improvements
   - Identify remaining optimization opportunities
   - Document gas usage vs. alternatives (OpenZeppelin, etc.)

3. Regression tests:
   - Ensure optimizations don't introduce security issues
   - Test with fuzzing/property-based testing
   - Validate against specification

4. Profiling data:
   - Per-operation gas costs
   - Memory usage patterns
   - Storage access patterns
   - Comparison matrix vs alternative implementations

Create clear gas report showing improvements.
Use Foundry's gas measurement features.
Document findings for documentation.
```

---

## PHASE 3: Security, Audits & Launch (Weeks 13-20)

### Week 13-14: Comprehensive Testing

#### 3.1 Security-Focused Testing

**PROMPT FOR SONNET 4.5:**
```
Create advanced security tests for EIP-7702 library in test/security/:

1. Attack vector tests:
   - Reentrancy attacks on Paymaster
   - Authorization forgery attempts
   - Nonce reuse attacks
   - Session key permission escalation
   - Daily limit bypass attempts
   - Signature malleability
   - Transaction replay on different chains

2. Formal property tests:
   - "Authorization nonce always increases"
   - "Session key can't exceed daily limit"
   - "Revoked session keys can't execute"
   - "Sponsorship budget never exceeded"
   - "Authorization always validates correctly"

3. Fuzzing campaigns:
   - Fuzz validateAuthorization with random signatures
   - Fuzz SessionKey permission checking
   - Fuzz transaction batching
   - Fuzz daily limit logic with time manipulation
   - Fuzz sponsorship budget tracking

4. State machine testing:
   - Model expected state transitions
   - Verify implementation matches model
   - Test state consistency across operations

5. Interaction testing:
   - All components working together
   - Multiple simultaneous operations
   - Recovery from error conditions
   - Cleanup and state reset

Use Foundry's fuzzing, Echidna if needed. Document findings.
Create test report summarizing coverage and findings.
```

#### 3.2 Integration Tests

**PROMPT FOR SONNET 4.5:**
```
Create comprehensive integration tests in test/integration/:

1. End-to-end user flows:
   - User with only session key can interact with DeFi
   - Paymaster sponsoring transaction without user ETH
   - Batch swap + transfer with sponsorship
   - Recovery from compromised session key
   - Revocation and re-establishment of access

2. Multi-component scenarios:
   - SessionKey + PayMaster + AuthorizationManager + BatchExecutor
   - Concurrent operations from different session keys
   - Sponsorship with session key restrictions
   - Batch operations with mixed authorization types

3. Real protocol integrations:
   - Uniswap V3 integration example
   - Token transfer and approval flows
   - NFT marketplace interactions (if applicable)
   - Liquidity pool operations

4. Performance tests:
   - Gas costs for realistic user flows
   - Throughput under load
   - Storage growth over time
   - Optimization effectiveness validation

5. Failure scenarios:
   - Handling failed calls in batch
   - Recovery from out-of-gas
   - Handling paused contracts
   - Network state changes during execution

Create realistic, production-like test scenarios.
Include performance profiling and optimization suggestions.
```

### Week 15: Documentation & Examples

#### 3.3 Developer Documentation

**PROMPT FOR SONNET 4.5:**
```
Create comprehensive developer documentation structure:

1. docs/ARCHITECTURE.md:
   - System design overview
   - Component interactions diagram (in ASCII)
   - Data flow diagrams
   - Security model explanation
   - Authorization flow breakdown

2. docs/API_REFERENCE.md:
   - Complete API documentation
   - Function signatures with parameters
   - Return values
   - Possible errors
   - Gas costs per function
   - Example usage for each function

3. docs/SECURITY.md:
   - Security assumptions
   - Known limitations
   - Attack vectors considered
   - Mitigation strategies
   - Recovery procedures
   - When NOT to use this library

4. docs/EXAMPLES.md:
   - Basic authorization example
   - Paymaster sponsorship example
   - Session key creation example
   - Batch transaction example
   - Real DeFi protocol integration examples

5. docs/DEPLOYMENT.md:
   - Deployment instructions
   - Network-specific configurations
   - Verification on block explorers
   - Post-deployment validation
   - Upgrade procedures

6. docs/PERFORMANCE.md:
   - Gas benchmarks
   - Performance comparisons
   - Optimization tips
   - When to use assembly vs. Solidity

Write for developers with varying Solidity expertise.
Include code examples that can be copy-pasted.
Keep explanations clear and concise.
```

#### 3.4 Example Implementations

**PROMPT FOR SONNET 4.5:**
```
Create practical example implementations in examples/:

1. examples/SimpleGasSponsor.sol:
   - Basic dApp implementing gas sponsorship
   - Accept sponsored swaps
   - Budget enforcement
   - Full working example with tests

2. examples/SessionKeyWallet.sol:
   - Mobile wallet using session keys
   - Create restricted session keys for different apps
   - Manage expiration and permissions
   - Recovery mechanisms

3. examples/DAOVoting.sol:
   - DAO voting using signature aggregation
   - Transaction batching for atomic proposals
   - Sponsorship for voter participation
   - Complete working DAO example

4. examples/MultiSigWallet.sol:
   - Multi-signature wallet using EIP-7702
   - Authorization aggregation
   - Gas-efficient multi-sig operations
   - Full implementation

5. examples/DeFiBot.sol:
   - Automated trading bot using session keys
   - Daily limits on risky operations
   - Emergency stop mechanisms
   - Production-ready example

Each example:
- Fully commented
- Includes deployment script
- Includes test suite
- Shows gas costs
- Documents assumptions
- Production-quality code

Create ready-to-deploy examples developers can learn from.
```

### Week 16: Security Audit Preparation

#### 3.5 Audit Readiness

**PROMPT FOR SONNET 4.5:**
```
Prepare EIP-7702 library for professional security audits:

1. Code documentation:
   - Comprehensive natspec for all public functions
   - Security considerations documented
   - Implementation notes explaining critical sections
   - Links to relevant EIPs and standards

2. Specification document:
   - Formal specification of expected behavior
   - Security properties that must hold
   - Assumptions about usage
   - Edge cases and boundary conditions
   - Links to external standards

3. Test coverage report:
   - Line-by-line coverage analysis
   - Critical path coverage verification
   - Test case descriptions
   - Known limitations

4. Vulnerability analysis:
   - Self-review of common vulnerabilities
   - Justification for why they're mitigated
   - Residual risks documented
   - Security model explanation

5. Architecture documentation:
   - Component roles and responsibilities
   - Interface specifications
   - Data flow through system
   - Trust assumptions

6. Known issues:
   - Any known limitations
   - Performance tradeoffs
   - Future improvements planned
   - Version history

Create professional, audit-ready documentation.
Make it easy for auditors to understand system.
Highlight critical sections needing review.
```

#### 3.6 Preparation Checklist

**PROMPT FOR SONNET 4.5:**
```
Create audit preparation checklist in AUDIT_CHECKLIST.md:

Verification:
- [ ] All tests passing (>95% coverage)
- [ ] No warnings in compiler output
- [ ] Gas optimizations implemented
- [ ] Documentation complete
- [ ] Examples working correctly
- [ ] All security considerations documented

Code Quality:
- [ ] Consistent code style
- [ ] No unused variables or imports
- [ ] Error messages clear and helpful
- [ ] Comments explain WHY not just WHAT
- [ ] Natspec complete for all public functions

Security:
- [ ] Input validation on all functions
- [ ] Reentrancy guards where needed
- [ ] Integer overflow/underflow checked
- [ ] Authorization properly validated
- [ ] No delegatecall to untrusted targets
- [ ] Events emitted for state changes

Testing:
- [ ] Unit tests comprehensive
- [ ] Integration tests cover real flows
- [ ] Fuzzing completed
- [ ] Edge cases tested
- [ ] Error conditions tested
- [ ] Performance profiled

Documentation:
- [ ] README complete and clear
- [ ] API reference complete
- [ ] Architecture documented
- [ ] Examples functional
- [ ] Deployment guide complete
- [ ] Security assumptions clear

List everything auditors will check.
Make it actionable and measurable.
```

### Week 17-18: Formal Verification (Optional but Recommended)

#### 3.7 Formal Verification Prep

**PROMPT FOR SONNET 4.5:**
```
Prepare critical functions for formal verification using Certora or SMTChecker:

1. Target functions for formal verification:
   - validateAuthorization (correctness critical)
   - checkDailyLimit (safety critical)
   - sponsorTransaction (budget correctness)
   - revokeSessionKey (state consistency)

2. Formal properties to verify:
   - Authorization validation is sound (valid sigs accept, invalid reject)
   - Nonce prevents replay attacks
   - Daily limits are enforced correctly
   - Budgets never exceeded
   - Revoked sessions can't execute
   - State transitions are correct

3. For each function:
   - Write formal preconditions
   - Write formal postconditions
   - Document state invariants
   - Specify safety properties

4. Implementation:
   - Create spec files for formal verification tool
   - Add assertion statements for invariant checking
   - Document verification results
   - Create formal correctness report

This is optional but significantly increases audit confidence.
Choose one tool (Certora preferred for industry adoption).
Focus on highest-value verification targets.
```

### Week 19: Launch Preparation

#### 3.8 Mainnet Deployment

**PROMPT FOR SONNET 4.5:**
```
Create mainnet deployment strategy and scripts in script/:

1. script/Deploy.s.sol:
   - Core library deployments
   - Initialization functions
   - Parameter setting
   - Verification script
   - Post-deployment validation

2. Deployment checklist:
   - [ ] Testnet deployment successful
   - [ ] All tests passing
   - [ ] Gas estimates documented
   - [ ] Audits completed
   - [ ] Emergency pause mechanism ready
   - [ ] Monitoring set up
   - [ ] Communication plan ready

3. Multi-network deployment:
   - Ethereum mainnet
   - Optimism, Arbitrum (L2s)
   - Polygon
   - Other EVM-compatible chains
   - Same contract addresses (create2 or manually coordinate)

4. Verification:
   - Etherscan verification for each deployment
   - Build verification against published source
   - Block explorer display correctly
   - Contract interaction works on block explorer

5. Monitoring setup:
   - Event monitoring
   - Error tracking
   - Gas usage monitoring
   - Anomaly detection

6. Communication plan:
   - Launch announcement timing
   - Discord/Twitter threads
   - Blog post
   - Partners to notify
   - Community builders to reach out

Create reproducible, tested deployment scripts.
Document all parameters and assumptions.
```

#### 3.9 Launch Communications

**PROMPT FOR SONNET 4.5:**
```
Create launch communications templates:

1. Twitter/X announcement thread:
   - Hook about solving account abstraction
   - Problem statement
   - Solution overview
   - Key features
   - Links and calls to action
   - Engagement questions

2. Blog post outline (for separate publication):
   - Why EIP-7702 matters
   - Problems this library solves
   - How it works (conceptual)
   - Getting started guide
   - Use cases and examples
   - Future roadmap

3. Discord/Community announcement:
   - Library overview
   - Where to learn more
   - How to integrate
   - Support channels
   - Contribution opportunities

4. Partner outreach template:
   - Library overview
   - Integration opportunities
   - Benefits for their users
   - Support offered
   - Contact for questions

5. Technical documentation for devs:
   - Installation instructions
   - Quick start
   - API overview
   - Example code
   - Support channels

Make communications clear and compelling.
Emphasize benefits, not just features.
Include clear next steps for developers.
```

### Week 20: Post-Launch Maintenance

#### 3.10 Ongoing Maintenance Plan

**PROMPT FOR SONNET 4.5:**
```
Create post-launch maintenance and support plan:

1. Immediate (Week 1-2 post-launch):
   - Monitor for issues/reports
   - Quick bug fix turnaround
   - Community support active
   - Performance monitoring
   - Security alert system

2. Short-term (Month 1):
   - Bug fixes and patches
   - Documentation improvements based on feedback
   - Example expansion based on requests
   - Community integration support
   - Early adopter relationship building

3. Medium-term (Months 2-3):
   - Version 1.1 with community features
   - Additional examples and integrations
   - Performance optimization Round 2
   - Integration with more protocols
   - Growing ecosystem

4. Long-term roadmap:
   - Integration with other EIP-7702 implementations
   - Additional features based on adoption patterns
   - Compatibility with new Solidity versions
   - Layer 2 specific optimizations
   - Cross-chain capabilities

5. Support structure:
   - GitHub issues for bugs
   - Discussions for questions
   - Discord channel for community
   - Weekly community calls
   - Quarterly AMA sessions

6. Metrics to track:
   - GitHub stars and forks
   - NPM/Soldeer downloads
   - Integrations (projects using library)
   - TVL in protocols using library
   - Community contributions

Create sustainable maintenance plan.
Plan for scaling support as adoption grows.
Build community ownership gradually.
```

---

## SONNET 4.5 MASTER PROMPTS BY PHASE

### MASTER PROMPT TEMPLATE - Core Implementation

```
You are building an EIP-7702 Account Abstraction Utilities library for Solidity.
This is a production-quality library that will be audited and used by major protocols.

CONTEXT:
- Target: Solidity 0.8.30, EVM Prague
- Focus: Security > Optimization > Features
- Goal: Standard library for account abstraction patterns

REQUIREMENTS:
1. Implementation:
   [SPECIFIC_FUNCTION_REQUIREMENTS]

2. Security:
   - Input validation on all parameters
   - Reentrancy protection where needed
   - Overflow/underflow protection
   - Authorization checks
   - Event logging for auditing
   - Clear error messages

3. Gas Efficiency:
   - Target gas budget: [X_GAS]
   - Use unchecked where safe (overflow impossible)
   - Pack storage efficiently
   - Minimize storage operations
   - Consider TSTORE for temporary data

4. Testing & Validation:
   - Write comprehensive tests
   - >95% code coverage
   - Edge cases and error paths
   - Gas measurement
   - Clear test names

5. Documentation:
   - Natspec for all public functions
   - Comments explaining security decisions
   - Example usage
   - Known limitations

DELIVERABLES:
1. Implementation file(s) with complete code
2. Comprehensive test file
3. Documentation/comments in code
4. Example usage showing typical flow

QUALITY STANDARDS:
- Production-ready code
- Audit-safe implementation
- No external dependencies unless absolutely necessary
- Clear, maintainable structure
- Security-first approach

START WITH:
[SPECIFIC_INSTRUCTION]
```

### MASTER PROMPT TEMPLATE - Testing & Validation

```
Create comprehensive tests for [CONTRACT_NAME] in Foundry.

CONTRACT INTERFACE:
[COPY_INTERFACE_OR_KEY_FUNCTIONS]

TEST REQUIREMENTS:
1. Test Categories:
   - Happy path (normal usage)
   - Error paths (all error conditions)
   - Edge cases (boundaries, zeros, max values)
   - Integration (working with other components)
   - Gas profiling (measure gas costs)

2. Test Coverage:
   - Every code path
   - All error conditions
   - State changes verified
   - Events verified
   - Authorization validated

3. Test Quality:
   - Descriptive test names
   - Clear test structure
   - Reusable helper functions
   - Isolated tests (no dependencies)
   - Proper assertions

4. Helper Functions:
   - Create valid [OBJECTS]
   - Create invalid [OBJECTS]
   - Assert state changes
   - Verify events

DELIVERABLES:
1. Complete test file with 100% coverage potential
2. Clear documentation of test organization
3. Helper functions for test data creation
4. Gas measurements and analysis

QUALITY: Tests should teach readers how function should behave.
```

### MASTER PROMPT TEMPLATE - Documentation

```
Create documentation for the [MODULE] component of EIP-7702 library.

COMPONENT: [NAME]
PURPOSE: [PURPOSE]
KEY_FUNCTIONS: [FUNCTION_LIST]

DOCUMENTATION REQUIREMENTS:
1. Architecture Overview:
   - Purpose and role
   - How it fits in system
   - Key responsibilities
   - Assumptions and constraints

2. API Reference:
   - Complete function documentation
   - Parameters and return values
   - Possible errors
   - Event descriptions
   - Gas costs

3. Security Model:
   - Security assumptions
   - Trust model
   - Attack vectors considered
   - Mitigations implemented
   - Known limitations

4. Usage Examples:
   - Basic usage
   - Common patterns
   - Integration with other modules
   - Error handling

5. Implementation Notes:
   - Why certain design decisions
   - Performance characteristics
   - Storage layout explanation
   - Optimization notes

DELIVERABLES:
1. README for module
2. API reference document
3. Security documentation
4. Multiple usage examples
5. Architecture diagram (ASCII acceptable)

AUDIENCE: Expert Solidity developers
```

---

## QUICK REFERENCE: PROMPT SEQUENCE

### For Implementation (Use master template with specifics):
1. "Implement [Module] with [specific requirements]"
2. "Create tests for [Module]"
3. "Optimize [Function] for gas"
4. "Create documentation for [Module]"
5. "Create examples showing [Use Case]"

### For Testing:
1. "Create unit tests for [Contract]"
2. "Add integration tests for [Components]"
3. "Create fuzzing tests for [Functions]"
4. "Create security tests for [Scenarios]"
5. "Generate gas reports"

### For Documentation:
1. "Create API reference for [Module]"
2. "Explain security model for [Feature]"
3. "Create examples for [Use Case]"
4. "Create deployment guide"
5. "Create developer guide"

---

## SUCCESS CRITERIA

### Code Quality
- [ ] Passes all tests (>95% coverage)
- [ ] No compiler warnings
- [ ] Follows consistent code style
- [ ] Clear, commented code
- [ ] Production-ready quality

### Security
- [ ] All attack vectors considered
- [ ] Input validation complete
- [ ] Reentrancy protected
- [ ] Overflow/underflow protected
- [ ] Security audit passed

### Performance
- [ ] Meets gas budgets
- [ ] Optimizations implemented
- [ ] Gas profiling complete
- [ ] Competitive with alternatives
- [ ] Benchmarks documented

### Documentation
- [ ] Comprehensive API docs
- [ ] Working examples
- [ ] Architecture documented
- [ ] Security model clear
- [ ] Deployment guide ready

### Adoption
- [ ] Early integrations
- [ ] Community support
- [ ] Positive feedback
- [ ] Active maintenance
- [ ] Growing ecosystem
