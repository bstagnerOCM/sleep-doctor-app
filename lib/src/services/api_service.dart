import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'api_config.dart';
import 'api_key_service.dart';

/// Custom exception for API-related errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? response;

  ApiException(this.message, {this.statusCode, this.response});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

/// Custom exception for rate limiting
class RateLimitException extends ApiException {
  final Duration? retryAfter;

  RateLimitException(String message, {this.retryAfter, int? statusCode})
      : super(message, statusCode: statusCode);
}

/// Custom exception for authentication errors
class AuthenticationException extends ApiException {
  AuthenticationException(String message, {int? statusCode})
      : super(message, statusCode: statusCode);
}

/// Service for making authenticated HTTP requests to WordPress REST API
class ApiService {
  static final ApiService _instance = ApiService._internal();
  static ApiService get instance => _instance;
  
  ApiService._internal();

  late final http.Client _client;
  DateTime? _lastRequestTime;
  int _requestCount = 0;

  /// Initialize the service
  void initialize() {
    _client = http.Client();
  }

  /// Dispose of resources
  void dispose() {
    _client.close();
  }

  /// Get headers with API authentication
  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      ApiConfig.contentTypeHeader: ApiConfig.contentTypeJson,
      'User-Agent': 'SleepDoctor-Flutter-App/1.0.0',
    };

    // Add API key if available
    final apiKey = await ApiKeyService.getApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      headers[ApiConfig.apiKeyHeader] = apiKey;
    } else {
      if (kDebugMode) {
        print('Warning: No API key found. Requests may fail.');
      }
    }

    return headers;
  }

  /// Check rate limiting before making requests
  void _checkRateLimit() {
    final now = DateTime.now();
    
    // Reset counter if hour has passed
    if (_lastRequestTime != null && 
        now.difference(_lastRequestTime!) > ApiConfig.rateLimitWindow) {
      _requestCount = 0;
    }
    
    if (_requestCount >= ApiConfig.maxRequestsPerHour) {
      throw RateLimitException(
        'Rate limit exceeded. Maximum ${ApiConfig.maxRequestsPerHour} requests per hour.',
        statusCode: 429,
      );
    }
    
    _lastRequestTime = now;
    _requestCount++;
  }

  /// Perform HTTP GET request with retry logic and error handling
  Future<http.Response> _performRequest(
    String url, {
    int retryCount = 0,
  }) async {
    try {
      _checkRateLimit();
      
      final headers = await _getHeaders();
      
      if (kDebugMode) {
        print('Making API request to: $url');
        print('Headers: ${headers.keys.join(', ')}');
      }

      final response = await _client.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw ApiException('Request timeout');
        },
      );

      // Handle different status codes
      switch (response.statusCode) {
        case 200:
          return response;
          
        case 403:
          throw AuthenticationException(
            'Authentication failed. Please check your API key.',
            statusCode: 403,
          );
          
        case 429:
          // Extract retry-after header if available
          Duration? retryAfter;
          final retryAfterHeader = response.headers['retry-after'];
          if (retryAfterHeader != null) {
            final seconds = int.tryParse(retryAfterHeader);
            if (seconds != null) {
              retryAfter = Duration(seconds: seconds);
            }
          }
          
          throw RateLimitException(
            'Rate limit exceeded. Try again later.',
            statusCode: 429,
            retryAfter: retryAfter,
          );
          
        case 404:
          throw ApiException(
            'Resource not found',
            statusCode: 404,
            response: response.body,
          );
          
        case 500:
        case 502:
        case 503:
        case 504:
          // Server errors - potentially retryable
          if (retryCount < ApiConfig.maxRetries) {
            return await _retryRequest(url, retryCount);
          }
          throw ApiException(
            'Server error: ${response.statusCode}',
            statusCode: response.statusCode,
            response: response.body,
          );
          
        default:
          throw ApiException(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
            statusCode: response.statusCode,
            response: response.body,
          );
      }
    } on SocketException {
      if (retryCount < ApiConfig.maxRetries) {
        return await _retryRequest(url, retryCount);
      }
      throw ApiException('Network error. Please check your connection.');
    } on HttpException catch (e) {
      throw ApiException('HTTP error: ${e.message}');
    } on FormatException catch (e) {
      throw ApiException('Invalid response format: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error: $e');
    }
  }

  /// Retry request with exponential backoff
  Future<http.Response> _retryRequest(String url, int retryCount) async {
    final delay = ApiConfig.initialRetryDelay * 
        (ApiConfig.backoffMultiplier * retryCount).round();
    
    if (kDebugMode) {
      print('Retrying request (attempt ${retryCount + 1}/${ApiConfig.maxRetries}) after ${delay.inSeconds}s delay');
    }
    
    await Future.delayed(delay);
    return _performRequest(url, retryCount: retryCount + 1);
  }

  /// Parse JSON response safely
  dynamic _parseJsonResponse(http.Response response) {
    try {
      return jsonDecode(response.body);
    } catch (e) {
      throw ApiException('Failed to parse response JSON: $e');
    }
  }

  /// Fetch articles with authentication
  Future<List<dynamic>> fetchArticles({
    String orderBy = 'last_modifed_date',
    int perPage = 10,
    int offset = 0,
    String? category,
  }) async {
    final queryParams = ApiConfig.getArticleParams(
      orderBy: orderBy,
      perPage: perPage,
      offset: offset,
      category: category,
    );
    
    final url = ApiConfig.buildUrl(ApiConfig.articlesEndpoint, queryParams: queryParams);
    final response = await _performRequest(url);
    final data = _parseJsonResponse(response);
    
    if (data is List) {
      return data;
    } else {
      throw ApiException('Expected array response for articles');
    }
  }

  /// Fetch categories with authentication
  Future<Map<String, dynamic>> fetchCategories() async {
    final url = ApiConfig.buildUrl(ApiConfig.categoriesEndpoint);
    final response = await _performRequest(url);
    final data = _parseJsonResponse(response);
    
    if (data is Map<String, dynamic>) {
      return data;
    } else {
      throw ApiException('Expected object response for categories');
    }
  }

  /// Fetch commercial content with authentication
  Future<List<dynamic>> fetchCommercial({
    int perPage = 10,
    int offset = 0,
  }) async {
    final queryParams = <String, String>{
      'per_page': perPage.toString(),
      'offset': offset.toString(),
    };
    
    final url = ApiConfig.buildUrl(ApiConfig.commercialEndpoint, queryParams: queryParams);
    final response = await _performRequest(url);
    final data = _parseJsonResponse(response);
    
    if (data is List) {
      return data;
    } else {
      throw ApiException('Expected array response for commercial content');
    }
  }

  /// Generic GET request for any URL (for backward compatibility)
  Future<http.Response> get(String url) async {
    return await _performRequest(url);
  }

  /// Check if API key is configured and service is ready
  Future<bool> isConfigured() async {
    return await ApiKeyService.hasApiKey();
  }

  /// Test API connection
  Future<bool> testConnection() async {
    try {
      await fetchCategories();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('API connection test failed: $e');
      }
      return false;
    }
  }
}