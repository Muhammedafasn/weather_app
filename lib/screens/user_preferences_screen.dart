import 'package:flutter/material.dart';
import '../database_helper.dart';

class UserPreferencesScreen extends StatefulWidget {
  final int userId;

  const UserPreferencesScreen({Key? key, required this.userId})
      : super(key: key);

  @override
  State<UserPreferencesScreen> createState() => _UserPreferencesScreenState();
}

class _UserPreferencesScreenState extends State<UserPreferencesScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  Map<String, dynamic>? _preferences;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final preferences = await _db.getUserPreferences(widget.userId);
      setState(() {
        _preferences = preferences;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tercihler yüklenemedi: $e')),
      );
    }
  }

  Future<void> _updatePreference(String key, dynamic value) async {
    try {
      await _db.updateUserPreferences(widget.userId, {
        key: value,
        'last_updated': DateTime.now().toIso8601String(),
      });
      await _loadPreferences();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tercih güncellendi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tercih güncellenemedi: $e')),
      );
    }
  }

  Future<void> _resetPreferences() async {
    try {
      await _db.resetUserPreferences(widget.userId);
      await _loadPreferences();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tercihler sıfırlandı')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tercihler sıfırlanamadı: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_preferences == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tercihler')),
        body: const Center(child: Text('Tercihler bulunamadı')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Tercihleri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetPreferences,
            tooltip: 'Tercihleri Sıfırla',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Varsayılan Şehir
          ListTile(
            title: const Text('Varsayılan Şehir'),
            subtitle: Text(_preferences!['default_city'] ?? 'Istanbul'),
            trailing: const Icon(Icons.location_city),
          ),
          const Divider(),

          // Sıcaklık Birimi
          ListTile(
            title: const Text('Sıcaklık Birimi'),
            subtitle: Text(_preferences!['temperature_unit'] == 'celsius'
                ? 'Celsius'
                : 'Fahrenheit'),
            trailing: Switch(
              value: _preferences!['temperature_unit'] == 'celsius',
              onChanged: (value) => _updatePreference(
                'temperature_unit',
                value ? 'celsius' : 'fahrenheit',
              ),
            ),
          ),
          const Divider(),

          // Dil
          ListTile(
            title: const Text('Dil'),
            subtitle:
                Text(_preferences!['language'] == 'tr' ? 'Türkçe' : 'English'),
            trailing: Switch(
              value: _preferences!['language'] == 'tr',
              onChanged: (value) => _updatePreference(
                'language',
                value ? 'tr' : 'en',
              ),
            ),
          ),
          const Divider(),

          // Bildirimler
          ListTile(
            title: const Text('Bildirimler'),
            subtitle: Text(_preferences!['notifications_enabled'] == 1
                ? 'Açık'
                : 'Kapalı'),
            trailing: Switch(
              value: _preferences!['notifications_enabled'] == 1,
              onChanged: (value) => _updatePreference(
                'notifications_enabled',
                value ? 1 : 0,
              ),
            ),
          ),
          const Divider(),

          // Karanlık Tema
          ListTile(
            title: const Text('Karanlık Tema'),
            subtitle: Text(_preferences!['dark_mode'] == 1 ? 'Açık' : 'Kapalı'),
            trailing: Switch(
              value: _preferences!['dark_mode'] == 1,
              onChanged: (value) => _updatePreference(
                'dark_mode',
                value ? 1 : 0,
              ),
            ),
          ),
          const Divider(),

          // Güncelleme Aralığı
          ListTile(
            title: const Text('Güncelleme Aralığı'),
            subtitle:
                Text('${_preferences!['weather_update_interval']} dakika'),
            trailing: DropdownButton<int>(
              value: _preferences!['weather_update_interval'],
              items: [15, 30, 60, 120].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value dk'),
                );
              }).toList(),
              onChanged: (value) =>
                  _updatePreference('weather_update_interval', value),
            ),
          ),
          const Divider(),

          // Görüntüleme Ayarları
          ExpansionTile(
            title: const Text('Görüntüleme Ayarları'),
            children: [
              SwitchListTile(
                title: const Text('Nem Bilgisi'),
                value: _preferences!['show_humidity'] == 1,
                onChanged: (value) =>
                    _updatePreference('show_humidity', value ? 1 : 0),
              ),
              SwitchListTile(
                title: const Text('Rüzgar Bilgisi'),
                value: _preferences!['show_wind'] == 1,
                onChanged: (value) =>
                    _updatePreference('show_wind', value ? 1 : 0),
              ),
              SwitchListTile(
                title: const Text('Basınç Bilgisi'),
                value: _preferences!['show_pressure'] == 1,
                onChanged: (value) =>
                    _updatePreference('show_pressure', value ? 1 : 0),
              ),
              SwitchListTile(
                title: const Text('Hissedilen Sıcaklık'),
                value: _preferences!['show_feels_like'] == 1,
                onChanged: (value) =>
                    _updatePreference('show_feels_like', value ? 1 : 0),
              ),
              SwitchListTile(
                title: const Text('Hava Durumu İkonu'),
                value: _preferences!['show_weather_icon'] == 1,
                onChanged: (value) =>
                    _updatePreference('show_weather_icon', value ? 1 : 0),
              ),
            ],
          ),
          const Divider(),

          // Konum Ayarları
          ExpansionTile(
            title: const Text('Konum Ayarları'),
            children: [
              SwitchListTile(
                title: const Text('Otomatik Konum'),
                subtitle: const Text('Konumunuzu otomatik olarak kullan'),
                value: _preferences!['auto_location'] == 1,
                onChanged: (value) =>
                    _updatePreference('auto_location', value ? 1 : 0),
              ),
              SwitchListTile(
                title: const Text('Konum İzni'),
                subtitle: const Text('Konum servislerine erişim izni'),
                value: _preferences!['location_permission'] == 1,
                onChanged: (value) =>
                    _updatePreference('location_permission', value ? 1 : 0),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
