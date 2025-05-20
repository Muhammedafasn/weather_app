// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/main.dart';
import 'package:weather_app/home_page.dart';
import 'package:weather_app/widgets/daily_weather_card.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app starts with the home page
    expect(find.byType(MyHomePage), findsOneWidget);
  });

  testWidgets('DailyWeatherCard test', (WidgetTester tester) async {
    // Create a test CardDailyItem
    final testItem = CardDailyItem(
      temperature: 25.5,
      icon: '01d',
      date: '2024-03-20 12:00:00',
    );

    // Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DailyWeatherCard(cardDailyItem: testItem),
        ),
      ),
    );

    // Verify that the card displays the correct information
    expect(find.text('20/3/2024 12:00'), findsOneWidget);
    expect(find.text('25.5° C'), findsOneWidget);
  });
}
