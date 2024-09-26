# Blockchain Disaster Recovery Fund Project
## Overview
This project implements a **blockchain-based disaster relief fund** system designed to manage
donations, allocate funds to recipients, and allow verified beneficiaries to withdraw funds. The
project consists of three smart contracts:
1. **Disaster-Relief Contract**: Manages donations, recipients, and fund withdrawals.
2. **Governance Contract**: Handles administrative functions and defines rules like minimum
donation amounts and withdrawal limits.
3. **Utility Contract**: Provides common functions and safeguards for secure mathematical
operations and validation checks.
The system ensures transparency and security in disaster recovery efforts by leveraging blockchain
technology, allowing global participation through donations and providing strict governance to
prevent misuse.
## Features
- **Donations**: Accepts donations from any user within defined minimum and maximum limits.
- **Recipients**: Admin can add verified recipients who are eligible to withdraw funds.
- **Fund Allocation**: Each recipient is allocated a specific amount of funds, which they can
withdraw based on the allocated limit.
- **Withdrawal Cooldown**: Enforces a cooldown period between withdrawals for each recipient to
ensure fair fund distribution.
- **Administrative Control**: The admin can update key contract parameters like donation limits,
recipient allocation, and pause/unpause the contract in emergency situations.
- **Governance Policies**: Admin can adjust rules for minimum donations and maximum withdrawal
amounts, ensuring adaptability to different disaster scenarios.
## Project Structure
### 1. **Disaster-Relief Contract**
The core contract for handling donations and fund withdrawals. It allows anyone to donate, tracks
the donations, and manages verified recipients who can withdraw funds.
#### Key Functions:
- **donate(amount)**: Allows anyone to donate to the fund within the defined donation limits.
- **add-recipient(recipient, allocation)**: Admin function to add new recipients who can withdraw
funds up to their allocation.
- **withdraw(amount)**: Allows verified recipients to withdraw funds after checking eligibility and
withdrawal cooldown.
- **get-donation(user)**: Read-only function to check how much a user has donated.
- **get-recipient-allocation(recipient)**: Read-only function to check a recipient's allocated funds.

### 2. **Governance Contract**
The governance contract provides the administrative functionality to update donation rules,
withdrawal limits, and set a new admin. It works as a controller to regulate disaster-relief operations.
#### Key Functions:
- **set-admin(new-admin)**: Allows the current admin to transfer control to a new admin.
- **set-min-donation(amount)**: Admin function to update the minimum donation amount.
- **set-withdrawal-limit(amount)**: Admin function to update the maximum amount a recipient can
withdraw.

### 3. **Utility Contract**
The utility contract provides shared functions for the disaster-relief and governance contracts,
ensuring secure arithmetic operations and validating input data.
#### Key Functions:
- **is-valid-principal(user)**: Checks if a principal is valid (either a contract or standard principal).
- **safe-add(a, b)**: Secure addition function to prevent overflow.
- **safe-subtract(a, b)**: Secure subtraction function to prevent underflow.
- **safe-divide(a, b)**: Secure division function with zero-division protection.
## How It Works
1. **Donations**: Users can send donations to the contract using the `donate` function, ensuring the
amount is within the specified limits.
2. **Adding Recipients**: The admin adds verified recipients using the `add-recipient` function,
allocating them a fixed amount they can withdraw.
3. **Fund Withdrawal**: Recipients can withdraw funds up to their allocated limit, respecting a
cooldown period between withdrawals to prevent abuse.
4. **Administrative Functions**: The admin can modify key parameters such as donation limits,
recipient allocations, and the paused state of the contract to handle exceptional circumstances.
## Admin Functions and Governance
The governance contract enables administrative control over the disaster-relief contract. The admin
can:
- Transfer admin rights using the `set-admin` function.
- Update the donation limits to adapt to new situations.
- Control the maximum withdrawal amount for recipients to ensure funds are distributed fairly during
disaster recovery.
## Cooldown and Security Measures
To prevent abuse, withdrawals are subject to a **cooldown period** (24 hours), enforced by the
contract. Additionally, the **paused state** ensures that the admin can temporarily disable all
operations (donations and withdrawals) during emergencies or system upgrades.
## Installation and Deployment
To deploy the contracts, follow these steps:
1. **Install the required tools**:
 Ensure you have a blockchain development environment set up, such as
[Clarinet](https://clarinet.dev/) for Clarity smart contracts.
2. **Compile the contracts**:
 Run the following command to compile the contracts:
 ```
 clarinet compile
 ```
3. **Deploy the contracts**:
 Deploy the contracts to your preferred blockchain testnet (e.g., Stacks testnet):
 ```
 clarinet deploy
 ```
4. **Interact with the contract**:
 Use the following example to donate funds:
 ```clarity
 (contract-call? .disaster-relief donate u500)
 ```
## Tests
Unit tests are included to verify the functionality of the core and governance contracts. To run tests,
use:
```
clarinet test
```
## Future Improvements
- **Recipient Verification**: Add automated recipient verification systems using blockchain oracles.
- **Advanced Governance**: Implement decentralized governance allowing stakeholders to vote on
changes to contract parameters.
- **Multi-Currency Donations**: Support donations in multiple currencies or tokens.