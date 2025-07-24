import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/remove_html.dart';
import 'article_detail.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sleep_doctor/main.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String url;
  final String title;

  const CategoryDetailScreen(
      {super.key, required this.url, required this.title});

  @override
  CategoryDetailScreenState createState() => CategoryDetailScreenState();
}

class CategoryDetailScreenState extends State<CategoryDetailScreen> {
  late Future<List<Post>> posts;

  @override
  void initState() {
    super.initState();
    posts = fetchPosts();
  }

  Future<List<Post>> fetchPosts() async {
    final response = await http.get(Uri.parse(widget.url));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Post.fromJson(json)).toList();
    } else {
      if (kDebugMode) {
        print('Failed to load posts: ${response.statusCode}, ${response.body}');
      }
      throw Exception('Failed to load posts: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(themeProvider.sdLogoAsset, height: 40),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(widget.title,
                  style: Theme.of(context).textTheme.titleLarge)),
          Expanded(
            child: FutureBuilder<List<Post>>(
              future: posts,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  var firstPost = snapshot.data!.first;
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          splashColor: Colors.blue.withAlpha(30),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ArticleDetailScreen(
                                      link: firstPost.link)),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(firstPost.title,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge),
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
                                              DateFormat('MMM dd yyyy').format(
                                                  DateTime.parse(firstPost
                                                      .lastModifiedDate)),
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
                                          link: snapshot.data![i].link)),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(
                                    bottom: 8.0,
                                    top: 16.0,
                                    left: 8.0,
                                    right: 8.0),
                                child: Card(
                                    elevation: 0,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .background,
                                    surfaceTintColor: Colors.transparent,
                                    child: IntrinsicHeight(
                                        child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                right: 8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(snapshot.data![i].title,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium),
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
                                                        DateFormat(
                                                                'MMM dd yyyy')
                                                            .format(DateTime
                                                                .parse(snapshot
                                                                    .data![i]
                                                                    .lastModifiedDate)),
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
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            child: Image.network(
                                              snapshot.data![i].imageUrl!,
                                              width:
                                                  100, // Adjust width as needed
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
                        )));
              },
            ),
          ),
        ],
      ),
    );
  }
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
      link: json['link'],
    );
  }
}
