import 'package:flutter/material.dart';

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
                color: const Color.fromRGBO(97, 97, 97, 1)),
          ),
        ],
      ),
    );
  }
} 