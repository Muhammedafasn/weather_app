import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String selectedCity = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şehir Ara'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Şehir Adı',
                hintText: 'Şehir adını girin',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  setState(() {
                    selectedCity = value;
                  });
                  Navigator.pop(context, selectedCity);
                }
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_searchController.text.isNotEmpty) {
                  setState(() {
                    selectedCity = _searchController.text;
                  });
                  Navigator.pop(context, selectedCity);
                }
              },
              child: const Text('Ara'),
            ),
          ],
        ),
      ),
    );
  }
}
