import 'package:flutter/material.dart';
import 'package:quote_application/pages/onboarding_screen.dart';
import 'package:quote_application/splash_screen/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'filtered_quote_page.dart';
import 'quote_category_grid_page.dart';
import '../navigations component/mainscaffold.dart';

class LauncherPage extends StatefulWidget {
  const LauncherPage({super.key});

  @override
  State<LauncherPage> createState() => _LauncherPageState();
}

class _LauncherPageState extends State<LauncherPage> {
  @override
  void initState() {
    super.initState();
    _decideInitialScreen();
  }

  Future<void> _decideInitialScreen() async {
    final prefs = await SharedPreferences.getInstance();

    // ✅ Consistent key names
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    final setupCompleted = prefs.getBool('setupCompleted') ?? false;

    print("🧪 onboardingCompleted: $onboardingCompleted");
    print("🧪 setupCompleted: $setupCompleted");

    if (!onboardingCompleted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()), // ✅ make sure this is the right screen
      );
      return;
    }

    if (!setupCompleted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const QuoteCategoryGridPage()),
      );
      return;
    }

    // ✅ Go to MainScaffold with selected categories
    final selectedTitles = prefs.getStringList('selected_categories') ?? [];
    final allCategories = _getAllQuoteCategories();

    final selectedCategories = allCategories
        .where((category) => selectedTitles.contains(category['title']))
        .toList();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainScaffold(
          selectedCategories: selectedCategories,
          body: FilteredQuotePage(selectedCategories: selectedCategories),
        ),
      ),
    );
  }

  List<Map<String, String>> _getAllQuoteCategories() {
    return [
      {'title': 'Motivation', 'image': 'images/motivation.webp'},
      {'title': 'Love', 'image': 'images/love.webp'},
      {'title': 'Car Quotes', 'image': 'images/car.webp'},
      {'title': 'Life', 'image': 'images/life.webp'},
      {'title': 'Success', 'image': 'images/success.webp'},
      {'title': 'Wisdom', 'image': 'images/wisdom.webp'},
      {'title': 'Inspiration', 'image': 'images/inspiration.webp'},
      {'title': 'Friendship', 'image': 'images/friendship.webp'},
      {'title': 'Sad Quotes', 'image': 'images/sad.webp'},
      {'title': 'Happiness', 'image': 'images/happiness.webp'},
      {'title': 'Hustle', 'image': 'images/hustle.webp'},
      {'title': 'Heartbreak', 'image': 'images/heartbreak.webp'},
      {'title': 'Good Night', 'image': 'images/night.webp'},
      {'title': 'Relationship', 'image': 'images/relationship.webp'},
      {'title': 'Fitness', 'image': 'images/fitness.webp'},
      {'title': 'Birthday', 'image': 'images/birthday.webp'},
      {'title': 'Self-Love', 'image': 'images/selflove.webp'},
      {'title': 'Good Morning', 'image': 'images/morning.webp'},
      {'title': 'Spiritual', 'image': 'images/spiritual.webp'},
      {'title': 'Lifestyle', 'image': 'images/lifestyle.webp'},
      {'title': 'Confidence', 'image': 'images/confidence.webp'},
      {'title': 'Time', 'image': 'images/time.webp'},
      {'title': 'Pets', 'image': 'images/pets.webp'},
      {'title': 'Photography', 'image': 'images/photography.webp'},
      {'title': 'Funny', 'image': 'images/funny.webp'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SplashScreen()
    );
  }
}
