import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:quote_application/navigations%20component/mainscaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'filtered_quote_page.dart';

class QuoteCategoryGridPage extends StatefulWidget {
  final List<Map<String, String>>? existingSelectedCategories;

  const QuoteCategoryGridPage({super.key, this.existingSelectedCategories});

  @override
  QuoteCategoryGridPageState createState() => QuoteCategoryGridPageState();
}

class QuoteCategoryGridPageState extends State<QuoteCategoryGridPage> {
  final List<Map<String, String>> quoteCategories = [
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

  late List<String> selectedCategories;

  final Color customBackgroundColor = Colors.white;

  @override
  void initState() {
    super.initState();
    selectedCategories = widget.existingSelectedCategories
            ?.map((e) => e['title'] ?? '')
            .where((title) => title.isNotEmpty)
            .toList() ??
        [];
  }

  void toggleCategory(String title) {
    setState(() {
      if (selectedCategories.contains(title)) {
        selectedCategories.remove(title);
      } else {
        selectedCategories.add(title);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Center(child: Text('Select Quote Categories')),
        backgroundColor: customBackgroundColor,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: GridView.builder(
                itemCount: quoteCategories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 3 / 2,
                ),
                itemBuilder: (context, index) {
                  final category = quoteCategories[index];
                  final isSelected = selectedCategories.contains(category['title']);

                  return GestureDetector(
                    onTap: () => toggleCategory(category['title']!),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(category['image']!),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) {
                                if (kDebugMode) {
                                  print('Image load failed for ${category['image']}');
                                  print('Error: $exception');
                                }
                              },
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.black.withOpacity(isDark ? 0.7 : 0.8)
                                : Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(
                                    color: Theme.of(context).colorScheme.secondary,
                                    width: 2,
                                  )
                                : null,
                          ),
                        ),
                        Center(
                          child: Text(
                            category['title']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 65),
            child: ElevatedButton(
              
              onPressed: selectedCategories.isNotEmpty
                  ? () async {
                      final prefs = await SharedPreferences.getInstance();

                      await prefs.setStringList('selected_categories', selectedCategories);
                      await prefs.setBool('setupCompleted', true);
                      print('✅ setupCompleted set to TRUE');

                      final selectedCategoryMaps = quoteCategories
                          .where((category) => selectedCategories.contains(category['title']))
                          .toList();

                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MainScaffold(
                              selectedCategories: selectedCategoryMaps,
                              body: FilteredQuotePage(selectedCategories: selectedCategoryMaps),
                            ),
                          ),
                        );
                      }
                    }
                  : null,
                  
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: selectedCategories.isNotEmpty
                    ? customBackgroundColor
                    : Colors.grey,
                foregroundColor: Colors.black,
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
