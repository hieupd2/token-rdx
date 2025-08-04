# token_rdx

A Sui Move package implementing the RDX token standard with support for:

- Everyone can mint new RDX coins, no fix cap
- Burning RDX coins (full or partial)
- Transferring full or partial amounts between addresses


## Table of Contents

- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Running Tests](#running-tests)
- [Test Coverage](#test-coverage)


## Prerequisites

- [Install Sui](https://docs.sui.io/build/install)


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


## Running Tests

Execute all Move unit tests with:

```powershell
sui move test
```


## Test Coverage

Generate a coverage report with:

```powershell
sui move test --coverage
sui move coverage summary
```

