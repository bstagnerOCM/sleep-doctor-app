import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/explore_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/health_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sleep_doctor/main.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class BottomTabRouter extends StatefulWidget {
  const BottomTabRouter({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _BottomTabRouterState createState() => _BottomTabRouterState();
}

class _BottomTabRouterState extends State<BottomTabRouter> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Platform.isAndroid
            ? const Size.fromHeight(kToolbarHeight + 10)
            : const Size.fromHeight(kToolbarHeight),
        child: Container(
          padding: Platform.isAndroid
              ? const EdgeInsets.only(top: 30)
              : EdgeInsets.zero,
          child: AppBar(
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: InkWell(
              onTap: () {
                setState(() {
                  _currentIndex = 0;
                });
                _pageController.jumpToPage(0);
              },
              child: SvgPicture.asset(
                themeProvider.sdLogoAsset,
                height: 40,
              ),
            ),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: const [
          HomePage(),
          HealthPage(),
          ExplorePage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          _pageController.jumpToPage(index);
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.outline,
        type: BottomNavigationBarType.fixed, // Ensure the type is fixed
        showUnselectedLabels: true, // Ensure unselected labels are shown
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.health_and_safety), label: 'Health'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
