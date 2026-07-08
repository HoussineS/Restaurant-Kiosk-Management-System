Restaurant Kiosk Management System - Work Progress

Current Sprint: Sprint 1 - Foundation and Product Management

Status: In progress, core Sprint 1 foundation implemented.

What changed

- Replaced the default Flutter counter app with the real Restaurant Kiosk app entry point.
- Added Riverpod at the root of the app with `ProviderScope`.
- Used Flutter Material navigation with `MaterialPageRoute` and `Navigator`, as requested.
- Added a clean folder structure under `lib/src`:
  - `app` for the app shell, routes, and theme.
  - `core` for shared database and service code.
  - `features/menu/domain` for entities and repository contracts.
  - `features/menu/data` for SQLite models, data source, and repository implementations.
  - `features/menu/presentation` for providers, screens, and widgets.
- Added a Material 3 light/dark theme.
- Added SQLite desktop support with `sqflite_common_ffi`.
- Created local database tables:
  - `categories`
  - `products`
- Added domain entities:
  - `MenuCategory`
  - `Product`
- Added repository contracts:
  - `CategoryRepository`
  - `ProductRepository`
- Added SQLite repository implementations for categories and products.
- Added Riverpod controllers for category and product CRUD operations.
- Added category management screen:
  - List categories.
  - Add category.
  - Edit category.
  - Delete category.
  - Prevent deleting a category that still has products.
- Added product management screen:
  - List products.
  - Add product.
  - Edit product.
  - Delete product.
  - Set category, description, price, availability, and image.
- Added local product image storage:
  - Pick an image from the device.
  - Copy it into the app support directory.
  - Store the local image path in SQLite.
- Replaced the starter counter test with simple menu domain model tests.

Important decision

- `go_router` was removed because the project should use Flutter's built-in Material navigation.
- Named route definitions were removed. Screen navigation now uses direct `MaterialPageRoute` builders.

Verification

- `flutter analyze` passed with no issues.
- `flutter test` passed with all tests green.
- `flutter build windows` is blocked by the local machine setup, not by Dart code:
  - Flutter cannot find a suitable Visual Studio toolchain.
  - `flutter doctor -v` says Visual Studio Build Tools 2019 is installed but incomplete.

Git setup

- Initialized a local Git repository.
- Updated `README.md` with the project name and current Sprint 1 status.
- Created the first commit with the Flutter project and Sprint 1 foundation files.
- Prepared the repository for the GitHub remote:
  - `https://github.com/HoussineS/Restaurant-Kiosk-Management-System.git`

Next Sprint 1 improvements

- Add better form validation messages for duplicate category names.
- Add product filtering by category.
- Add optional sample data for first launch.
- Add repository-focused tests with an in-memory SQLite database.

Sprint 2-4 implementation pass

- Added a Dashboard section with KPIs for today's sales, order count, average ticket, menu size, status totals, best-selling products, and last-7-days revenue.
- Added a Kitchen Queue section with Pending, Preparing, and Ready columns plus quick actions to start, mark ready, complete, or cancel orders.
- Expanded Order Management with search by order number/product, status filtering, date filtering, summary printing, receipt reprinting, status updates, and deletion.
- Added a Settings section with database backup, data refresh, all-time sales summary printing, and fullscreen kiosk toggle.
- Added a database maintenance service that checkpoints SQLite and copies database backup files to a selected folder.
- Added an unfiltered all-orders provider for dashboard/kitchen/reporting so analytics are not affected by history filters.
- Fixed order number generation so new numbers are based on all saved orders, not only the currently filtered order list.
- Hardened SQLite numeric reads for order totals and unit prices.
- Updated main navigation to include Dashboard, Kitchen, Orders, Categories, Products, and Settings.
- Kept existing POS/cart/product/category flows and extended them instead of replacing the app structure.

Verification after this pass

- `dart analyze lib test` reported: No issues found.
- `dart format` completed formatting the touched Dart files.
- `flutter test` and `flutter test test/menu_model_test.dart --reporter expanded` both timed out after 120 seconds on this machine.
- Dart/Flutter commands still report a global telemetry write warning for `C:\Users\Lenovo\AppData\Roaming\.dart-tool\dart-flutter-telemetry-session.json`; this is outside the project and not a source-code analyzer issue.
