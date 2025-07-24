import 'package:flutter/material.dart';
import 'package:sleep_doctor/main.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  SettingsState createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  final _storage = const FlutterSecureStorage();
  late List<Map<String, dynamic>> settings;
  late List<Map<String, dynamic>> betaAdminSettings;

  @override
  void initState() {
    super.initState();

    // Access the state from ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    settings = [
      {
        'title': 'Enable Dark Mode',
        'description': 'Enable to activate Dark Mode',
        'isChecked': false,
      },
      {
        'title': 'Enable Notifications',
        'description':
            'Get notified when new articles are published or updated',
        'isChecked': false,
      },
    ];

    void updateSetting(String key, bool value) async {
      final existingValue = await _storage.read(key: key);
      if (existingValue != null) {
        // Key already exists, delete it first
        await _storage.delete(key: key);
      }
      await _storage.write(key: key, value: value ? 'true' : 'false');
    }

    void loadSettings() async {
      setState(() {
        settings = [
          {
            'title': 'Enable Dark Mode',
            'description': 'Enable to activate Dark Mode',
            'isChecked':
                themeProvider.themeMode == ThemeMode.dark ? true : false,
            'callback': (bool value) {
              themeProvider.toggleTheme(value);
              updateSetting('darkModeEnabled', value);
            }
          },
          {
            'title': 'Enable Notifications',
            'description':
                'Get notified when new articles are published or updated',
            'isChecked': themeProvider.isNotificationsEnabled,
            'callback': (bool value) {
              updateSetting('notificationsEnabled', value);
            },
          },
        ];
      });
    }

    loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ...settings.map((setting) => _buildSettingItem(setting)).toList(),
          const SizedBox(height: 20),
          _buildLogoutItem(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    void logoutUser() async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Perform logout operations
      await _storage.deleteAll();
      await authProvider.signOut();

      if (mounted) {
        Navigator.pop(context);
      }
    }

    return GestureDetector(
      onTap: () {
        logoutUser(); // Call the logout function
      },
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.logout, color: Colors.redAccent),
              SizedBox(width: 12),
              Text(
                "Logout",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildSettingItem(Map<String, dynamic> setting) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          setting['title'],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                setting['description'],
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 24),
            Switch(
              value: setting['isChecked'],
              onChanged: (bool value) {
                setState(() {
                  setting['isChecked'] = value;
                  // Call the callback function
                  if (setting['callback'] != null) {
                    setting['callback'](value);
                  }
                });
              },
            ),
          ],
        ),
        const Divider(color: Colors.grey),
      ],
    );
  }
}
