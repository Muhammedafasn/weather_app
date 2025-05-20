import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'weather_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Kullanıcılar tablosu
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        created_at TEXT NOT NULL,
        last_login TEXT
      )
    ''');

    // Hava durumu tablosu
    await db.execute('''
      CREATE TABLE weather_data(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        city TEXT NOT NULL,
        temperature REAL NOT NULL,
        feels_like REAL,
        humidity INTEGER,
        wind_speed REAL,
        pressure INTEGER,
        description TEXT NOT NULL,
        icon TEXT,
        date_time TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Kullanıcı tercihleri tablosu
    await db.execute('''
      CREATE TABLE user_preferences(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        default_city TEXT DEFAULT 'Istanbul',
        temperature_unit TEXT DEFAULT 'celsius',
        language TEXT DEFAULT 'tr',
        notifications_enabled INTEGER DEFAULT 1,
        dark_mode INTEGER DEFAULT 0,
        weather_update_interval INTEGER DEFAULT 30,
        show_humidity INTEGER DEFAULT 1,
        show_wind INTEGER DEFAULT 1,
        show_pressure INTEGER DEFAULT 1,
        show_feels_like INTEGER DEFAULT 1,
        show_weather_icon INTEGER DEFAULT 1,
        auto_location INTEGER DEFAULT 0,
        location_permission INTEGER DEFAULT 0,
        last_updated TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Favori şehirler tablosu
    await db.execute('''
      CREATE TABLE favorite_cities(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        city_name TEXT NOT NULL,
        country_code TEXT,
        added_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE(user_id, city_name)
      )
    ''');

    // Hava durumu geçmişi tablosu
    await db.execute('''
      CREATE TABLE weather_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        city TEXT NOT NULL,
        temperature REAL NOT NULL,
        humidity INTEGER,
        wind_speed REAL,
        pressure INTEGER,
        description TEXT NOT NULL,
        icon TEXT,
        date_time TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  // Kullanıcı işlemleri
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // Hava durumu işlemleri
  Future<int> insertWeatherData(Map<String, dynamic> weather) async {
    final db = await database;
    return await db.insert('weather_data', weather);
  }

  Future<List<Map<String, dynamic>>> getWeatherDataByUserId(int userId) async {
    final db = await database;
    return await db.query(
      'weather_data',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date_time DESC',
    );
  }

  // Favori şehirler işlemleri
  Future<int> addFavoriteCity(Map<String, dynamic> city) async {
    final db = await database;
    return await db.insert('favorite_cities', city);
  }

  Future<List<Map<String, dynamic>>> getFavoriteCities(int userId) async {
    final db = await database;
    return await db.query(
      'favorite_cities',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'added_at DESC',
    );
  }

  Future<int> removeFavoriteCity(int userId, String cityName) async {
    final db = await database;
    return await db.delete(
      'favorite_cities',
      where: 'user_id = ? AND city_name = ?',
      whereArgs: [userId, cityName],
    );
  }

  // Hava durumu geçmişi işlemleri
  Future<int> addWeatherHistory(Map<String, dynamic> weather) async {
    final db = await database;
    return await db.insert('weather_history', weather);
  }

  Future<List<Map<String, dynamic>>> getWeatherHistory(int userId) async {
    final db = await database;
    return await db.query(
      'weather_history',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date_time DESC',
    );
  }

  // Kullanıcı tercihleri işlemleri
  Future<int> saveUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final db = await database;
      return await db.insert('user_preferences', preferences);
    } catch (e) {
      throw Exception('Kullanıcı tercihleri kaydedilemedi: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserPreferences(int userId) async {
    try {
      final db = await database;
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

  Future<int> updateUserPreferences(
      int userId, Map<String, dynamic> preferences) async {
    try {
      final db = await database;
      return await db.update(
        'user_preferences',
        preferences,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      throw Exception('Kullanıcı tercihleri güncellenemedi: $e');
    }
  }

  Future<void> resetUserPreferences(int userId) async {
    try {
      final db = await database;
      await db.update(
        'user_preferences',
        {
          'default_city': 'Istanbul',
          'temperature_unit': 'celsius',
          'language': 'tr',
          'notifications_enabled': 1,
          'dark_mode': 0,
          'weather_update_interval': 30,
          'show_humidity': 1,
          'show_wind': 1,
          'show_pressure': 1,
          'show_feels_like': 1,
          'show_weather_icon': 1,
          'auto_location': 0,
          'location_permission': 0,
          'last_updated': DateTime.now().toIso8601String(),
        },
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      throw Exception('Kullanıcı tercihleri sıfırlanamadı: $e');
    }
  }
}
