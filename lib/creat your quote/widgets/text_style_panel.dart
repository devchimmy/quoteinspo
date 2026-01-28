import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class QuoteTextStyle {
  String text = "Your quote goes here";
  double fontSize = 28;
  Color color = Colors.white;
  FontWeight fontWeight = FontWeight.w600;
  String fontFamily = "Montserrat";
}

class TextStylePanel extends StatelessWidget {
  final QuoteTextStyle style;
  final double opacity;
  final Function(double) onOpacityChanged;
  final VoidCallback onStyleChanged;

  const TextStylePanel({
    super.key,
    required this.style,
    required this.opacity,
    required this.onOpacityChanged,
    required this.onStyleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          Slider(
            value: opacity,
            min: 0,
            max: 0.7,
            label: "Overlay",
            onChanged: onOpacityChanged,
          ),
          Slider(
            value: style.fontSize,
            min: 16,
            max: 60,
            label: "Text Size",
            onChanged: (v) {
              style.fontSize = v;
              onStyleChanged();
            },
          ),
          Row(
            children: [
              ElevatedButton(
                child: const Text("Text Color"),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      content: BlockPicker(
                        pickerColor: style.color,
                        onColorChanged: (c) {
                          style.color = c;
                          onStyleChanged();
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                child: const Text("Bold"),
                onPressed: () {
                  style.fontWeight = style.fontWeight ==
                          FontWeight.bold
                      ? FontWeight.w400
                      : FontWeight.bold;
                  onStyleChanged();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
