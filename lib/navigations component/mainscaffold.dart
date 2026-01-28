import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/services.dart'; // <-- For SystemNavigator.pop()
import 'package:quote_application/pages/favorite_quotes_page.dart';
import 'package:quote_application/pages/all_quote_page.dart';
import 'package:quote_application/navigations%20component/settings_page.dart';

class MainScaffold extends StatefulWidget {
  final Widget? body;
  final int currentIndex;
  final List<Map<String, String>>? selectedCategories;

  const MainScaffold({
    super.key,
    this.body,
    this.currentIndex = 0,
    this.selectedCategories,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;
  late List<Map<String, String>> _selectedCategories;
  bool _showExitBar = false;
  DateTime? _lastPressed;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _selectedCategories =
        widget.selectedCategories ?? _getAllCategories(); // fallback
  }

  List<Map<String, String>> _getAllCategories() {
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

  Future<bool> _onWillPop() async {
    final now = DateTime.now();

    if (!_showExitBar ||
        _lastPressed == null ||
        now.difference(_lastPressed!) > const Duration(seconds: 3)) {
      setState(() {
        _showExitBar = true;
        _lastPressed = now;
      });

      // Hide automatically after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showExitBar = false;
          });
        }
      });

      return false; // don't exit yet
    }

    return false; // user must tap Exit
  }

  void _exitApp() {
    SystemNavigator.pop(); // properly closes the app
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      widget.body ?? AllQuotePage(selectedCategories: _selectedCategories),
      const FavoriteQuotesPage(),
      const SettingsPage(),
    ];

    final Widget content =
        (widget.body != null && _currentIndex == widget.currentIndex)
            ? widget.body!
            : pages[_currentIndex];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Stack(
        children: [
          Scaffold(
            body: content,
            bottomNavigationBar: SafeArea(
              top: false,
              child: CurvedNavigationBar(
                backgroundColor: Colors.transparent,
                color: Colors.white,
                buttonBackgroundColor: Colors.grey.shade100,
                animationDuration: const Duration(milliseconds: 300),
                index: _currentIndex,
                items: const [
                  Icon(Icons.home, size: 30, color: Colors.black),
                  Icon(Icons.favorite, size: 30, color: Colors.black),
                  Icon(Icons.settings, size: 30, color: Colors.black),
                ],
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            ),
          ),

          //Exit bar (appears above bottom navigation bar) 
          if (_showExitBar)
            Positioned(
              left: 0,
              right: 0,
              bottom: 70, // just above the curved bottom bar
              child: AnimatedOpacity(
                opacity: _showExitBar ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: GestureDetector(
                  onTap: _exitApp,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Tap here to exit",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            decoration: TextDecoration.none, // no underline
                          ),
                        ),
                        SizedBox(width: 10,),
                        Icon(Icons.cancel_rounded,color: Colors.red,)
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
