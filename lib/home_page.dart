import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'search_page.dart';
import 'widgets/daily_weather_card.dart';
import 'package:http/http.dart' as http;
import 'package:loading_indicator/loading_indicator.dart';
import 'package:geolocator/geolocator.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  static String APIKEY = '2ad7faa3104a0b4cb2194b48271efb45';

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String location = 'Bursa';
  String code = 'Clear';
  double? temperature;
  String icon = '';
  List<CardDailyItem> cardDailyItems = [];

  var locationData;
  Position? position;

  Future<void> getLocationData() async {
    locationData = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$location&appid=${MyHomePage.APIKEY}&units=metric'));
    final locationDataParsed = jsonDecode(locationData.body);

    setState(() {
      temperature = locationDataParsed['main']['temp'];
      location = locationDataParsed['name'];
      icon = locationDataParsed['weather'].first['icon'];
      code = locationDataParsed['weather'].first['main'];
    });
    getDailyForecastByLocation();
  }

  Future<void> getDevicePosition() async {
    position = await _determinePosition();
    print('device poisiton:');
    print(position);
  }

  Future<void> getLocationDataFromApiByLocation() async {
    if (position != null) {
      setState(() {
        temperature = null;
      });

      locationData = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=${position!.latitude}&lon=${position!.longitude}&appid=${MyHomePage.APIKEY}&units=metric'));
      final locationDataParsed = jsonDecode(locationData.body);

      setState(() {
        temperature = locationDataParsed['main']['temp'];
        location = locationDataParsed['name'];
        icon = locationDataParsed['weather'].first['icon'];
        code = locationDataParsed['weather'].first['main'];
      });
    }
  }

  Future<void> getDailyForecastByLatLon() async {
    cardDailyItems.clear();
    var forecast = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?lat=${position!.latitude}&lon=${position!.longitude}&appid=${MyHomePage.APIKEY}&units=metric'));
    final forecastParsed = jsonDecode(forecast.body);

    print(forecastParsed['list'][39]['main']['temp']);
    setState(() {
      for (int i = 7; i <= 39; i += 8) {
        cardDailyItems.add(CardDailyItem(
            temperature: forecastParsed['list'][i]['main']['temp'],
            icon: forecastParsed['list'][i]['weather'][0]['icon'],
            date: forecastParsed['list'][i]['dt_txt']));
      }
    });
  }

  Future<void> getDailyForecastByLocation() async {
    cardDailyItems.clear();
    var forecast = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?q=${location}&appid=${MyHomePage.APIKEY}&units=metric'));
    final forecastParsed = jsonDecode(forecast.body);

    setState(() {
      for (int i = 7; i <= 39; i += 8) {
        cardDailyItems.add(CardDailyItem(
            temperature: forecastParsed['list'][i]['main']['temp'],
            icon: forecastParsed['list'][i]['weather'][0]['icon'],
            date: forecastParsed['list'][i]['dt_txt']));
      }
    });
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  void loadData() async {
    await getDevicePosition();
    await getLocationDataFromApiByLocation();
    await getDailyForecastByLatLon();
  }

  @override
  void initState() {
    loadData();
    print('init state');

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
            image: AssetImage('assets/$code.jpg'), fit: BoxFit.cover),
      ),
      child: (temperature == null || cardDailyItems.isEmpty)
          ? const Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 150,
                    child: LoadingIndicator(
                        indicatorType: Indicator.ballGridPulse,

                        /// Required, The loading type of the widget
                        colors: const [
                          Colors.red,
                          Colors.orange,
                          Colors.yellow,
                          Colors.green,
                          Colors.blue,
                          Colors.indigo,
                          Colors.purple,
                        ],

                        /// Optional, The color collections
                        strokeWidth: 2,

                        /// Optional, The stroke of the line, only applicable to widget which contains line
                        backgroundColor: Colors.transparent,

                        /// Optional, Background of the widget
                        pathBackgroundColor: Colors.black

                        /// Optional, the stroke backgroundColor
                        ),
                  ),
                  Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        'Hava durumu bilgisi bekleniyor..',
                        style: TextStyle(
                            fontSize: 23,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ))
                ],
              )),
            )
          : Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(
                        height: 150,
                        child: Image.network(
                            'https://openweathermap.org/img/wn/$icon@4x.png'),
                      ),
                      Text(
                        "$temperature° C",
                        style: const TextStyle(
                            fontSize: 70, fontWeight: FontWeight.w700),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            location,
                            style: TextStyle(fontSize: 30),
                          ),
                          IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () async {
                              temperature = null;
                              final selectedCity = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SearchPage()));
                              location = selectedCity;
                              getLocationData();
                            },
                          )
                        ],
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: cardDailyItems.length,
                          itemBuilder: (BuildContext context, int index) {
                            return DailyWeatherCard(
                              cardDailyItem: cardDailyItems[index],
                            );
                          },
                        ),
                      )
                    ]),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () async {
                  await getLocationDataFromApiByLocation();
                  await getDailyForecastByLocation();
                },
                child: Icon(Icons.location_searching),
              ),
            ),
    );
  }
}
