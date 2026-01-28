import 'package:flutter/material.dart';

class RateOurAppPage extends StatelessWidget {
  const RateOurAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Our App')),
      body: const Center(
        child: Text(
          'Coming Soon!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
