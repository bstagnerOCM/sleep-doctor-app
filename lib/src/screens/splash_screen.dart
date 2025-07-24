import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:sleep_doctor/main.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      // Set your background color
      color: Theme.of(context).colorScheme.onPrimary,
      child: Center(
        child:
            // Your logo or image
            SvgPicture.asset(themeProvider.sdLogoAsset, height: 80),
      ),
    );
  }
}
