import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'wallpaper_grid_page.dart';

const List<String> wallpaperCategories = [
  'Cars','Nature','Abstract','Minimalist','Technology','Neon',
  '3D Art','mountain','skyscrapers','Night Cities','Pets','Fitness',
  'Anime','birds','artistic','Phone wallpaper','cartoons','superheros',
];

class WallpaperCategoriesPage extends StatefulWidget {
  final bool selectMode; // ✅ Add this parameter

  const WallpaperCategoriesPage({super.key, this.selectMode = false}); // ✅ default false

  @override
  State<WallpaperCategoriesPage> createState() => _WallpaperCategoriesPageState();
}

class _WallpaperCategoriesPageState extends State<WallpaperCategoriesPage> {
  Map<String, List<String>> categoryImages = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    final jsonString =
        await rootBundle.loadString('assets/json/wallpaper_backgrounds.json');
    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;

    final filteredMap = jsonMap.map(
      (key, value) => MapEntry(key, List<String>.from(value)),
    )..removeWhere((key, _) => !wallpaperCategories.contains(key));

    setState(() {
      categoryImages = filteredMap;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wallpaper Categories")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: categoryImages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.2,
              ),
              itemBuilder: (context, index) {
                final category = categoryImages.keys.elementAt(index);
                return GestureDetector(
                  onTap: () async {
                    final selected = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WallpaperGridPage(
                          category: category,
                          images: categoryImages[category]!,
                          selectMode: widget.selectMode, // ✅ pass it
                        ),
                      ),
                    );

                    if (widget.selectMode && selected != null) {
                      Navigator.pop(context, selected);
                    }
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        categoryImages[category]!.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: Colors.grey[300]),
                      ),
                      Container(color: Colors.black.withOpacity(0.4)),
                      Center(
                        child: Text(
                          category,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
