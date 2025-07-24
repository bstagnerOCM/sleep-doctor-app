import 'package:flutter/material.dart';
import '../features/health/health.dart';

class HealthPage extends StatelessWidget {
  const HealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0),
        child: HealthApp(),
      ),
    );
  }
}
