import 'package:flutter/material.dart';
import 'package:quote_application/daily_notification_scheduler.dart';
import 'package:quote_application/pages/daily_quotes_page.dart';
import 'package:quote_application/pages/life_lesson_list_page.dart';
import 'package:quote_application/services/notification_service.dart';
import 'package:quote_application/pages/show_quote_category_page.dart';
import 'package:quote_application/pages/random_quote_page.dart';
import 'package:quote_application/pages/wallpaper_categories_page.dart';

class AllQuotePage extends StatefulWidget {
  final List<Map<String, String>>? selectedCategories;

  const AllQuotePage({super.key, this.selectedCategories});

  @override
  State<AllQuotePage> createState() => _AllQuotePageState();
}

class _AllQuotePageState extends State<AllQuotePage> {
  final List<String> storyImages = [
    'images/motivation.webp',
    'images/love.webp',
    'images/car.webp',
    'images/life.webp',
    'images/success.webp',
    'images/wisdom.webp',
    'images/inspiration.webp',
    'images/friendship.webp',
    'images/sad.webp',
    'images/happiness.webp',
    'images/hustle.webp',
    'images/heartbreak.webp',
    'images/night.webp',
    'images/relationship.webp',
    'images/fitness.webp',
    'images/birthday.webp',
    'images/selflove.webp',
    'images/morning.webp',
    'images/spiritual.webp',
    'images/lifestyle.webp',
    'images/confidence.webp',
    'images/time.webp',
    'images/pets.webp',
    'images/funny.webp',
  ];

  final List<Map<String, String>> exploreItems = [
    {'title': 'Random Quotes', 'icon': 'images/random.webp'},
    {'title': 'Wallpapers', 'icon': 'images/wallpaper.webp'},
    {'title': 'Life Lessons', 'icon': 'images/articles.webp'},
    {'title': 'Daily Quotes', 'icon': 'images/book.webp'},
  ];

  final List<Map<String, String>> allQuoteCategories = [
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
    {'title': 'Funny', 'image': 'images/funny.webp'},
  ];

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> categoriesToShow =
        widget.selectedCategories ?? allQuoteCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Quotes"),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
           onPressed: () async {
  final action = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Notification Actions'),
      content: const Text('What would you like to do?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 'cancel'),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, 'schedule'),
          child: const Text('Schedule Notifications'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, 'test'),
          child: const Text('Test Notification'),
        ),
      ],
    ),
  );

  if (action == 'schedule') {
    
    await DailyNotificationsScheduler.scheduleAllDailyNotifications();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Daily notifications scheduled.")),
    );
  } else if (action == 'test') {
    await NotificationService.showNotification(
      id: 999,
      title: '🎉 Test Title',
      body: '✅ This is a test notification!',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("📩 Test notification sent.")),
    );
  }
}

          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Horizontal story scroll
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categoriesToShow.length,
                itemBuilder: (context, index) {
                  final category = categoriesToShow[index];
                  final categoryTitle = category['title']!;
                  final jsonFileName = '${categoryTitle.toLowerCase().replaceAll(' ', '_')}.json';

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QuoteCategoryPage(
                                  categoryTitle: categoryTitle,
                                  jsonFileName: jsonFileName,
                                ),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            radius: 35,
                            backgroundImage: AssetImage(category['image']!),
                          ),
                        ),
                        const SizedBox(height: 5),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Explore section
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text("Explore", style: Theme.of(context).textTheme.titleLarge),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: exploreItems.length,
                itemBuilder: (context, index) {
                  final item = exploreItems[index];
                  return InkWell(
                    onTap: () {
                      switch (item['title']) {
                        case 'Random Quotes':
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ExplorePage()));
                          break;
                        case 'Wallpapers':
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const WallpaperCategoriesPage()));
                          break;
                        case 'Life Lessons':
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const LifeLessonListPage()));
                          break;
                        case 'Daily Quotes':
                          Navigator.push(context, MaterialPageRoute(builder: (_) => DailyQuotePage()));
                          break;
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 60,
                            width: 60,
                            child: Image.asset(item['icon']!, fit: BoxFit.contain),
                          ),
                          const SizedBox(height: 8),
                          Text(item['title']!,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            

           
            // Grid of quote categories
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text("Quote Categories", style: Theme.of(context).textTheme.titleLarge),
            ),
            GridView.builder(
              padding: const EdgeInsets.all(12),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: categoriesToShow.length,
              itemBuilder: (context, index) {
                final category = categoriesToShow[index];
                final jsonFileName = '${category['title']!.toLowerCase().replaceAll(' ', '_')}.json';

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuoteCategoryPage(
                          categoryTitle: category['title']!,
                          jsonFileName: jsonFileName,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            category['image']!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(category['title']!,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
