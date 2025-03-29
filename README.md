# Renewable Trade Contract - Smart Contract

## Overview
The **Renewable Trade Contract** is a blockchain-based smart contract designed for trading renewable energy resources. It facilitates transactions between users who wish to buy and sell energy in kilowatt-hours (kWh) using STX (Stacks cryptocurrency). The contract ensures secure and fair transactions while maintaining system-wide limits and fee structures.

## Features
- **Set Pricing:** Admin can set unit prices for energy.
- **Service Fees:** A service charge is deducted on each trade.
- **Refund System:** Users can return excess energy for partial refunds.
- **Resource Trading:** Users can list, buy, and remove energy from the market.
- **Storage Management:** Limits exist to prevent resource hoarding.
- **Security Measures:** Prevents unauthorized actions and self-trading.

## Smart Contract Variables
- **unit-price**: The cost of 1 kWh in microstacks.
- **user-quota**: Maximum energy a user can trade.
- **fee-rate**: Percentage charged as a transaction fee.
- **refund-rate**: Percentage refunded when users return energy.
- **system-cap**: Maximum energy storage allowed in the contract.
- **active-stock**: Current total energy stored in the contract.

## Data Mappings
- **holdings**: Tracks each user's energy balance.
- **stx-wallet**: Stores each user's STX balance.
- **market**: Lists available energy sales.

## Functions
### Admin Functions
1. **set-unit-price(price uint)** – Set the price per kWh.
2. **set-fee-rate(rate uint)** – Define the service charge percentage.
3. **set-refund-rate(rate uint)** – Set the percentage refunded on returns.
4. **set-system-cap(limit uint)** – Adjust the system's max energy limit.

### User Functions
1. **list-resource(quantity uint, price uint)** – Add energy to the market.
2. **delist-resource(quantity uint)** – Remove listed energy from sale.
3. **purchase(seller principal, quantity uint)** – Buy energy from a seller.

## Read-Only Functions
1. **get-unit-price()** – Returns the current unit price.
2. **get-fee-rate()** – Returns the transaction fee percentage.
3. **get-refund-rate()** – Returns the refund percentage.
4. **get-holdings(user principal)** – Returns a user's energy balance.
5. **get-stx-wallet(user principal)** – Returns a user's STX balance.
6. **get-market(user principal)** – Returns a user's active listings.
7. **get-active-stock()** – Returns the total stored energy.
8. **get-system-cap()** – Returns the system's max storage capacity.

## Security Measures
- Only the admin can modify system settings.
- Users cannot trade with themselves.
- Transactions ensure adequate balance checks.
- Storage limits prevent exceeding system capacity.

## Usage
This contract enables decentralized energy trading while ensuring fair pricing and security through smart contract logic. It allows users to efficiently trade renewable energy using STX.
