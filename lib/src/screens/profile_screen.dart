import 'package:flutter/material.dart';
import '../features/profile/profile.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0),
        child: Profile(),
      ),
    );
  }
}
