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
