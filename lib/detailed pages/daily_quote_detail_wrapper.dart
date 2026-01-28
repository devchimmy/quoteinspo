import 'package:flutter/material.dart';
import 'package:quote_application/detailed%20pages/daily_quote_detail_page.dart';

class DailyQuoteDetailWrapper extends StatelessWidget {
  const DailyQuoteDetailWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

    return DailyQuoteDetailPage(
      date: args['date'],
      quote: args['quote'],
      backgroundImage: args['backgroundImage'],
    );
  }
}
