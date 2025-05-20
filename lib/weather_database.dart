import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class WeatherDatabase {
  static final WeatherDatabase instance = WeatherDatabase._init();
  static Database? _database;

  WeatherDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('weather.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      throw Exception('Veritabanı başlatılamadı: $e');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    try {
      // Kullanıcı tablosu
      await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL UNIQUE,
          email TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL,
          created_at TEXT NOT NULL,
          last_login TEXT
        )
      ''');

      // Hava durumu tablosu
      await db.execute('''
        CREATE TABLE weather (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          city TEXT NOT NULL,
          temperature REAL NOT NULL,
          feelsLike REAL,
          humidity INTEGER,
          windSpeed REAL,
          pressure INTEGER,
          description TEXT NOT NULL,
          icon TEXT,
          dateTime TEXT NOT NULL,
          country TEXT,
          sunrise INTEGER,
          sunset INTEGER,
          clouds INTEGER,
          visibility INTEGER,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      // Kullanıcı tercihleri tablosu
      await db.execute('''
        CREATE TABLE user_preferences (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          default_city TEXT,
          temperature_unit TEXT DEFAULT 'celsius',
          language TEXT DEFAULT 'tr',
          notifications_enabled BOOLEAN DEFAULT 1,
          dark_mode BOOLEAN DEFAULT 0,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
    } catch (e) {
      throw Exception('Tablolar oluşturulamadı: $e');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Gelecekte yapılacak veritabanı güncellemeleri için
    }
  }

  // Kullanıcı işlemleri
  Future<int> createUser(Map<String, dynamic> user) async {
    try {
      final db = await instance.database;
      return await db.insert('users', user);
    } catch (e) {
      throw Exception('Kullanıcı oluşturulamadı: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );
      if (maps.isNotEmpty) {
        return maps.first;
      }
      return null;
    } catch (e) {
      throw Exception('Kullanıcı bulunamadı: $e');
    }
  }

  Future<void> updateLastLogin(int userId) async {
    try {
      final db = await instance.database;
      await db.update(
        'users',
        {'last_login': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      throw Exception('Son giriş tarihi güncellenemedi: $e');
    }
  }

  // Hava durumu işlemleri
  Future<int> insertWeather(Map<String, dynamic> weather) async {
    try {
      final db = await instance.database;
      return await db.insert('weather', weather);
    } catch (e) {
      throw Exception('Hava durumu verisi kaydedilemedi: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getWeatherByUserId(int userId) async {
    try {
      final db = await instance.database;
      return await db.query(
        'weather',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'dateTime DESC',
      );
    } catch (e) {
      throw Exception('Kullanıcının hava durumu verileri alınamadı: $e');
    }
  }

  // Kullanıcı tercihleri işlemleri
  Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final db = await instance.database;
      await db.insert('user_preferences', preferences);
    } catch (e) {
      throw Exception('Kullanıcı tercihleri kaydedilemedi: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserPreferences(int userId) async {
    try {
      final db = await instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'user_preferences',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      if (maps.isNotEmpty) {
        return maps.first;
      }
      return null;
    } catch (e) {
      throw Exception('Kullanıcı tercihleri alınamadı: $e');
    }
  }

  Future<void> updateUserPassword(int userId, String hashedPassword) async {
    try {
      final db = await instance.database;
      await db.update(
        'users',
        {'password': hashedPassword},
        where: 'id = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      throw Exception('Şifre güncellenemedi: $e');
    }
  }

  Future<void> close() async {
    try {
      final db = await instance.database;
      db.close();
    } catch (e) {
      throw Exception('Veritabanı kapatılamadı: $e');
    }
  }
}
