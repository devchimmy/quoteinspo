import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

class RandomQuote {
  static final Random _random = Random();

  static const Map<String, String> quoteCategories = {
    'Motivation': 'motivation.json',
    'Love': 'love.json',
    'Car Quotes': 'car_quotes.json',
    'Life': 'life.json',
    'Success': 'success.json',
    'Wisdom': 'wisdom.json',
    'Inspiration': 'inspiration.json',
    'Friendship': 'friendship.json',
    'Sad Quotes': 'sad_quotes.json',
    'Happiness': 'happiness.json',
    'Hustle': 'hustle.json',
    'Heartbreak': 'heartbreak.json',
    'Relationship': 'relationship.json',
    'Fitness': 'fitness.json',
    'Self-Love': 'self-love.json',
    'Spiritual': 'spiritual.json',
    'Lifestyle': 'lifestyle.json',
    'Confidence': 'confidence.json',
    'Time': 'time.json',
    'Pets': 'pets.json',
    'Photography': 'photography.json',
    'Funny': 'funny.json',
  };

  static Future<Map<String, dynamic>> getRandomQuoteAndImage() async {
    final categoryList = quoteCategories.keys.toList();
    final String selectedCategory = categoryList[_random.nextInt(categoryList.length)];
    final String jsonFile = quoteCategories[selectedCategory]!;

    final quoteJson = await rootBundle.loadString('assets/json/$jsonFile');
    final List quotesList = json.decode(quoteJson);
    final Map<String, dynamic> randomQuoteEntry = quotesList[_random.nextInt(quotesList.length)];
    final String quote = randomQuoteEntry['quote'];
    final int quoteIndex = quotesList.indexOf(randomQuoteEntry);

    final imageJson = await rootBundle.loadString('assets/json/quote_backgrounds.json');
    final Map<String, dynamic> imageData = json.decode(imageJson);
    final List<String> images = List<String>.from(imageData[selectedCategory] ?? []);
    final String backgroundImage = images.isNotEmpty
        ? images[_random.nextInt(images.length)]
        : 'images/default.png';

    return {
      'id': quoteIndex.toString(),
      'category': selectedCategory,
      'quote': quote,
      'backgroundImage': backgroundImage,
    };
  }
}
