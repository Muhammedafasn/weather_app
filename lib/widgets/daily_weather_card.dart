import 'package:flutter/material.dart';
import '../utils.dart';

class CardDailyItem {
  final double temperature;
  final String icon;
  final String date;

  CardDailyItem({
    required this.temperature,
    required this.icon,
    required this.date,
  });
}

class DailyWeatherCard extends StatelessWidget {
  final CardDailyItem cardDailyItem;

  const DailyWeatherCard({
    Key? key,
    required this.cardDailyItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              formatDateTime(cardDailyItem.date),
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Image.network(
              'https://openweathermap.org/img/wn/${cardDailyItem.icon}@2x.png',
              width: 50,
              height: 50,
            ),
            const SizedBox(height: 8),
            Text(
              formatTemperature(cardDailyItem.temperature),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
