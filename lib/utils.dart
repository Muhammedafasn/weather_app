import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'config.dart';

void snackbarShow(BuildContext context, String message,
    {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? Colors.red : Colors.blue,
      action: SnackBarAction(
        label: 'Tamam',
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ),
  );
}

Future<bool> checkInternetConnection() async {
  try {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }

    // Gerçek internet bağlantısını test et
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  } catch (e) {
    print('İnternet bağlantısı kontrol edilemedi: $e');
    return false;
  }
}

Future<void> sendWeatherToServer(Map<String, dynamic> weather) async {
  if (!await checkInternetConnection()) {
    throw Exception(
        'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.');
  }

  try {
    final response = await http
        .post(
          Uri.parse('${Config.serverUrl}/weather'),
          headers: Config.headers,
          body: json.encode(weather),
        )
        .timeout(Duration(seconds: Config.connectionTimeout));

    if (response.statusCode != 200) {
      throw Exception(
          'Sunucu hatası: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    if (e is http.ClientException) {
      throw Exception(
          'Sunucuya bağlanılamadı. Lütfen internet bağlantınızı kontrol edin.');
    } else if (e is SocketException) {
      throw Exception(
          'Sunucuya bağlanılamadı. Lütfen sunucunun çalıştığından emin olun.');
    } else if (e is TimeoutException) {
      throw Exception(
          'Sunucu yanıt vermedi. Lütfen daha sonra tekrar deneyin.');
    } else {
      throw Exception('Sunucuya bağlanırken hata: $e');
    }
  }
}

Future<void> testServerConnection() async {
  if (!await checkInternetConnection()) {
    print('İnternet bağlantısı yok');
    return;
  }

  try {
    final response = await http
        .get(
          Uri.parse('${Config.serverUrl}/test'),
        )
        .timeout(Duration(seconds: Config.connectionTimeout));

    if (response.statusCode == 200) {
      print('Sunucu bağlantısı başarılı');
    } else {
      print('Sunucu bağlantısı başarısız: ${response.statusCode}');
    }
  } catch (e) {
    if (e is http.ClientException) {
      print(
          'Sunucuya bağlanılamadı. Lütfen internet bağlantınızı kontrol edin.');
    } else if (e is SocketException) {
      print(
          'Sunucuya bağlanılamadı. Lütfen sunucunun çalıştığından emin olun.');
    } else if (e is TimeoutException) {
      print('Sunucu yanıt vermedi. Lütfen daha sonra tekrar deneyin.');
    } else {
      print('Sunucu bağlantı hatası: $e');
    }
  }
}

String formatDateTime(String dateTime) {
  try {
    final date = DateTime.parse(dateTime);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  } catch (e) {
    return dateTime;
  }
}

String formatTemperature(double? temperature) {
  if (temperature == null) return '...';
  return '${temperature.toStringAsFixed(1)}° C';
}

String formatWindSpeed(double? speed) {
  if (speed == null) return '...';
  return '${speed.toStringAsFixed(1)} m/s';
}

String formatHumidity(int? humidity) {
  if (humidity == null) return '...';
  return '$humidity%';
}

String formatPressure(int? pressure) {
  if (pressure == null) return '...';
  return '$pressure hPa';
}
