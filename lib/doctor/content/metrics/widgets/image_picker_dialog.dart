import 'package:flutter/material.dart';
import 'package:wellwiz/utils/color_palette.dart';

class ImagePickerDialog extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const ImagePickerDialog({
    super.key,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text(
        "Upload a snap",
        style: TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.bold, color: ColorPalette.blackDarker),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onCamera,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.camera_alt, color: ColorPalette.green, size: 26),
                      const SizedBox(width: 14),
                      const Text(
                        "Take a photo",
                        style: TextStyle(fontFamily: 'Mulish', fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onGallery,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.photo, color: ColorPalette.green, size: 26),
                      const SizedBox(width: 14),
                      const Text(
                        "Choose from Gallery",
                        style: TextStyle(fontFamily: 'Mulish', fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 