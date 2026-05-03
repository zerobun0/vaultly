# Vaultly

Vaultly is an offline-first personal finance app built with Flutter. It brings together transaction importing, budgeting, savings goals, income tax estimates, and Trading 212 portfolio insights in one local-first dashboard.

## What it does

- Dashboard with income, spending, category breakdowns, monthly charts, and recent transactions.
- Transaction browsing with search, date grouping, category filters, and import flow.
- Budget tracking with per-category spend and progress indicators.
- Savings goals with progress updates, target dates, and completion tracking.
- UK income tax calculator with manual salary and dividend inputs.
- Trading 212 integration for portfolio, order history, dividends, and cash balance.
- Settings for theme selection, biometric lock, and API key management.
- Local storage for app data and secrets, with no telemetry.

## Tech Stack

- Flutter / Dart 3
- Riverpod for state management
- GoRouter for navigation
- Drift + SQLite for local persistence
- flutter_secure_storage for secrets
- fl_chart and flutter_animate for charts and motion
- local_auth and flutter_local_notifications for device features

## Getting Started

### Prerequisites

- Flutter SDK 3.3 or newer
- Android Studio, VS Code, or another Flutter-compatible editor
- A connected device or emulator

### Install dependencies

```bash
flutter pub get
```

### Generate code

If you change providers, Drift models, or router annotations, regenerate the generated files:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Run the app

```bash
flutter run
```

### Run tests

```bash
flutter test
```

## Configuration

- Open Settings to switch between dark, light, and system theme modes.
- Enable biometric lock if the device supports it.
- Add your Trading 212 API key in Settings to unlock the Investments view.

## Project Structure

- `lib/main.dart` app entry point
- `lib/app.dart` root app widget and biometric gate
- `lib/presentation/` UI, routing, screens, and providers
- `lib/data/` repositories, parsers, services, and database access
- `lib/domain/` business logic and calculators
- `test/` unit and widget tests

## Notes

- Vaultly is designed to keep user data on-device.
- Some features, such as biometric auth and Trading 212 data, depend on device support and valid API credentials.
- The app uses generated files that are already checked in for convenience, but you should still run code generation after changing the relevant source files.
