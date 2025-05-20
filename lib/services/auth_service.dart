import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../database_helper.dart';

class AuthService {
  final DatabaseHelper _db = DatabaseHelper();

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<Map<String, dynamic>?> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // E-posta kontrolü
      final existingUser = await _db.getUserByEmail(email);
      if (existingUser != null) {
        throw Exception('Bu e-posta adresi zaten kullanılıyor.');
      }

      // Yeni kullanıcı oluştur
      final user = {
        'username': username,
        'email': email,
        'password': _hashPassword(password),
        'created_at': DateTime.now().toIso8601String(),
      };

      final userId = await _db.insertUser(user);

      // Varsayılan kullanıcı tercihlerini oluştur
      await _db.saveUserPreferences({
        'user_id': userId,
        'default_city': 'Istanbul',
        'temperature_unit': 'celsius',
        'language': 'tr',
        'notifications_enabled': 1,
        'dark_mode': 0,
      });

      return {
        'id': userId,
        'username': username,
        'email': email,
      };
    } catch (e) {
      throw Exception('Kayıt işlemi başarısız: $e');
    }
  }

  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _db.getUserByEmail(email);
      if (user == null) {
        throw Exception('Kullanıcı bulunamadı.');
      }

      final hashedPassword = _hashPassword(password);
      if (user['password'] != hashedPassword) {
        throw Exception('Hatalı şifre.');
      }

      // Son giriş tarihini güncelle
      await _db.updateUserPreferences(user['id'], {
        'last_login': DateTime.now().toIso8601String(),
      });

      return {
        'id': user['id'],
        'username': user['username'],
        'email': user['email'],
      };
    } catch (e) {
      throw Exception('Giriş işlemi başarısız: $e');
    }
  }

  Future<void> logout() async {
    // Oturum kapatma işlemleri burada yapılabilir
    // Örneğin: yerel depolamadaki oturum bilgilerini temizleme
  }

  Future<void> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    try {
      final user = await _db.getUserByEmail(email);
      if (user == null) {
        throw Exception('Kullanıcı bulunamadı.');
      }

      final hashedCurrentPassword = _hashPassword(currentPassword);
      if (user['password'] != hashedCurrentPassword) {
        throw Exception('Mevcut şifre hatalı.');
      }

      // Şifreyi güncelle
      await _db.updateUserPreferences(userId, {
        'password': _hashPassword(newPassword),
      });
    } catch (e) {
      throw Exception('Şifre değiştirme işlemi başarısız: $e');
    }
  }
}
