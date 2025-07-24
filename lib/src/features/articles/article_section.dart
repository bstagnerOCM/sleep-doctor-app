import 'package:flutter/material.dart';
import 'dart:convert';
import '../../utils/remove_html.dart';
import '../../services/api_service.dart';
import 'article_detail.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class ArticleSection extends StatefulWidget {
  final String url;
  final String title;
  final String domain;

  const ArticleSection(
      {super.key,
      required this.url,
      required this.title,
      required this.domain});

  @override
  ArticleSectionState createState() => ArticleSectionState();
}

class ArticleSectionState extends State<ArticleSection>
    with AutomaticKeepAliveClientMixin {
  Future<List<Post>>? _cachedPosts;

  @override
  void initState() {
    super.initState();
    _cachedPosts ??= fetchPosts();
  }

  Future<List<Post>> fetchPosts() async {
    try {
      final response = await ApiService.instance.get(widget.url);
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load posts from article section: $e');
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
    super.build(context); // Important for AutomaticKeepAliveClientMixin
    return FutureBuilder<List<Post>>(
      future: _cachedPosts,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          var firstPost = snapshot.data!.first;
          return SizedBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(widget.title,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                InkWell(
                  splashColor: Colors.blue.withAlpha(30),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ArticleDetailScreen(
                              link: firstPost.link, domain: widget.domain)),
                    );
                  },
                  child: Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.background,
                    surfaceTintColor: Colors.transparent,
                    child: Column(
                      children: [
                        if (firstPost.imageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                                8.0), // Adjust the radius as needed
                            child: Image.network(firstPost.imageUrl!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover),
                          ),
                        SizedBox(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(firstPost.title,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onBackground,
                                      size: 18.0,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      firstPost.lastModifiedDate != 'No Date'
                                          ? DateFormat('MMM dd yyyy').format(
                                              DateTime.parse(
                                                  firstPost.lastModifiedDate))
                                          : 'No Date',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onBackground,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                for (var i = 1; i < snapshot.data!.length; i++)
                  InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ArticleDetailScreen(
                                  link: snapshot.data![i].link,
                                  domain: widget.domain)),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(
                            bottom: 8.0, top: 16.0, left: 8.0, right: 8.0),
                        child: Card(
                            elevation: 0,
                            color: Theme.of(context).colorScheme.background,
                            surfaceTintColor: Colors.transparent,
                            child: IntrinsicHeight(
                                child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(snapshot.data![i].title,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onBackground,
                                              size: 18.0,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                                snapshot.data![i].lastModifiedDate != 'No Date'
                                                    ? DateFormat('MMM dd yyyy')
                                                        .format(DateTime.parse(
                                                            snapshot.data![i]
                                                                .lastModifiedDate))
                                                    : 'No Date',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .displaySmall),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (snapshot.data![i].imageUrl != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                      snapshot.data![i].imageUrl!,
                                      width: 100, // Adjust width as needed
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                              ],
                            ))),
                      )),
                Divider(
                    color: Theme.of(context).colorScheme.outline,
                    height: 40,
                    indent: 100,
                    endIndent: 100)
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }
        return const Center(
            child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(),
          ),
        ));
      },
    );
  }

  @override
  bool get wantKeepAlive => true; // Keep state alive
}

class Post {
  final String title;
  final String lastModifiedDate;
  final String? excerpt;
  final String? imageUrl;
  final String? link;

  Post({
    required this.title,
    required this.lastModifiedDate,
    this.excerpt,
    this.imageUrl,
    this.link,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      title: json['title']['rendered'] ?? 'No Title',
      lastModifiedDate: json['yoast_head_json']['schema']['@graph'][0]
              ['dateModified'] ??
          'No Date',
      excerpt: stripHtml(json['excerpt']['rendered'] ?? 'No Excerpt'),
      imageUrl: json['yoast_head_json']['og_image']?[0]['url'],
      link: json['link'], // Extract the article link
    );
  }
}
