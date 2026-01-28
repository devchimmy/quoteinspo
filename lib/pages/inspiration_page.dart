import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
// import 'package:share_plus/share_plus.dart';
import '../models/quote.dart';
import 'dart:convert';

class InspirationPage extends StatefulWidget {
  const InspirationPage({super.key});

  @override
  InspirationPageState createState() => InspirationPageState();
}

class InspirationPageState extends State<InspirationPage> {
  List<Quote> quotes = [];

  @override
  void initState() {
    super.initState();
    loadQuotes();
  }

  Future<void> loadQuotes() async {
    final String response = await rootBundle.loadString('assets/data/inspirational_quotes.json');
    final List<dynamic> data = json.decode(response);
    setState(() {
      quotes = data.map((e) => Quote.fromJson(e)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Inspiration")),
      body: quotes.isEmpty
          ? Center(child: CircularProgressIndicator())
          : CarouselSlider.builder(
              itemCount: quotes.length,
              options: CarouselOptions(
                height: 500,
                enlargeCenterPage: true,
                autoPlay: false,
                viewportFraction: 0.9,
              ),
              itemBuilder: (context, index, _) {
                final quote = quotes[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 4,
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              quote.quote,
                              style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: Icon(Icons.copy),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: quote.quote));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Copied")),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.share),
                              onPressed: (){}
                              // () => 
                              // Share.share(quote.quote),
                            ),
                            IconButton(
                              icon: Icon(Icons.bookmark),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Saved (placeholder)")),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                quote.isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: quote.isFavorite ? Colors.red : null,
                              ),
                              onPressed: () {
                                setState(() {
                                  quote.isFavorite = !quote.isFavorite;
                                });
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
