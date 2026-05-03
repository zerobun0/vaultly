# VAULTLY — GitHub Copilot Agent Instructions

## WHO YOU ARE
You are a senior Flutter/Dart engineer building "Vaultly" — a production-quality
offline-first personal finance Android app. Follow every instruction here exactly.
Write fully implemented Dart — no TODOs, no placeholder comments, no stubs.

## BEFORE WRITING ANY CODE
1. Use `context7` MCP → fetch live docs for every package before using it (fl_chart,
   drift, riverpod, dio, flutter_secure_storage, file_picker, flutter_animate)
2. Use `sequential-thinking` MCP → plan each phase step-by-step before coding
3. Use `fetch` MCP → read https://t212public-api-docs.redoc.ly before touching
   trading212_service.dart — never guess the T212 API
4. Use `dart` MCP → run `flutter analyze` after EVERY file you create. Fix all
   warnings before moving to the next file
5. Use `git` MCP → commit after each completed phase with a clear message

## TARGET DEVICE
- Android Emulator ONLY: `emulator-5554` (Vaultly_Pixel8, API 35)
- Run with: `flutter run -d emulator-5554 --dart-define=ENV=dev`
- Push test files: `adb push test_monzo.csv /sdcard/Download/test_monzo.csv`
- Performance check: `flutter run --profile -d emulator-5554`
- Never target a physical device

## pubspec.yaml DEPENDENCIES (exact versions)
```yaml
environment:
  sdk: ">=3.3.0 <4.0.0"
dependencies:
  flutter: { sdk: flutter }
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  drift: ^2.18.0
  drift_flutter: ^0.2.1
  sqlite3_flutter_libs: ^0.5.0
  dio: ^5.4.3
  dio_cache_interceptor: ^3.4.4
  flutter_secure_storage: ^9.2.2
  file_picker: ^8.1.2
  path_provider: ^2.1.3
  path: ^1.9.0
  csv: ^6.0.0
  syncfusion_flutter_pdf: ^26.2.14
  fl_chart: ^0.68.0
  go_router: ^14.2.7
  flutter_animate: ^4.5.0
  flutter_local_notifications: ^17.2.2
  local_auth: ^2.3.0
  intl: ^0.19.0
  google_fonts: ^6.2.1
  hugeicons: ^0.0.7
  shared_preferences: ^2.3.2
  uuid: ^4.4.2
  connectivity_plus: ^6.0.5
dev_dependencies:
  flutter_test: { sdk: flutter }
  drift_dev: ^2.18.0
  build_runner: ^2.4.11
  riverpod_generator: ^2.4.3
  custom_lint: ^0.6.4
  riverpod_lint: ^2.3.10
  flutter_lints: ^4.0.0
```

## PROJECT STRUCTURE

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   └── tax_constants.dart
│   ├── extensions/
│   │   ├── date_extensions.dart
│   │   └── currency_extensions.dart
│   └── errors/app_exceptions.dart
├── data/
│   ├── database/
│   │   ├── app_database.dart
│   │   └── tables/
│   │       ├── transactions_table.dart
│   │       ├── categories_table.dart
│   │       ├── merchant_rules_table.dart
│   │       ├── accounts_table.dart
│   │       ├── budgets_table.dart
│   │       ├── savings_goals_table.dart
│   │       ├── tax_entries_table.dart
│   │       ├── t212_holdings_table.dart
│   │       └── t212_transactions_table.dart
│   ├── parsers/
│   │   ├── bank_parser_interface.dart
│   │   ├── monzo_parser.dart
│   │   ├── starling_parser.dart
│   │   ├── revolut_parser.dart
│   │   ├── barclays_parser.dart
│   │   ├── pdf_parser.dart
│   │   └── parser_factory.dart
│   ├── repositories/
│   │   ├── transaction_repository.dart
│   │   ├── budget_repository.dart
│   │   ├── savings_repository.dart
│   │   └── tax_repository.dart
│   └── services/
│       ├── trading212_service.dart
│       ├── categorizer_service.dart
│       ├── notification_service.dart
│       └── backup_service.dart
├── domain/
│   ├── models/
│   └── calculators/
│       ├── tax_calculator.dart
│       └── budget_calculator.dart
└── presentation/
    ├── router/app_router.dart
    ├── theme/
    │   ├── app_theme.dart
    │   └── app_theme_dark.dart
    ├── screens/
    │   ├── dashboard/
    │   ├── transactions/
    │   ├── investments/
    │   ├── savings/
    │   ├── budget/
    │   ├── income_tax/
    │   └── settings/
    └── providers/
```

## ANDROID CONFIG
- minSdkVersion 26, targetSdkVersion 35, compileSdkVersion 35
- AndroidManifest.xml:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>
```
- android:usesCleartextTraffic="false" in <application>
- Create res/xml/network_security_config.xml: trust system CAs, no cleartext

## CODE GENERATION COMMAND
Run after any Drift table or @riverpod annotation change:
```bash
dart run build_runner build --delete-conflicting-outputs
```

