import 'package:flutter/material.dart';
import 'package:quote_application/creat%20your%20quote/create_quote_type_page.dart';
import 'package:quote_application/daily_notification_scheduler.dart';
import 'package:quote_application/widgets/daily_quote_card.dart';
import 'package:quote_application/pages/daily_quotes_page.dart';
import 'package:quote_application/pages/life_lesson_list_page.dart';
import 'package:quote_application/pages/show_quote_category_page.dart';
import 'package:quote_application/pages/random_quote_page.dart';
import 'package:quote_application/pages/wallpaper_categories_page.dart';
import 'quote_category_grid_page.dart';

class FilteredQuotePage extends StatefulWidget {
  final List<Map<String, String>> selectedCategories;

  const FilteredQuotePage({super.key, required this.selectedCategories});

  @override
  State<FilteredQuotePage> createState() => _FilteredQuotePageState();
}

class _FilteredQuotePageState extends State<FilteredQuotePage> {
  late List<Map<String, String>> selectedCategories;

  @override
  void initState() {
    super.initState();
    selectedCategories = widget.selectedCategories;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () async {
              await DailyNotificationsScheduler.scheduleAllDailyNotifications();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("✅ Daily notifications scheduled.")),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Horizontal Category Chips
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: selectedCategories.length,
                itemBuilder: (context, index) {
                  final category = selectedCategories[index];
                  final categoryTitle = category['title']!;
                  final jsonFileName =
                      '${categoryTitle.toLowerCase().replaceAll(' ', '_')}.json';

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
            const SizedBox(height: 4),

            // Daily Quote Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: DailyQuoteCard(),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Explore",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.add,color: Colors.redAccent,),
                    label: const Text("Create Your Own Quote",style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateQuoteTypePage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // =========================
            //    RESPONSIVE EXPLORE
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = MediaQuery.of(context).size;
                  final shortest = size.shortestSide;
                  final isPortrait =
                      MediaQuery.of(context).orientation == Orientation.portrait;

                  final double containerHeight = isPortrait
                      ? shortest * 0.40
                      : shortest * 0.70;

                  // 🔥 NEW ICON SIZE — MUCH SMALLER
                  final double iconSize = (shortest * 0.15).clamp(40, 90);

                  return SizedBox(
                    width: double.infinity,
                    height: containerHeight.clamp(120, 350),
                    child: isPortrait
                        ? ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildExploreItem(context, "Random Quotes",
                                  "images/random.webp", const ExplorePage(), iconSize),
                              _buildExploreItem(context, "Wallpapers",
                                  "images/wallpaper.webp", const WallpaperCategoriesPage(), iconSize),
                              _buildExploreItem(context, "Life Lessons",
                                  "images/articles.webp", const LifeLessonListPage(), iconSize),
                              _buildExploreItem(context, "Daily Quotes",
                                  "images/book.webp", DailyQuotePage(), iconSize),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildExploreItem(context, "Random Quotes",
                                  "images/random.webp", const ExplorePage(), iconSize),
                              _buildExploreItem(context, "Wallpapers",
                                  "images/wallpaper.webp", const WallpaperCategoriesPage(), iconSize),
                              _buildExploreItem(context, "Life Lessons",
                                  "images/articles.webp", const LifeLessonListPage(), iconSize),
                              _buildExploreItem(context, "Daily Quotes",
                                  "images/book.webp", DailyQuotePage(), iconSize),
                            ],
                          ),
                  );
                },
              ),
            ),



            // Quote Categories Header + Button
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Quote Categories",
                      style: Theme.of(context).textTheme.titleLarge),
                  TextButton.icon(
                    onPressed: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuoteCategoryGridPage(
                            existingSelectedCategories: selectedCategories,
                          ),
                        ),
                      );

                      if (updated != null &&
                          updated is List<Map<String, String>>) {
                        setState(() {
                          for (var newCategory in updated) {
                            bool exists = selectedCategories.any(
                              (cat) => cat['title'] == newCategory['title'],
                            );
                            if (!exists) {
                              selectedCategories.add(newCategory);
                            }
                          }
                        });
                      }
                    },
                    icon: const Icon(Icons.arrow_right, size: 18),
                    label: const Text("Select More"),
                  ),
                ],
              ),
            ),

            // Grid of selected categories
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
              itemCount: selectedCategories.length,
              itemBuilder: (context, index) {
                final category = selectedCategories[index];
                final categoryTitle = category['title']!;
                final jsonFileName =
                    '${categoryTitle.toLowerCase().replaceAll(' ', '_')}.json';

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuoteCategoryPage(
                          categoryTitle: categoryTitle,
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
                      Text(
                        categoryTitle,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
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

  // ==============================
  //   Responsive Explore Builder
  // ==============================
  Widget _buildExploreItem(
    BuildContext context,
    String title,
    String icon,
    Widget page,
    double iconSize,
  ) {
    return InkWell(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: iconSize,
              width: iconSize,
              child: Image.asset(icon),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
