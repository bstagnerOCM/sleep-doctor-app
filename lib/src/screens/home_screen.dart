import 'package:flutter/material.dart';
import '../features/articles/article_section.dart';
import 'package:provider/provider.dart';
import 'package:sleep_doctor/main.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  // int _activeButton = 0;
  String dropdownValue = 'Sleepfoundation';
  // Unique key for each ArticleSection to force rebuild
  var _latestSFKey = GlobalKey();
  var _latestKey = GlobalKey();
  var _teensKey = GlobalKey();
  var _snoringKey = GlobalKey();

  Future<void> _refreshArticles() async {
    setState(() {
      // Create new keys to force the rebuild of ArticleSections
      _latestSFKey = GlobalKey();
      _latestKey = GlobalKey();
      _teensKey = GlobalKey();
      _snoringKey = GlobalKey();
    });
  }

  bool isDarkMode(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return themeProvider.themeMode == ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    List<Map<String, String>> dropdownItems = [
      {
        'label': 'Sleepfoundation',
        'iconPath': themeProvider.sfIconAsset,
        'iconPathActive': themeProvider.sfIconAsset
      },
      {
        'label': 'Sleep Doctor',
        'iconPath': themeProvider.sdIconAsset,
        'iconPathActive': 'assets/icons/sd-icon-dark.svg'
      },
    ];
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshArticles,
        child: ListView(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Articles from',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  DropdownButton<String>(
                    value: dropdownValue,
                    onChanged: (String? newValue) {
                      setState(() {
                        dropdownValue = newValue!;
                      });
                    },
                    items: dropdownItems.map<DropdownMenuItem<String>>((item) {
                      return DropdownMenuItem<String>(
                        value: item['label'],
                        child: Row(
                          children: [
                            SvgPicture.asset(item['iconPath']!,
                                width: 24, height: 24),
                            const SizedBox(width: 8),
                            Text(item['label']!,
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Visibility(
                visible: dropdownValue == 'Sleepfoundation',
                child: Column(children: [
                  ArticleSection(
                      key: _latestSFKey,
                      url:
                          'https://sleepfoundationv2.local/wp-json/wp/v2/article?orderby=last_modifed_date&per_page=4&offset=0',
                      title: 'Latest',
                      domain: 'sf'),
                  ArticleSection(
                      key: _teensKey,
                      url:
                          'https://sleepfoundationv2.local/wp-json/wp/v2/article?orderby=last_modifed_date&category=teens-category&per_page=4&offset=0',
                      title: 'Teens & Sleep',
                      domain: 'sf'),
                  ArticleSection(
                      key: _snoringKey,
                      url:
                          'https://sleepfoundationv2.local/wp-json/wp/v2/article?orderby=last_modifed_date&category=snoring-category&per_page=4&offset=0',
                      title: 'Snoring',
                      domain: 'sf'),
                ])),
            Visibility(
                visible: dropdownValue == 'Sleep Doctor',
                child: Column(children: [
                  ArticleSection(
                      key: _latestKey,
                      url:
                          'https://tsdv2.local/wp-json/wp/v2/article?orderby=last_modifed_date&per_page=4&offset=0',
                      title: 'Latest',
                      domain: 'sd'),
                  ArticleSection(
                      key: _teensKey,
                      url:
                          'https://tsdv2.local/wp-json/wp/v2/article?orderby=last_modifed_date&category=teens-category&per_page=4&offset=0',
                      title: 'Teens & Sleep',
                      domain: 'sf'),
                  ArticleSection(
                      key: _snoringKey,
                      url:
                          'https://tsdv2.local/wp-json/wp/v2/article?orderby=last_modifed_date&category=snoring-category&per_page=4&offset=0',
                      title: 'Snoring',
                      domain: 'sf'),
                ])),
          ],
        ),
      ),
    );
  }

  // Widget _buildButton(
  //     int index, String iconInactive, String iconActive, String text) {
  //   bool isActive = index == _activeButton;
  //   return ElevatedButton(
  //     onPressed: () {
  //       setState(() {
  //         _activeButton = index;
  //       });
  //     },
  //     style: ElevatedButton.styleFrom(
  //       backgroundColor:
  //           isActive ? Theme.of(context).colorScheme.secondary : null,
  //       elevation: isActive ? 1 : 0,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(20),
  //       ),
  //     ),
  //     child: Row(
  //       children: [
  //         SvgPicture.asset(
  //             isDarkMode(context) && isActive
  //                 ? iconInactive
  //                 : isDarkMode(context) && !isActive
  //                     ? iconActive
  //                     : isActive
  //                         ? iconActive
  //                         : iconInactive,
  //             height: 24),
  //         const SizedBox(width: 8),
  //         Text(
  //           text,
  //           style: Theme.of(context).textTheme.bodySmall?.copyWith(
  //                 color:
  //                     isActive ? Theme.of(context).colorScheme.onPrimary : null,
  //               ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
