import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'weather_database.dart';
import 'utils.dart';
import 'config.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String city = Config.defaultCity;
  double? temperature;
  double? feelsLike;
  int? humidity;
  double? windSpeed;
  int? pressure;
  String? description;
  String? icon;
  String? country;
  int? sunrise;
  int? sunset;
  int? clouds;
  int? visibility;
  bool isLoading = false;
  List<Map<String, dynamic>> history = [];

  Future<void> fetchAndSaveWeather(String city) async {
    if (!await checkInternetConnection()) {
      snackbarShow(context,
          'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.');
      return;
    }

    setState(() => isLoading = true);
    try {
      final url =
          '${Config.weatherApiBaseUrl}/weather?q=$city&appid=${Config.apiKey}&units=metric&lang=tr';
      final response = await http
          .get(Uri.parse(url))
          .timeout(Duration(seconds: Config.connectionTimeout));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          this.city = city;
          temperature = data['main']['temp'];
          feelsLike = data['main']['feels_like'];
          humidity = data['main']['humidity'];
          pressure = data['main']['pressure'];
          windSpeed = data['wind']['speed'];
          description = data['weather'][0]['description'];
          icon = data['weather'][0]['icon'];
          country = data['sys']['country'];
          sunrise = data['sys']['sunrise'];
          sunset = data['sys']['sunset'];
          clouds = data['clouds']['all'];
          visibility = data['visibility'];
        });

        final weather = {
          'city': city,
          'temperature': temperature,
          'feelsLike': feelsLike,
          'humidity': humidity,
          'windSpeed': windSpeed,
          'pressure': pressure,
          'description': description,
          'icon': icon,
          'country': country,
          'sunrise': sunrise,
          'sunset': sunset,
          'clouds': clouds,
          'visibility': visibility,
          'dateTime': DateTime.now().toIso8601String(),
        };

        // Veritabanına kaydet
        await WeatherDatabase.instance.insertWeather(weather);

        // Sunucuya gönder
        try {
          await sendWeatherToServer(weather);
          snackbarShow(context, 'Veriler sunucuya gönderildi');
        } catch (e) {
          snackbarShow(context, 'Sunucuya gönderilirken hata: $e');
        }

        await loadHistory();
      } else if (response.statusCode == 404) {
        throw Exception('Şehir bulunamadı: $city');
      } else if (response.statusCode == 401) {
        throw Exception(
            'API anahtarı geçersiz. Lütfen .env dosyasını kontrol edin.');
      } else {
        throw Exception('Hava durumu alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      snackbarShow(context, 'Hata: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> loadHistory() async {
    try {
      history = await WeatherDatabase.instance.getAllWeather();
      setState(() {});
    } catch (e) {
      snackbarShow(context, 'Geçmiş yüklenirken hata: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAndSaveWeather(city);
    loadHistory();
    testServerConnection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          SizedBox.expand(
            child: Image.network(
              'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.blue[900],
                  child: const Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                );
              },
            ),
          ),
          Container(color: Colors.black.withOpacity(0.2)),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Weather icon
                if (icon != null)
                  Image.network(
                    '${Config.weatherIconBaseUrl}/$icon@2x.png',
                    width: 100,
                    height: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.wb_sunny,
                        color: Colors.deepOrange,
                        size: 80,
                      );
                    },
                  ),
                const SizedBox(height: 16),
                // Temperature
                Text(
                  temperature != null
                      ? '${temperature!.toStringAsFixed(1)}° C'
                      : '...',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black45,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                if (feelsLike != null)
                  Text(
                    'Hissedilen: ${feelsLike!.toStringAsFixed(1)}° C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                const SizedBox(height: 8),
                // City name and search
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$city${country != null ? ', $country' : ''}',
                      style: const TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            blurRadius: 8,
                            color: Colors.black45,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: () async {
                        final result = await showDialog<String>(
                          context: context,
                          builder: (context) {
                            String input = '';
                            return AlertDialog(
                              title: const Text('Şehir Ara'),
                              content: TextField(
                                onChanged: (value) => input = value,
                                decoration: const InputDecoration(
                                    hintText: 'Şehir adı'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, input),
                                  child: const Text('Ara'),
                                ),
                              ],
                            );
                          },
                        );
                        if (result != null && result.isNotEmpty) {
                          fetchAndSaveWeather(result);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 16),
                // Weather details
                if (humidity != null || windSpeed != null || pressure != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        if (humidity != null)
                          _buildWeatherDetail(
                              Icons.water_drop, '$humidity%', 'Nem'),
                        if (windSpeed != null)
                          _buildWeatherDetail(Icons.air,
                              '${windSpeed!.toStringAsFixed(1)} m/s', 'Rüzgar'),
                        if (pressure != null)
                          _buildWeatherDetail(
                              Icons.speed, '$pressure hPa', 'Basınç'),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),
                if (isLoading)
                  const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Geçmiş Sorgular',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];
                      return Card(
                        color: Colors.white.withOpacity(0.7),
                        child: ListTile(
                          title: Text(
                              '${item['city']} - ${item['temperature']}°C'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${item['description']}'),
                              if (item['humidity'] != null)
                                Text('Nem: ${item['humidity']}%'),
                              if (item['windSpeed'] != null)
                                Text('Rüzgar: ${item['windSpeed']} m/s'),
                            ],
                          ),
                          trailing: Text(
                              '${item['dateTime'].toString().substring(0, 16).replaceAll('T', ' ')}'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
