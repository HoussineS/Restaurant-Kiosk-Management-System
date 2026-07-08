import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  static const _databaseName = 'restaurant_kiosk.db';
  static const int _databaseVersion = 3;

  // Singleton pattern
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await databasePath;

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<String> get databasePath async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, _databaseName);
  }

  Future<void> checkpoint() async {
    final db = await database;
    await db.rawQuery('PRAGMA wal_checkpoint(FULL)');
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon_name TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        price REAL NOT NULL,
        available INTEGER NOT NULL DEFAULT 1,
        image_path TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE product_modifiers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        extra_price REAL NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_number TEXT NOT NULL,
        total_price REAL NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE order_item_modifiers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_item_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        extra_price REAL NOT NULL,
        FOREIGN KEY (order_item_id) REFERENCES order_items (id) ON DELETE CASCADE
      )
    ''');

    await _seedTunisianData(db);
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE orders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          order_number TEXT NOT NULL,
          total_price REAL NOT NULL,
          status TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE order_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          order_id INTEGER NOT NULL,
          product_id INTEGER NOT NULL,
          product_name TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          unit_price REAL NOT NULL,
          FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE product_modifiers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          extra_price REAL NOT NULL,
          FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE order_item_modifiers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          order_item_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          extra_price REAL NOT NULL,
          FOREIGN KEY (order_item_id) REFERENCES order_items (id) ON DELETE CASCADE
        )
      ''');

      // Clear existing menu and re-seed
      await db.execute('DELETE FROM products');
      await db.execute('DELETE FROM categories');
      await _seedTunisianData(db);
    }
  }

  Future<void> _seedTunisianData(Database db) async {
    // Categories
    final catStarters = await db.insert('categories', {
      'name': 'Starters',
      'icon_name': 'local_dining',
      'color_value': 0xFFE57373,
      'sort_order': 0,
    });
    final catMain = await db.insert('categories', {
      'name': 'Main Dishes',
      'icon_name': 'restaurant',
      'color_value': 0xFF81C784,
      'sort_order': 1,
    });
    final catStreet = await db.insert('categories', {
      'name': 'Street Food',
      'icon_name': 'fastfood',
      'color_value': 0xFFFFB74D,
      'sort_order': 2,
    });
    final catDesserts = await db.insert('categories', {
      'name': 'Desserts',
      'icon_name': 'cake',
      'color_value': 0xFFBA68C8,
      'sort_order': 3,
    });
    final catDrinks = await db.insert('categories', {
      'name': 'Drinks',
      'icon_name': 'local_cafe',
      'color_value': 0xFF64B5F6,
      'sort_order': 4,
    });

    // Starters
    await db.insert('products', {
      'category_id': catStarters,
      'name': 'Brik à l\'Oeuf',
      'description':
          'Crispy thin pastry filled with egg, tuna, parsley, and capers.',
      'price': 4.50,
      'image_path':
          'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=800&q=80',
    });
    await db.insert('products', {
      'category_id': catStarters,
      'name': 'Slata Mechouia',
      'description':
          'Grilled pepper and tomato salad with garlic, caraway, olive oil, and tuna.',
      'price': 6.00,
      'image_path':
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80',
    });
    await db.insert('products', {
      'category_id': catStarters,
      'name': 'Chorba Frik',
      'description': 'Traditional cracked wheat soup with lamb and tomatoes.',
      'price': 5.50,
      'image_path':
          'https://images.unsplash.com/photo-1547592180-85f173990554?w=800&q=80',
    });

    // Main Dishes
    final couscousId = await db.insert('products', {
      'category_id': catMain,
      'name': 'Couscous à l\'Agneau',
      'description':
          'Authentic Tunisian couscous with lamb, potatoes, carrots, and spicy harissa broth.',
      'price': 14.00,
      'image_path':
          'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=800&q=80',
    });
    await db.insert('product_modifiers', {
      'product_id': couscousId,
      'name': 'Morceau Viande Supplémentaire',
      'extra_price': 4.00,
    });

    await db.insert('products', {
      'category_id': catMain,
      'name': 'Ojja Merguez',
      'description':
          'Spicy tomato and pepper stew with eggs and grilled merguez sausage.',
      'price': 11.00,
      'image_path':
          'https://images.unsplash.com/photo-1564834724105-918b73d1b9e0?w=800&q=80',
    });

    final kaftejiId = await db.insert('products', {
      'category_id': catMain,
      'name': 'Kafteji',
      'description':
          'Fried vegetables (peppers, tomatoes, pumpkin, potatoes) chopped together with eggs.',
      'price': 9.50,
      'image_path':
          'https://images.unsplash.com/photo-1548943487-a2e4b43b4852?w=800&q=80',
    });
    await db.insert('product_modifiers', {
      'product_id': kaftejiId,
      'name': 'Oeuf Supplémentaire',
      'extra_price': 1.00,
    });
    await db.insert('product_modifiers', {
      'product_id': kaftejiId,
      'name': 'Merguez Supplémentaire',
      'extra_price': 2.00,
    });

    // Street Food
    final mlawiId = await db.insert('products', {
      'category_id': catStreet,
      'name': 'Mlawi',
      'description':
          'Flaky folded flatbread wrap with spicy escalope, harissa, and fries.',
      'price': 4.50,
      'image_path':
          'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800&q=80',
    });
    await db.insert('product_modifiers', {
      'product_id': mlawiId,
      'name': 'Double Fromage',
      'extra_price': 1.00,
    });
    await db.insert('product_modifiers', {
      'product_id': mlawiId,
      'name': 'Escalope Supplémentaire',
      'extra_price': 2.50,
    });
    await db.insert('product_modifiers', {
      'product_id': mlawiId,
      'name': 'Sans Harissa',
      'extra_price': 0.00,
    });

    final chapatiId = await db.insert('products', {
      'category_id': catStreet,
      'name': 'Chapati Tunisien',
      'description':
          'Traditional flatbread sandwich with omelet, tuna, and cheese.',
      'price': 5.00,
      'image_path':
          'https://images.unsplash.com/photo-1619860860505-642d2a7f5a81?w=800&q=80',
    });
    await db.insert('product_modifiers', {
      'product_id': chapatiId,
      'name': 'Double Fromage',
      'extra_price': 1.00,
    });
    await db.insert('product_modifiers', {
      'product_id': chapatiId,
      'name': 'Sans Harissa',
      'extra_price': 0.00,
    });

    await db.insert('products', {
      'category_id': catStreet,
      'name': 'Fricassé',
      'description':
          'Fried savory donut filled with tuna, harissa, boiled egg, olives, and potatoes.',
      'price': 3.50,
      'image_path':
          'https://images.unsplash.com/photo-1626079975762-b9b2ffbf41af?w=800&q=80',
    });

    // Desserts
    await db.insert('products', {
      'category_id': catDesserts,
      'name': 'Bambalouni',
      'description': 'Tunisian sweet fried dough ring rolled in sugar.',
      'price': 2.00,
      'image_path':
          'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=800&q=80',
    });
    await db.insert('products', {
      'category_id': catDesserts,
      'name': 'Assida Zgougou',
      'description':
          'Traditional Aleppo pine nut pudding topped with vanilla cream and nuts.',
      'price': 7.00,
      'image_path':
          'https://images.unsplash.com/photo-1517260739337-6799d239ce83?w=800&q=80',
    });

    // Drinks
    await db.insert('products', {
      'category_id': catDrinks,
      'name': 'Citronnade aux Amandes',
      'description': 'Freshly blended Tunisian lemon and almond drink.',
      'price': 4.00,
      'image_path':
          'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=800&q=80',
    });
    await db.insert('products', {
      'category_id': catDrinks,
      'name': 'Thé aux Pignons',
      'description': 'Mint tea served with pine nuts.',
      'price': 3.50,
      'image_path':
          'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=800&q=80',
    });
    await db.insert('products', {
      'category_id': catDrinks,
      'name': 'Boga Cidre',
      'description': 'Traditional Tunisian dark soda.',
      'price': 2.50,
      'image_path':
          'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=800&q=80',
    });
  }
}
