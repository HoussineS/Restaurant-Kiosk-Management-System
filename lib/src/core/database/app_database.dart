import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  static const _databaseName = 'restaurant_kiosk.db';
  static const _databaseVersion = 2;

  Database? _database;

  Future<Database> get database async {
    final openedDatabase = _database;
    if (openedDatabase != null) {
      return openedDatabase;
    }

    final database = await _openDatabase();
    _database = database;
    return database;
  }

  Future<Database> _openDatabase() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final databasePath = p.join(supportDirectory.path, _databaseName);

    return databaseFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (database, version) async {
          await database.execute('''
            CREATE TABLE categories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL UNIQUE,
              created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
          ''');

          await database.execute('''
            CREATE TABLE products (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              category_id INTEGER NOT NULL,
              name TEXT NOT NULL,
              description TEXT NOT NULL DEFAULT '',
              image_path TEXT,
              price REAL NOT NULL,
              available INTEGER NOT NULL DEFAULT 1,
              created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
              updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
              FOREIGN KEY (category_id)
                REFERENCES categories (id)
                ON DELETE RESTRICT
            )
          ''');

          await database.execute(
            'CREATE INDEX idx_products_category_id ON products(category_id)',
          );

          await _createOrderTables(database);
        },
        onUpgrade: (database, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await _createOrderTables(database);
          }
        },
      ),
    );
  }

  Future<void> _createOrderTables(Database database) async {
    await database.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_number TEXT NOT NULL UNIQUE,
        total_price REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await database.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        FOREIGN KEY (order_id)
          REFERENCES orders (id)
          ON DELETE CASCADE
      )
    ''');

    await database.execute(
      'CREATE INDEX idx_order_items_order_id ON order_items(order_id)',
    );
  }
}

