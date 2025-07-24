class ApiConfig {
  // Base URL for the WordPress REST API
  static const String baseUrl = 'http://sleepfoundationv2.local';
  
  // WordPress REST API endpoints that require authentication
  static const String articlesEndpoint = '/wp-json/wp/v2/article';
  static const String commercialEndpoint = '/wp-json/wp/v2/commercial';
  static const String categoriesEndpoint = '/wp-json/wp/v2/article_categories/';
  
  // API headers
  static const String apiKeyHeader = 'X-SF-API-Key';
  static const String contentTypeHeader = 'Content-Type';
  static const String contentTypeJson = 'application/json';
  
  // Rate limiting
  static const int maxRequestsPerHour = 100;
  static const Duration rateLimitWindow = Duration(hours: 1);
  
  // Retry configuration
  static const int maxRetries = 3;
  static const Duration initialRetryDelay = Duration(seconds: 1);
  static const double backoffMultiplier = 2.0;
  
  // Build full URL for an endpoint
  static String buildUrl(String endpoint, {Map<String, String>? queryParams}) {
    var uri = Uri.parse('$baseUrl$endpoint');
    
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }
    
    return uri.toString();
  }
  
  // Common query parameters for articles
  static Map<String, String> getArticleParams({
    String orderBy = 'last_modifed_date',
    int perPage = 10,
    int offset = 0,
    String? category,
  }) {
    final params = <String, String>{
      'orderby': orderBy,
      'per_page': perPage.toString(),
      'offset': offset.toString(),
    };
    
    if (category != null && category.isNotEmpty) {
      params['category'] = category;
    }
    
    return params;
  }
}