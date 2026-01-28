import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class LifeLessonDetailWrapper extends StatelessWidget {
  const LifeLessonDetailWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args == null || !args.containsKey('lesson')) {
      return const Scaffold(
        body: Center(child: Text("No lesson data found.")),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (args['backgroundImage'] != null)
            Image.asset(args['backgroundImage'], fit: BoxFit.cover)
          else
            Container(color: Colors.black),
          Container(color: Colors.black.withOpacity(0.6)),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  args['lesson'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, color: Colors.white),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: args['lesson']));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lesson copied!')),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: () {
                        Share.share(args['lesson']);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.favorite_border, color: Colors.white),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to favorites!')),
                        );
                      },
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
