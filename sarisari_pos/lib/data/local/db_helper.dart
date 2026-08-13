import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Central SQLite database helper.
/// Handles creation, migrations, and provides a single shared [Database] instance.
class DBHelper {
  DBHelper._internal();
  static final DBHelper instance = DBHelper._internal();

  static const _dbName = 'sarisari_pos.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        // Enforce foreign key constraints (off by default in sqflite)
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        barcode TEXT UNIQUE,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
        cost_price REAL DEFAULT 0,
        sell_price REAL NOT NULL,
        stock_qty REAL NOT NULL DEFAULT 0,
        reorder_level REAL DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE stock_movements (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        type TEXT NOT NULL,
        qty REAL NOT NULL,
        reference_id TEXT,
        notes TEXT,
        created_at TEXT,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    batch.execute('''
      CREATE TABLE buyers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        contact_number TEXT,
        total_outstanding_balance REAL DEFAULT 0,
        created_at TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        subtotal REAL NOT NULL,
        total REAL NOT NULL,
        amount_tendered REAL DEFAULT 0,
        change_amount REAL DEFAULT 0,
        payment_type TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'completed',
        buyer_id TEXT,
        void_reason TEXT,
        synced_flag INTEGER DEFAULT 0,
        created_at TEXT,
        FOREIGN KEY (buyer_id) REFERENCES buyers(id)
      )
    ''');

    batch.execute('''
      CREATE TABLE transaction_items (
        id TEXT PRIMARY KEY,
        transaction_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        qty REAL NOT NULL,
        unit_price REAL NOT NULL,
        line_total REAL NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id),
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    batch.execute('''
      CREATE TABLE credit_payments (
        id TEXT PRIMARY KEY,
        transaction_id TEXT NOT NULL,
        buyer_id TEXT NOT NULL,
        amount_paid REAL NOT NULL,
        notes TEXT,
        created_at TEXT,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id),
        FOREIGN KEY (buyer_id) REFERENCES buyers(id)
      )
    ''');

    batch.execute('''
      CREATE TABLE license (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        store_id TEXT NOT NULL,
        license_type TEXT NOT NULL,
        expires_at TEXT,
        issued_at TEXT NOT NULL,
        signature TEXT NOT NULL,
        last_check_in TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Helpful indexes for common lookups
    batch.execute('CREATE INDEX idx_products_barcode ON products(barcode)');
    batch.execute('CREATE INDEX idx_txn_items_txn ON transaction_items(transaction_id)');
    batch.execute('CREATE INDEX idx_stock_movements_product ON stock_movements(product_id)');
    batch.execute('CREATE INDEX idx_transactions_status ON transactions(status)');

    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Add migration steps here as schema evolves, e.g.:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE products ADD COLUMN category TEXT');
    // }
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
