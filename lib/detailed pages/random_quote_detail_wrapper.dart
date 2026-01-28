import 'package:flutter/material.dart';
import 'package:quote_application/detailed%20pages/random_quotes_detail_page.dart';


class RandomQuoteDetailWrapper extends StatelessWidget {
  const RandomQuoteDetailWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args == null || !args.containsKey('quote')) {
      return const Scaffold(
        body: Center(child: Text("No quote data found.")),
      );
    }

    return RandomQuoteDetailPage(
      quote: args['quote'],
      category: args['category'],
      backgroundImage: args['backgroundImage'] ?? 'images/default.png',
    );
  }
}
