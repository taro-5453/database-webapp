# Momo Paradise – Database Project

A database system for a multi-branch all-you-can-eat shabu/sukiyaki
restaurant chain, supporting reservations, queues, buffet dining
sessions, ordering, billing, membership, and promotions.

Course: ICCS 225 Database Foundations — Term 2025-26 T3

## Team
- Chaiyanun Sakulsaowapakkul 6681299
- 
- 

## Tech Stack
- Database: PostgreSQL (hosted on Render)
- Tooling: DataGrip

## Repository Structure
- `database/` — schema and sample data
  - `schema.sql` — creates all 14 tables (keys, constraints, indexes)
  - `sample_data.sql` — sample rows for every table
- `function/` — SQL functions that feed each screen
- `document/` — report and ER diagram
- `UI Pages/` — screenshots and Figma wireframes

## Database
- 14 tables, normalized, with foreign keys and CHECK constraints
- Security: passwords stored as hashes; least-privilege access
- Efficiency: indexes on frequently queried columns

## How to Run
1. Create a PostgreSQL database (e.g. on Render).
2. Run `database/schema.sql` to create the tables.
3. Run `database/sample_data.sql` to populate sample data.