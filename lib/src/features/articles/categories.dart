import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/api_config.dart';
import './category_details.dart';
import 'package:flutter/foundation.dart';

class Categories extends StatefulWidget {
  const Categories({super.key});

  @override
  CategoriesState createState() => CategoriesState();
}

class CategoriesState extends State<Categories> {
  static List<Category>? _cachedCategories;
  late Future<List<Category>> categories;

  @override
  void initState() {
    super.initState();
    if (_cachedCategories == null) {
      categories = fetchCategories();
    } else {
      categories = Future.value(_cachedCategories);
    }
  }

  Future<List<Category>> fetchCategories() async {
    try {
      final data = await ApiService.instance.fetchCategories();
      _cachedCategories =
          data.values.map((json) => Category.fromJson(json)).toList();
      return _cachedCategories!;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load categories: $e');
      }
      
      // Provide user-friendly error messages
      String errorMessage = 'Failed to load categories';
      if (e is AuthenticationException) {
        errorMessage = 'Authentication failed. Please check your API key in settings.';
      } else if (e is RateLimitException) {
        errorMessage = 'Too many requests. Please try again later.';
      } else if (e is ApiException) {
        errorMessage = e.message;
      }
      
      throw Exception(errorMessage);
    }
  }

  Future<void> _refreshCategories() async {
    setState(() {
      categories = fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshCategories,
        child: FutureBuilder<List<Category>>(
          future: categories,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                _cachedCategories == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('${snapshot.error}');
            }
            if (snapshot.hasData) {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  Category category = snapshot.data![index];
                  return ListTile(
                    title: Text(category.name,
                        style: Theme.of(context).textTheme.bodyLarge),
                    onTap: () {
                      final categoryUrl = ApiConfig.buildUrl(
                        ApiConfig.articlesEndpoint,
                        queryParams: ApiConfig.getArticleParams(
                          category: category.slug,
                        ),
                      );
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CategoryDetailScreen(
                                url: categoryUrl,
                                title: category.name)),
                      );
                    },
                  );
                },
              );
            } else {
              return const Text('No data available');
            }
          },
        ),
      ),
    );
  }
}

class Category {
  final String name;
  final int landingPage;
  final String postType;
  final String slug;

  Category({
    required this.name,
    required this.landingPage,
    required this.postType,
    required this.slug,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      name: json['category_name'] ?? 'No Name',
      landingPage: json['landing_page'] ?? 0,
      postType: json['post_type'] ?? '',
      slug: json['slug'] ?? '',
    );
  }
}
