import 'package:flutter/material.dart';
import 'package:wellwiz/utils/color_palette.dart';

class ConnectingDialog extends StatelessWidget {
  final String message;
  const ConnectingDialog({Key? key, this.message = 'Connecting to services...'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorPalette.green,
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 5,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Mulish'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 