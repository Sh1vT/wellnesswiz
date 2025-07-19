import 'package:flutter/material.dart';

class SignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String buttontext;
  final ImageProvider<Object>? iconImage;
  final bool loading;
  const SignInButton({
    super.key,
    this.onPressed,
    required this.buttontext,
    this.iconImage,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(width: 2, color: Colors.grey.shade700,)
        ),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading) ...[
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6AAC43)),
                  ),
                ),
                const SizedBox(width: 10),
              ] else if (iconImage != null) ...[
                CircleAvatar(
                  backgroundImage: iconImage,
                  radius: 10,
                  backgroundColor: Colors.transparent,
                ),
                const SizedBox(width: 10),
              ],
              Text(
                buttontext,
                style: TextStyle(
                    fontFamily: 'Mulish',
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