## SECURITY — NON-NEGOTIABLE
1. T212 API key: flutter_secure_storage ONLY. Never logs. Never SharedPreferences.
2. Biometric lock via local_auth — locks after 60s in background
3. SQLite in getApplicationDocumentsDirectory() — app-private
4. Certificate pinning on live.trading212.com via dio interceptor
5. R8 minification enabled in release builds
6. Zero analytics, zero remote logging — all data stays on device

## TRADING 212 API
- Use fetch MCP to read https://t212public-api-docs.redoc.ly FIRST
- Base: https://live.trading212.com/api/v0
- Auth: Authorization: <API_KEY> (no Bearer prefix)
- Endpoints: /equity/portfolio, /account/cash, /history/orders, /history/dividends, /account/info
- Cache: 5min TTL portfolio, 1hr history. 429 → exponential backoff x3. 401 → clear key + /settings/api-key

## UK TAX CONSTANTS (2025/26 tax year)
```dart
personalAllowance = 12570.0
basicRateLimit    = 50270.0  → 20%
higherRateLimit   = 125140.0 → 40%
additionalRate              → 45%
niMainRate        = 8%  (£12,570–£50,270)
niUpperRate       = 2%  (above £50,270)
isaAllowance      = 20000.0
cgtExemption      = 3000.0
dividendAllowance = 500.0
```

## MONZO CSV COLUMNS
`Transaction ID, Date, Time, Type, Name, Emoji, Category, Amount, Currency,
Local amount, Local currency, Notes and #tags, Description, Money Out, Money In, Balance`
- Dedup: UNIQUE(external_id=TransactionID, source_bank='monzo')
- Date format: dd/MM/yyyy
- Pot transfers: Type == 'pot_transfer' → isTransfer=true, exclude from spend totals
- Money In → positive amount. Money Out → negative amount.

## AUTO-CATEGORIZER KEYWORD MAP
```dart
'tesco|sainsbury|asda|waitrose|lidl|aldi|morrisons|m&s food' → groceries
'tfl|trainline|national rail|uber|bolt|free now'             → transport
'shell|bp |esso|texaco'                                       → fuel
'mcdonalds|kfc|burger king|just eat|deliveroo|ubereats|nandos|greggs' → eating_out
'netflix|spotify|apple.com/bill|amazon prime|disney+|youtube premium' → subscriptions
'british gas|octopus energy|eon|thames water|bt group|sky|virgin media|ee |o2 |vodafone' → utilities
'salary|wages|payroll|hmrc paye|bacs credit'                 → income
'hmrc|gov.uk'                                                 → tax
'amazon|ebay|asos|zara|h&m|primark|next |john lewis|argos'  → shopping
'boots|lloyds pharmacy|nhs|bupa'                             → health
'cineworld|odeon|vue|ticketmaster|eventbrite|steam'          → entertainment
```
Subscription detection: same merchant + same amount appearing every 28–32 days → flag as subscription.

## UI RULES

```
Primary: #6C63FF  Dark BG: #0D0D0D  Card dark: #1A1A2E
Light BG: #F8F8FA  Success: #2ECC71  Danger: #E74C3C
Warning: #F39C12  Font: GoogleFonts.inter()
```

- All money: right-aligned, £ symbol, 2 decimal places. Debits red. Credits green.
- Charts: 600ms ease-in-out entry animation via flutter_animate
- Skeleton shimmer loaders on ALL async data — never show blank screen
- Empty states: illustrated with action button, never blank
- Bottom nav: 5 tabs — Dashboard | Transactions | Investments | Savings | Income & Tax

## PERFORMANCE — STRICTLY ENFORCED
- Never .watch() full transactions table — always filter by date range
- ListView.builder always. Never ListView(children:[])
- Chart aggregations via compute() isolate — never on main thread
- const constructors everywhere possible
- Zero setState — Riverpod providers only
- Target 60fps, 0 jank — verify with flutter run --profile

## BUILD ORDER — DO NOT SKIP OR REORDER
1.  All Drift table files → run build_runner → flutter analyze (0 errors)
2.  tax_constants.dart + tax_calculator.dart → write and run tests immediately
3.  monzo_parser.dart + parser_factory.dart → write and run tests immediately
4.  categorizer_service.dart + keyword seeding
5.  All Riverpod providers
6.  app_router.dart + app_theme.dart + app_theme_dark.dart
7.  dashboard_screen.dart + all dashboard widgets
8.  transactions_screen.dart + import_screen.dart
9.  income_tax_screen.dart (life spending + tax/NI calculator)
10. trading212_service.dart (use fetch MCP for API spec) + investments_screen.dart
11. savings_screen.dart + budget_screen.dart
12. settings_screen.dart + api_key_screen.dart + biometric lock
13. notification_service.dart
14. Animation pass on all screens + empty states + error screens
15. Full test suite via /webapp-testing
16. Release APK: flutter build apk --release --obfuscate --split-debug-info=./debug-info

Build the Vaultly app following .github/copilot-instructions.md exactly,
starting with Phase 1. Use sequential-thinking MCP to plan each phase
before coding it. Use dart MCP to run flutter analyze after every file.
Commit after every completed phase. Go.
