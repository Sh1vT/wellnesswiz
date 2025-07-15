import 'package:flutter/material.dart';

class SignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String buttontext;
  final ImageProvider<Object> iconImage;
  const SignInButton(
      {super.key,
      required this.onPressed,
      required this.buttontext,
      required this.iconImage});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(width: 2, color: Colors.grey.shade700,)
        ),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundImage: iconImage,
                radius: 10,
                backgroundColor: Colors.transparent,
              ),
              const SizedBox(width: 10),
              Text(
                buttontext,
                style: TextStyle(
                    fontFamily: "Mulish",
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
