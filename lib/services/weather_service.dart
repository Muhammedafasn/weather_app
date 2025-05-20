import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database_helper.dart';
import '../config.dart';

class WeatherService {
  final DatabaseHelper _db = DatabaseHelper();

  Future<Map<String, dynamic>> getWeatherData(String city) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${Config.weatherApiBaseUrl}?q=$city&appid=${Config.apiKey}&units=metric&lang=tr'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'city': data['name'],
          'temperature': data['main']['temp'],
          'feels_like': data['main']['feels_like'],
          'humidity': data['main']['humidity'],
          'wind_speed': data['wind']['speed'],
          'pressure': data['main']['pressure'],
          'description': data['weather'][0]['description'],
          'icon': data['weather'][0]['icon'],
          'date_time': DateTime.now().toIso8601String(),
        };
      } else {
        throw Exception('Hava durumu verisi alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Hava durumu verisi alınamadı: $e');
    }
  }

  Future<void> saveWeatherData(
      int userId, Map<String, dynamic> weatherData) async {
    try {
      // Hava durumu verisini kaydet
      await _db.insertWeatherData({
        'user_id': userId,
        ...weatherData,
      });

      // Hava durumu geçmişine ekle
      await _db.addWeatherHistory({
        'user_id': userId,
        ...weatherData,
      });
    } catch (e) {
      throw Exception('Hava durumu verisi kaydedilemedi: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getWeatherHistory(int userId) async {
    try {
      return await _db.getWeatherHistory(userId);
    } catch (e) {
      throw Exception('Hava durumu geçmişi alınamadı: $e');
    }
  }

  Future<void> addFavoriteCity(
      int userId, String cityName, String countryCode) async {
    try {
      await _db.addFavoriteCity({
        'user_id': userId,
        'city_name': cityName,
        'country_code': countryCode,
        'added_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Favori şehir eklenemedi: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getFavoriteCities(int userId) async {
    try {
      return await _db.getFavoriteCities(userId);
    } catch (e) {
      throw Exception('Favori şehirler alınamadı: $e');
    }
  }

  Future<void> removeFavoriteCity(int userId, String cityName) async {
    try {
      await _db.removeFavoriteCity(userId, cityName);
    } catch (e) {
      throw Exception('Favori şehir silinemedi: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserPreferences(int userId) async {
    try {
      return await _db.getUserPreferences(userId);
    } catch (e) {
      throw Exception('Kullanıcı tercihleri alınamadı: $e');
    }
  }

  Future<void> updateUserPreferences(
      int userId, Map<String, dynamic> preferences) async {
    try {
      await _db.updateUserPreferences(userId, preferences);
    } catch (e) {
      throw Exception('Kullanıcı tercihleri güncellenemedi: $e');
    }
  }
}
