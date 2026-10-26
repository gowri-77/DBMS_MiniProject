# Supply Chain Traceability System

A web-based supply chain inventory and traceability application built using Next.js and PostgreSQL.

## Features

### 1. Warehouse Inventory Dashboard
- Displays warehouse information.
- Shows units in stock, batches held, and warehouse utilisation.
- Retrieves data from PostgreSQL.

### 2. Batch Management
- Displays batch information.
- Shows product names, batch codes, expiry dates, and available quantities.
- Highlights expiry information to help monitor batches.

### 3. Low Stock Monitoring
- Displays warehouse stock records returned by the low-stock database view.
- Shows warehouse names, products, batch codes, and quantities.

### 4. Order Management
- Displays retailer orders and order dates.
- Shows retailer names, cities, and order quantities.
- Displays order status, shipment status, and delivery dates.

## Technology Stack

- Frontend: Next.js, React, TypeScript
- Backend: Next.js API routes
- Database: PostgreSQL
- Database driver: `pg`
- Runtime: Node.js

## Prerequisites

Install the following before running the project:

- Node.js and npm
- PostgreSQL 18 or a compatible PostgreSQL installation
- The project's database and required database views

## Setup

### 1. Install dependencies

Clone or open the project directory, then run:

```bash
npm install
```

### 2. Configure environment variables

Create a `.env.local` file in the project root.

Add your PostgreSQL connection string:

```env
DATABASE_URL=postgresql://USER:PASSWORD@localhost:5432/supplychain
```

Replace `USER` and `PASSWORD` with your PostgreSQL credentials.

Do not commit `.env.local` or expose database passwords.

### 3. Start PostgreSQL

Make sure the PostgreSQL server is running and the `supplychain` database exists.

The application expects the following database views:

- `v_warehouse_stock`
- `v_expiring_batches`
- `v_low_stock`
- `v_order_details`

The health endpoint also checks the database connection.

### 4. Start the development server

Run:

```bash
npm run dev
```

Open the application at:

http://localhost:3000

## Application Pages

| Page | Route |
|---|---|
| Warehouse Inventory Dashboard | `/` |
| Batch Management | `/batches` |
| Low Stock Monitoring | `/low-stock` |
| Order Management | `/orders` |

## API Endpoints

| Endpoint | Purpose |
|---|---|
| `/api/health` | Checks the PostgreSQL connection |
| `/api/warehouses` | Retrieves warehouse stock information |
| `/api/batches` | Retrieves expiring batch information |
| `/api/low-stock` | Retrieves low-stock records |
| `/api/orders` | Retrieves retailer order information |

## Testing

Verify the following during testing:

1. The health endpoint reports a successful database connection.
2. The dashboard displays warehouse data.
3. Batch Management displays batch and expiry information.
4. Low Stock Monitoring displays stock records.
5. Order Management displays order and shipment details.
6. Navigation between the pages works correctly.

## Security Notes

- Keep `.env.local` private.
- Never commit database passwords or other secrets.
- Use environment variables for configuration.

## Project Status

The dashboard, Batch Management, Low Stock Monitoring, and Order Management pages have been tested locally against PostgreSQL.