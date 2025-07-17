import 'package:flutter/material.dart';

class ColorPalette {
  static const Color green = Color.fromARGB(255, 106, 172, 67);

  static const MaterialColor greenSwatch = MaterialColor(
    0xFF6AAC43, // Primary value
    <int, Color>{
      50: Color.fromARGB(255, 232, 245, 224),
      100: Color.fromARGB(255, 200, 230, 201),
      200: Color.fromARGB(255, 165, 214, 167),
      300: Color.fromARGB(255, 129, 199, 132),
      400: Color.fromARGB(255, 106, 172, 67), // Main
      500: Color.fromARGB(255, 106, 172, 67), // Main
      600: Color.fromARGB(255, 85, 139, 47),
      700: Color.fromARGB(255, 51, 105, 30),
      800: Color.fromARGB(255, 27, 94, 32),
      900: Color.fromARGB(255, 0, 51, 0),
    },
  );

  static const Color black = Color.fromRGBO(97, 97, 97, 1);
  static const Color blackDarker = Color.fromRGBO(66, 66, 66, 1);
} 