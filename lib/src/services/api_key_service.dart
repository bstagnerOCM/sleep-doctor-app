import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class ApiKeyService {
  static const String _apiKeyStorageKey = 'sf_api_key';
  
  // Configure secure storage with platform-specific options
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      groupId: null,
      accountName: 'SleepDoctor',
      synchronizable: false,
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    lOptions: LinuxOptions(),
    wOptions: WindowsOptions(),
    mOptions: MacOsOptions(
      groupId: null,
      accountName: 'SleepDoctor',
      synchronizable: false,
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Store the API key securely
  static Future<void> storeApiKey(String apiKey) async {
    try {
      await _secureStorage.write(key: _apiKeyStorageKey, value: apiKey);
      if (kDebugMode) {
        print('API key stored successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to store API key: $e');
      }
      rethrow;
    }
  }

  /// Retrieve the API key from secure storage
  static Future<String?> getApiKey() async {
    try {
      final apiKey = await _secureStorage.read(key: _apiKeyStorageKey);
      return apiKey;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to retrieve API key: $e');
      }
      return null;
    }
  }

  /// Check if an API key is stored
  static Future<bool> hasApiKey() async {
    try {
      final apiKey = await getApiKey();
      return apiKey != null && apiKey.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to check API key existence: $e');
      }
      return false;
    }
  }

  /// Delete the stored API key
  static Future<void> deleteApiKey() async {
    try {
      await _secureStorage.delete(key: _apiKeyStorageKey);
      if (kDebugMode) {
        print('API key deleted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to delete API key: $e');
      }
      rethrow;
    }
  }

  /// Clear all stored data (use with caution)
  static Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
      if (kDebugMode) {
        print('All secure storage data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to clear secure storage: $e');
      }
      rethrow;
    }
  }

  /// Validate API key format (basic validation)
  static bool isValidApiKeyFormat(String apiKey) {
    // Basic validation - adjust as needed based on your API key format
    return apiKey.isNotEmpty && 
           apiKey.length >= 10 && 
           apiKey.length <= 100 &&
           !apiKey.contains(' '); // No spaces in API keys
  }
}