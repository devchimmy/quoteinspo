import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quote_application/pages/wallpaper_categories_page.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

class ImageQuoteEditor extends StatefulWidget {
  const ImageQuoteEditor({super.key});

  @override
  State<ImageQuoteEditor> createState() => _ImageQuoteEditorState();
}

class _ImageQuoteEditorState extends State<ImageQuoteEditor> {
  File? backgroundFile;
  String? backgroundUrl;
  double overlayOpacity = 0.6; // Darker overlay

  String quoteText = "Your quote goes here";
  double fontSize = 28;
  FontWeight fontWeight = FontWeight.w600;
  Color textColor = Colors.white;

  final ScreenshotController controller = ScreenshotController();

  // Pick image from gallery
  Future<void> pickFromGallery() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() {
        backgroundFile = File(img.path);
        backgroundUrl = null;
      });
    }
  }

  // Pick wallpaper from categories
  Future<void> pickFromWallpapers() async {
    final selectedWallpaperUrl = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const WallpaperCategoriesPage(selectMode: true),
      ),
    );

    if (selectedWallpaperUrl != null) {
      setState(() {
        backgroundUrl = selectedWallpaperUrl;
        backgroundFile = null;
      });
    }
  }

  // Download quote image
  Future<void> downloadQuote() async {
    if (backgroundUrl != null && backgroundFile == null) {
      final response = await http.get(Uri.parse(backgroundUrl!));
      final dir = await getTemporaryDirectory();
      backgroundFile = File('${dir.path}/wallpaper.png');
      await backgroundFile!.writeAsBytes(response.bodyBytes);
    }

    final image = await controller.capture();
    if (image == null) return;

    final result = await ImageGallerySaver.saveImage(
      image,
      name: 'quote_${DateTime.now().millisecondsSinceEpoch}',
      quality: 100,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['isSuccess'] == true
            ? "✅ Saved to Gallery"
            : "❌ Failed to save"),
      ),
    );
  }

  // Share quote image
  Future<void> shareQuote() async {
    if (backgroundUrl != null && backgroundFile == null) {
      final response = await http.get(Uri.parse(backgroundUrl!));
      final dir = await getTemporaryDirectory();
      backgroundFile = File('${dir.path}/wallpaper.png');
      await backgroundFile!.writeAsBytes(response.bodyBytes);
    }

    final image = await controller.capture();
    if (image == null) return;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/quote.png');
    await file.writeAsBytes(image);

    await Share.shareXFiles([XFile(file.path)]);
  }

  // Open dialog to edit quote
  void openEditDialog() {
    TextEditingController editController =
        TextEditingController(text: quoteText);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Quote"),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: editController,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Type your quote here...",
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                quoteText = editController.text;
              });
              Navigator.pop(context);
            },
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasBackground = backgroundFile != null || backgroundUrl != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Image Quote Editor"),
        actions: [
          if (hasBackground)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: shareQuote,
            ),
        ],
      ),
      body: Column(
        children: [
          // Top buttons for color and bold
          if (hasBackground)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  ElevatedButton(
                    child: const Text("Color"),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          content: BlockPicker(
                            pickerColor: textColor,
                            onColorChanged: (c) => setState(() => textColor = c),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    child: const Text("Bold"),
                    onPressed: () {
                      setState(() {
                        fontWeight = fontWeight == FontWeight.bold
                            ? FontWeight.w400
                            : FontWeight.bold;
                      });
                    },
                  ),
                ],
              ),
            ),

          // Image / quote editor
          Expanded(
            child: Screenshot(
              controller: controller,
              child: Stack(
                children: [
                  // Background
                  Positioned.fill(
                    child: hasBackground
                        ? (backgroundFile != null
                            ? Image.file(backgroundFile!, fit: BoxFit.cover)
                            : Image.network(
                                backgroundUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(
                                      child: CircularProgressIndicator());
                                },
                                errorBuilder: (_, __, ___) =>
                                    Container(color: Colors.grey),
                              ))
                        : Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: pickFromGallery,
                                  child: const Text("Upload Image"),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: pickFromWallpapers,
                                  child: const Text("Choose from Wallpaper"),
                                ),
                              ],
                            ),
                          ),
                  ),

                  // Dark overlay
                  if (hasBackground)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(overlayOpacity),
                      ),
                    ),

                  // Centered quote text with padding/margin
                  if (hasBackground)
                    Center(
                      child: InkWell(
                        onTap: openEditDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 50),
                          child: Text(
                            quoteText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: fontWeight,
                              color: textColor,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Sliders
          if (hasBackground)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text("Overlay"),
                      Expanded(
                        child: Slider(
                          value: overlayOpacity,
                          min: 0,
                          max: 0.8,
                          onChanged: (v) => setState(() => overlayOpacity = v),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text("Text Size"),
                      Expanded(
                        child: Slider(
                          value: fontSize,
                          min: 16,
                          max: 60,
                          onChanged: (v) => setState(() => fontSize = v),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Download button
          if (hasBackground)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text("Download"),
                  onPressed: downloadQuote,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
