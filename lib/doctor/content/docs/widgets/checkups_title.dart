import 'package:flutter/material.dart';
import 'package:wellwiz/utils/color_palette.dart';

class CheckupsTitle extends StatelessWidget {
  const CheckupsTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Check-",
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontFamily: 'Mulish',
                fontSize: 40,
                color: Color.fromARGB(255, 106, 172, 67)),
          ),
          Text(
            "Ups",
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