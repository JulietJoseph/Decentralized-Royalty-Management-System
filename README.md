# Royalty Management System

## Overview
The **Royalty Management System** is a smart contract designed to manage royalties for NFTs in a dynamic and scalable way. It enables NFT creators to set up royalties that dynamically adjust based on the number of sales, rewarding creators while promoting sustainability in secondary markets.

This system includes functionalities for registering NFTs with a base royalty, updating royalties as sales occur, and calculating adjusted royalties based on predefined rules.

---

## Features
- **NFT Registration**: Contract owners can register NFTs with a base royalty percentage.
- **Dynamic Royalties**: Royalties decrease proportionally with the number of sales, ensuring a fair reward system.
- **Sale Tracking**: Keeps track of the number of sales for each NFT.
- **Royalty Streaming**: NEW! Subscription-based creator support with tiered streaming payments.
- **Creator Subscriptions**: Supporters can subscribe to creators with flexible tier-based commitments.
- **Streaming Payments**: Automated recurring payments to creators based on subscription tiers.
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

## Royalty Streaming Feature

The **Royalty Streaming** contract introduces a revolutionary subscription-based model for continuous creator support, enabling fans and collectors to establish ongoing financial relationships with content creators through flexible tier-based streaming payments.

### Core Concepts

#### Subscription Tiers
Creators can establish multiple subscription tiers with different benefits and pricing:
- **Tier Configuration**: Name, monthly cost, minimum commitment period, and benefit descriptions
- **Flexible Pricing**: Each tier can have different cost structures and commitment requirements
- **Benefit Descriptions**: Detailed explanations of what subscribers receive at each level

#### Streaming Subscriptions
Supporters can subscribe to creators with automated recurring payments:
- **Automated Payments**: Regular payments processed according to subscription terms
- **Flexible Commitments**: Variable commitment periods based on tier requirements
- **Subscriber Controls**: Ability to upgrade, pause, resume, or cancel subscriptions

### Key Functions

#### Creator Functions
```clarity
;; Set up subscription tiers
(create-subscription-tier u1 "Basic Support" u100000 u30 "Monthly updates and early access")

;; Register as creator with streaming profile
(register-creator-profile "Artist Name" (list u1 u2 u3))

;; Claim accumulated streaming payments
(claim-stream-payment u1)
```

#### Subscriber Functions
```clarity
;; Subscribe to a creator's stream
(subscribe-to-stream 'SP123...CREATOR u1 u90) ;; tier-id=1, 90-day commitment

;; Upgrade to higher tier
(upgrade-subscription 'SP123...CREATOR u2)

;; Pause subscription temporarily
(pause-subscription 'SP123...CREATOR)

;; Resume paused subscription
(resume-subscription 'SP123...CREATOR)

;; Cancel subscription entirely
(cancel-subscription 'SP123...CREATOR)
```

#### Read-Only Queries
```clarity
;; Get tier information
(get-subscription-tier u1)

;; Check creator profile
(get-creator-profile 'SP123...CREATOR)

;; View subscription details
(get-subscription 'SP456...SUBSCRIBER 'SP123...CREATOR)

;; Check stream payment details
(get-stream-payment u1)
```

### Integration Benefits

1. **Predictable Revenue**: Creators receive consistent income through subscription commitments
2. **Fan Engagement**: Direct financial relationship between creators and supporters
3. **Flexible Tiers**: Multiple support levels accommodate different supporter capacities
4. **Automated Processing**: Smart contract handles payment processing and tier management
5. **Transparent Operations**: All transactions and commitments recorded on-chain

### Usage Scenarios

- **Content Creators**: Artists, musicians, and writers can establish fan funding streams
- **NFT Projects**: Ongoing support for continued development and community building
- **Gaming**: Support for game developers with tier-based early access and benefits
- **Educational Content**: Subscription-based learning platforms with progressive access

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