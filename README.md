# Royalty Management System

## Overview
The **Royalty Management System** is a smart contract designed to manage royalties for NFTs in a dynamic and scalable way. It enables NFT creators to set up royalties that dynamically adjust based on the number of sales, rewarding creators while promoting sustainability in secondary markets.

This system includes functionalities for registering NFTs with a base royalty, updating royalties as sales occur, and calculating adjusted royalties based on predefined rules.

---

## Features
- **NFT Registration**: Contract owners can register NFTs with a base royalty percentage.
- **Dynamic Royalties**: Royalties decrease proportionally with the number of sales, ensuring a fair reward system.
- **Sale Tracking**: Keeps track of the number of sales for each NFT.
- **Error Handling**: Includes robust error handling for unauthorized actions, invalid data, and non-existent NFTs.
- **Comprehensive Tests**: All functionalities are tested using Vitest.

---

## Smart Contract Functions

### Public Functions
1. **`register-nft (token-id uint, base-royalty uint)`**
   - Registers an NFT with a base royalty percentage.
   - **Parameters**:
     - `token-id`: Unique identifier for the NFT.
     - `base-royalty`: Initial royalty percentage (max: 100%).
   - **Returns**: Success or error code.

2. **`update-royalty (token-id uint)`**
   - Updates the royalty for an NFT after a sale.
   - **Parameters**:
     - `token-id`: Unique identifier for the NFT.
   - **Returns**: Updated royalty or error code.

### Read-Only Functions
1. **`get-nft-royalty (token-id uint)`**
   - Fetches the royalty details for a specific NFT.
   - **Parameters**:
     - `token-id`: Unique identifier for the NFT.
   - **Returns**: NFT royalty details or `null`.

2. **`calculate-dynamic-royalty (base-royalty uint, sale-count uint)`**
   - Computes the adjusted royalty based on the base royalty and the number of sales.
   - **Parameters**:
     - `base-royalty`: Initial royalty percentage.
     - `sale-count`: Total number of sales for the NFT.
   - **Returns**: Adjusted royalty percentage.

---

## Data Structures
- **`nft-royalties`**  
  A data map storing the following fields:
  - `creator`: The NFT creator’s principal address.
  - `base-royalty`: The initial royalty percentage.
  - `sale-count`: The total number of sales for the NFT.
  - `current-royalty`: The dynamically adjusted royalty percentage.

---

## Error Codes
- **`ERR_NOT_AUTHORIZED (100)`**: Thrown when a non-owner attempts unauthorized actions.
- **`ERR_NFT_NOT_FOUND (101)`**: Thrown when operations are attempted on a non-existent NFT.
- **`ERR_INVALID_PERCENTAGE (102)`**: Thrown when the royalty percentage exceeds 100%.

---

## Tests
Comprehensive tests are included to validate all functionalities:
- Registration of NFTs with valid and invalid royalties.
- Dynamic royalty adjustments after multiple sales.
- Handling of unauthorized actions and non-existent NFTs.

Run tests using **Vitest** to ensure the integrity of the system.  
Example:
```bash
npm run test
```

---

## Installation and Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/your-repo-url
   cd royalty-management-system
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Run tests:
   ```bash
   npm run test
   ```

---

## Usage Example
### Register an NFT
```clarity
(register-nft u1 u20)
```

### Update NFT Royalty After a Sale
```clarity
(update-royalty u1)
```

### Fetch NFT Details
```clarity
(get-nft-royalty u1)
```

---

## Future Improvements
- Add support for fractional royalties for more flexibility.
- Integrate marketplace smart contracts for automated royalty distribution.
- Enhance the dynamic royalty algorithm with more customizable rules.

---

## License
This project is licensed under the MIT License. See the `LICENSE` file for more details.