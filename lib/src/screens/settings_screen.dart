import 'package:flutter/material.dart';
import '../features/settings/settings.dart';

import './flyout_screen.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FlyoutPage(
      title: "Settings",
      body: Settings(), // Replace with your settings widget
    );
  }
}
