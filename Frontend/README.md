# Laundry App Frontend

Flutter mobile frontend for the Laundry App backend.

## Packages

- `http`
- `shared_preferences`
- `provider`
- `intl`

## Backend URL

The default API URL is set in:

```text
lib/core/constants/api_constants.dart
```

For Android emulator:

```dart
static const String baseUrl = 'http://10.0.2.2:5000/api';
```

For browser/desktop testing, use:

```dart
static const String baseUrl = 'http://localhost:5000/api';
```

## Run Steps

1. Start the backend:

```bash
cd ../Backend
npm run dev
```

2. Open the frontend folder:

```bash
cd ../Frontend
```

3. If platform folders are missing, generate them:

```bash
flutter create .
```

4. Install Flutter packages:

```bash
flutter pub get
```

5. Run the app:

```bash
flutter run
```

## Features

- Splash screen checks saved JWT token.
- Login saves JWT token and user data.
- Register customer form uses city and district dropdowns.
- Home screen shows customer menu cards.
- Create order screen calculates preview subtotals and total.
- Order history and order details screens call protected backend endpoints.

## Backend Lookup Endpoints

The app expects these lookup endpoints for dropdowns:

```text
GET /api/lookups/cities
GET /api/lookups/districts/:city_id
GET /api/lookups/services
GET /api/lookups/cloth-types
```

If those are not in your backend yet, add them before testing registration and order creation.
