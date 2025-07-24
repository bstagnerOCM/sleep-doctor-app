import 'package:flutter/material.dart';
import 'package:sleep_doctor/main.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/api_key_service.dart';
import '../../services/api_service.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  SettingsState createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  final _storage = const FlutterSecureStorage();
  late List<Map<String, dynamic>> settings;
  late List<Map<String, dynamic>> betaAdminSettings;
  final TextEditingController _apiKeyController = TextEditingController();
  bool _hasApiKey = false;
  bool _apiKeyTesting = false;
  String? _apiKeyStatus;

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
    _loadApiKeyStatus();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKeyStatus() async {
    final hasKey = await ApiKeyService.hasApiKey();
    setState(() {
      _hasApiKey = hasKey;
      _apiKeyStatus = hasKey ? 'API key configured' : 'No API key configured';
    });
  }

  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an API key')),
      );
      return;
    }

    if (!ApiKeyService.isValidApiKeyFormat(apiKey)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid API key format')),
      );
      return;
    }

    try {
      await ApiKeyService.storeApiKey(apiKey);
      await _loadApiKeyStatus();
      _apiKeyController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API key saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save API key: $e')),
        );
      }
    }
  }

  Future<void> _testApiConnection() async {
    setState(() {
      _apiKeyTesting = true;
    });

    try {
      final success = await ApiService.instance.testConnection();
      setState(() {
        _apiKeyStatus = success 
            ? 'API key configured ✓' 
            : 'API key configured but connection failed';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? 'API connection test successful!' 
                : 'API connection test failed. Check your key and network.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _apiKeyStatus = 'API connection test failed';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('API test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _apiKeyTesting = false;
      });
    }
  }

  Future<void> _removeApiKey() async {
    try {
      await ApiKeyService.deleteApiKey();
      await _loadApiKeyStatus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API key removed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove API key: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildApiKeySection(),
          const SizedBox(height: 20),
          ...settings.map((setting) => _buildSettingItem(setting)).toList(),
          const SizedBox(height: 20),
          _buildLogoutItem(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildApiKeySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'API Configuration',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Configure your WordPress REST API key for accessing articles, categories, and commercial content.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        
        // API Key Status
        Row(
          children: [
            Icon(
              _hasApiKey ? Icons.check_circle : Icons.warning,
              color: _hasApiKey ? Colors.green : Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _apiKeyStatus ?? 'Loading...',
                style: TextStyle(
                  color: _hasApiKey ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // API Key Input
        TextField(
          controller: _apiKeyController,
          decoration: InputDecoration(
            labelText: 'API Key',
            hintText: 'Enter your X-SF-API-Key value',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.key),
            suffixIcon: _apiKeyController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _apiKeyController.clear();
                      });
                    },
                  )
                : null,
          ),
          obscureText: true,
          onChanged: (value) {
            setState(() {}); // Rebuild to show/hide clear button
          },
        ),
        const SizedBox(height: 12),
        
        // Action Buttons
        Row(
          children: [
            ElevatedButton(
              onPressed: _saveApiKey,
              child: const Text('Save API Key'),
            ),
            const SizedBox(width: 8),
            if (_hasApiKey) ...[
              ElevatedButton(
                onPressed: _apiKeyTesting ? null : _testApiConnection,
                child: _apiKeyTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Test'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _removeApiKey,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Remove'),
              ),
            ],
          ],
        ),
        const Divider(color: Colors.grey),
      ],
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
