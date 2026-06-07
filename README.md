# Laundry App

Laundry App is a full-stack laundry management system with a Flutter mobile frontend, a Node.js/Express backend, and a MySQL database. It helps customers create laundry orders, staff manage order progress, delivery users handle pickups/deliveries, and admins manage services, staff, reports, payments, and expenses.

## System Overview

The project is split into three main parts:

- `Frontend/` - Flutter app used by customers, staff, delivery users, and admins.
- `Backend/` - Express.js API that handles authentication, orders, payments, reports, staff, services, expenses, and lookups.
- `Database/` - MySQL schema, tables, stored procedures, and default data.

## User Roles

### Customer

Customers can register, log in, create laundry orders, view order history, view exact order dates, pay for orders, view payment history, see their profile, and check their current balance.

### Staff

Staff can log in, view dashboard counts, view all customer orders, filter orders by date/customer/payment status, see customer balances, and update order statuses such as `Accepted`, `Washing`, `Ironing`, and `Ready`.

### Delivery

Delivery users can view assigned pickup and delivery orders, mark orders as picked up, and mark orders as delivered.

### Admin

Admins can view dashboard summaries, manage services, manage staff, view reports, add expenses, and see net income. Admin is the correct role for expenses because expenses affect profit and reporting.

## Main Workflows

### Customer Order Flow

1. Customer logs in or registers.
2. Customer creates an order with laundry items, pickup address, pickup date, and notes.
3. The backend creates the order and calculates totals.
4. Staff updates the order status as work progresses.
5. Customer can view the order in history and pay the remaining balance.
6. Payment updates the order payment status to `Unpaid`, `Partial`, or `Paid`.

### Balance Flow

Balances are calculated from real payment data:

```text
balance = total_amount - paid_total
```

The backend returns `paid_total` and `balance` with order data. The frontend displays customer balance on the customer dashboard, order history, order details, and staff order views.

### Admin Expense Flow

1. Admin opens `Expenses` from the admin dashboard.
2. Admin enters expense title, amount, date, and description.
3. Backend saves the expense in the `expenses` table.
4. Reports and dashboard totals use expenses to calculate net income.

```text
net_income = total_payments - total_expenses
```

## Admin Dashboard

The admin dashboard shows:

Row 1:

- Total Staffs
- Total Customers
- Total Services

Row 2:

- Total Payments
- Total Expense
- Net Income

Row 3:

- Total Orders
- Pending Orders
- Paid Orders
- Unpaid Orders

## Backend API

The backend runs on:

```text
http://localhost:5000
```

The frontend uses:

```text
http://127.0.0.1:5000/api
```

for testing. For Android emulator, run `adb reverse tcp:5000 tcp:5000` first.

Important API groups:

- `/api/auth` - login and password reset
- `/api/customers` - customer registration
- `/api/orders` - create orders, get orders, update status
- `/api/payments` - make payment, payment history
- `/api/staff` - staff dashboard and staff orders
- `/api/delivery` - delivery orders and status updates
- `/api/admin` - dashboard, services, staff, reports, expenses
- `/api/lookups` - cities, districts, services, cloth types

## Setup

### 1. Database

Import the schema:

```text
Database/schema.txt
```

Create a MySQL database named:

```text
laundry_system
```

### 2. Backend

```bash
cd Backend
npm install
npm run dev
```

Create or update `.env`:

```env
PORT=5000
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=laundry_system
JWT_SECRET=laundry_secret_key
```

### 3. Frontend

```bash
cd Frontend
flutter pub get
flutter run
```

If running on an Android Emulator, make sure to forward the backend port via ADB:

```bash
adb reverse tcp:5000 tcp:5000
```

The backend URL in:

```text
Frontend/lib/core/constants/api_constants.dart
```

is set to:

```dart
static const String baseUrl = 'http://127.0.0.1:5000/api';
```

which works across Android Emulator (with `adb reverse`), iOS Simulator, Desktop, and Web.

## Notes

- JWT tokens protect customer, staff, delivery, and admin routes.
- Passwords are hashed with `bcryptjs`.
- Generated files such as `node_modules`, Flutter build output, `.dart_tool`, and environment files are ignored by Git.
- Restart the backend after backend controller or route changes.
