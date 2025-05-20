import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static String get apiKey {
    final key = dotenv.env['OPENWEATHER_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('OPENWEATHER_API_KEY is not set in .env file');
    }
    return key;
  }

  static String get serverUrl {
    return dotenv.env['SERVER_URL'] ?? 'http://192.168.1.105:3000';
  }

  static const String defaultCity = 'Ankara';
  static const int connectionTimeout = 10;
  static const int receiveTimeout = 10;

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static const String weatherApiBaseUrl =
      'https://api.openweathermap.org/data/2.5';
  static const String weatherIconBaseUrl = 'https://openweathermap.org/img/wn';
}
