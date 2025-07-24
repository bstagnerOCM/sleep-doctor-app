import 'package:flutter/material.dart';
import '../../utils/remove_html.dart';
import '../../services/api_service.dart';
import 'package:flutter/foundation.dart';

class Commercial extends StatefulWidget {
  const Commercial({super.key});

  @override
  CommercialState createState() => CommercialState();
}

class CommercialState extends State<Commercial> {
  late Future<List<CommercialItem>> commercialItems;

  @override
  void initState() {
    super.initState();
    commercialItems = fetchCommercialItems();
  }

  Future<List<CommercialItem>> fetchCommercialItems() async {
    try {
      final data = await ApiService.instance.fetchCommercial(
        perPage: 10,
        offset: 0,
      );
      return data.map((json) => CommercialItem.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load commercial content: $e');
      }
      
      // Provide user-friendly error messages
      String errorMessage = 'Failed to load commercial content';
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

  Future<void> _refreshCommercialItems() async {
    setState(() {
      commercialItems = fetchCommercialItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commercial Content'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCommercialItems,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshCommercialItems,
        child: FutureBuilder<List<CommercialItem>>(
          future: commercialItems,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${snapshot.error}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshCommercialItems,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  CommercialItem item = snapshot.data![index];
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.imageUrl != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8.0),
                            ),
                            child: Image.network(
                              item.imageUrl!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              if (item.excerpt != null && item.excerpt!.isNotEmpty)
                                Text(
                                  item.excerpt!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.lastModifiedDate,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            } else {
              return const Center(
                child: Text('No commercial content available'),
              );
            }
          },
        ),
      ),
    );
  }
}

class CommercialItem {
  final String title;
  final String lastModifiedDate;
  final String? excerpt;
  final String? imageUrl;
  final String? link;

  CommercialItem({
    required this.title,
    required this.lastModifiedDate,
    this.excerpt,
    this.imageUrl,
    this.link,
  });

  factory CommercialItem.fromJson(Map<String, dynamic> json) {
    return CommercialItem(
      title: json['title']['rendered'] ?? 'No Title',
      lastModifiedDate: json['yoast_head_json']?['schema']?['@graph']?[0]
              ?['dateModified'] ??
          json['date'] ??
          'No Date',
      excerpt: stripHtml(json['excerpt']?['rendered'] ?? 'No Excerpt'),
      imageUrl: json['yoast_head_json']?['og_image']?[0]?['url'] ??
          json['featured_media_url'],
      link: json['link'],
    );
  }
}