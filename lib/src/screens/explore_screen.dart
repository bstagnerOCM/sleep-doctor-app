import 'package:flutter/material.dart';
import '../features/articles/categories.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Categories(),
    );
  }
}
