import 'package:flutter/material.dart';

class DailyPositivityButton extends StatelessWidget {
  final VoidCallback onTap;
  const DailyPositivityButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
        child: Container(
          padding: EdgeInsets.all(20),
          height: 80,
          decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.all(Radius.circular(12))),
          child: Center(
            child: Row(
              children: [
                Icon(
                  Icons.health_and_safety_outlined,
                  size: 40,
                  color: Colors.grey.shade700,
                ),
                SizedBox(width: 20),
                Row(
                  children: [
                    Text(
                      'Daily ',
                      style: TextStyle(
                          color: Color.fromARGB(255, 106, 172, 67),
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                    Text('Positivity',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                            fontSize: 18)),
                  ],
                ),
                Spacer(),
                Icon(
                  Icons.navigate_next_rounded,
                  color: Colors.grey.shade700,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 