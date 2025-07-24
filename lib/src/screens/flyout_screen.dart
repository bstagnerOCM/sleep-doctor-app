import 'package:flutter/material.dart';

class FlyoutPage extends StatelessWidget {
  final String title;
  final Widget body;
  final VoidCallback? onBack;

  const FlyoutPage({
    super.key,
    required this.title,
    required this.body,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack ?? () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0),
        child: body,
      ),
    );
  }
}
