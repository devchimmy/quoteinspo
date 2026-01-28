import 'package:flutter/material.dart';
import 'image_quote_editor.dart';

class CreateQuoteTypePage extends StatelessWidget {
  const CreateQuoteTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Your Quote")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _optionCard(
              context,
              title: "Image Quote",
              icon: Icons.image,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ImageQuoteEditor(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionCard(BuildContext context,
      {required String title,
      required IconData icon,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black.withOpacity(0.05),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 40),
            const SizedBox(width: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
