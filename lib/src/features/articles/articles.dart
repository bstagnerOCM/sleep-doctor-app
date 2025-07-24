import 'package:flutter/material.dart';
import '../../utils/remove_html.dart';
import '../../services/api_service.dart';
import 'package:flutter/foundation.dart';

class Articles extends StatefulWidget {
  final VoidCallback onBack;

  const Articles({super.key, required this.onBack});

  @override
  ArticlesState createState() => ArticlesState();
}

class ArticlesState extends State<Articles> {
  late Future<List<Post>> posts;

  @override
  void initState() {
    super.initState();
    posts = fetchPosts();
  }

  Future<List<Post>> fetchPosts() async {
    try {
      final data = await ApiService.instance.fetchArticles(
        orderBy: 'last_modifed_date',
        perPage: 2,
        offset: 0,
      );
      return data.map((json) => Post.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load posts: $e');
      }
      
      // Provide user-friendly error messages
      String errorMessage = 'Failed to load articles';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Post>>(
        future: posts,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Latest',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      var post = snapshot.data![index];
                      return Card(
                        child: index == 0
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (post.imageUrl != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                          8.0), // Adjust the radius as needed
                                      child: Image.network(post.imageUrl!),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(post.title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Text(post.lastModifiedDate),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                        post.excerpt ?? 'No excerpt available'),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    flex: 7,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(post.title,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text(post.lastModifiedDate),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (post.imageUrl != null)
                                    Expanded(
                                      flex: 3, // 30% width for image
                                      child: Image.network(
                                        post.imageUrl!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                ],
                              ),
                      );
                    },
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          }

          return const CircularProgressIndicator();
        },
      ),
    );
  }
}

class Post {
  final String title;
  final String lastModifiedDate;
  final String? excerpt;
  final String? imageUrl; // Optional field for image URL

  Post({
    required this.title,
    required this.lastModifiedDate,
    required this.excerpt,
    this.imageUrl,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      title: json['title']['rendered'] ?? 'No Title',
      lastModifiedDate: json['yoast_head_json']['schema']['@graph'][0]
              ['dateModified'] ??
          'No Date',
      excerpt: stripHtml(json['excerpt']['rendered'] ?? 'No Excerpt'),
      imageUrl: json['yoast_head_json']['og_image']?[0]
          ['url'], // Extract the image URL
    );
  }
}
