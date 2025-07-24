import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import './category_details.dart';

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
    final response = await http.get(Uri.parse(
        'http://sleepfoundationv2.local/wp-json/wp/v2/article_categories/'));

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      _cachedCategories =
          data.values.map((json) => Category.fromJson(json)).toList();
      return _cachedCategories!;
    } else {
      throw Exception('Failed to load categories');
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CategoryDetailScreen(
                                url:
                                    'http://sleepfoundationv2.local/wp-json/wp/v2/article?orderby=last_modifed_date&category=${category.slug}&per_page=10&offset=0',
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
