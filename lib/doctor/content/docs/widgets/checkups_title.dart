import 'package:flutter/material.dart';
import 'package:wellwiz/utils/color_palette.dart';

class HaveALookTitle extends StatelessWidget {
  const HaveALookTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Have",
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontFamily: 'Mulish',
                fontSize: 40,
                color: Color.fromARGB(255, 106, 172, 67)),
          ),
          Text(
            "a look",
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontFamily: 'Mulish',
                fontSize: 40,
                color: ColorPalette.black),
          ),
        ],
      ),
    );
  }
} 