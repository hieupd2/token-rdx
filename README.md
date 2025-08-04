# token_rdx

A Sui Move package implementing the RDX token standard with support for:

- Minting new RDX coins (with supply cap via `TreasuryCap`)
- Burning RDX coins (full or partial)
- Transferring full or partial amounts between addresses

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Project Structure](#project-structure)
- [Key Modules & Functions](#key-modules--functions)
- [Running Tests](#running-tests)
- [Test Coverage](#test-coverage)
- [Usage Examples](#usage-examples)

---

## Prerequisites

- [Install Sui](https://docs.sui.io/build/install)

---

## Setup

1. Clone this repository:

   ```bash
   git clone https://github.com/hieupd2/token-rdx.git
   cd token-rdx
   ```

2. Install dependencies and build

   ```powershell
   sui move build
   ```

---

## Project Structure

```
token-rdx/
├─ Move.toml          # Package configuration & dependencies
├─ sources/
│  └─ token_rdx.move  # Main RDX module with functions: mint, burn, transfer, etc.
├─ tests/
│  ├─ mint_tests.move
│  ├─ transfer_tests.move
│  ├─ transfer_amount_tests.move
│  └─ burn_amount_tests.move
└─ README.md         
```

---

## Key Modules & Functions

- **`RDX`**: The RDX coin.
- **`mint`**: Public entry to mint new coins (requires `TreasuryCap`).
- **`burn` / `burn_amount`**: burn coins fully or partially.
- **`transfer` / `transfer_amount`**: Send whole or partial coin amounts.
- **`test_init`**: Test-only initializer for Move unit tests.

---

## Running Tests

Execute all Move unit tests with:

```powershell
sui move test
```

---

## Test Coverage

Generate a coverage report with:

```powershell
sui move test --coverage
sui move coverage summary
```

---
