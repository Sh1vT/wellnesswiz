import 'package:flutter/material.dart';
import 'package:wellwiz/utils/color_palette.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoOpacity;
  late Animation<double> _titleOpacity;
  late Animation<double> _subtitleOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
    _titleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.7, curve: Curves.easeIn),
      ),
    );
    _subtitleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: _logoOpacity.value,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.jpeg',
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Opacity(
                  opacity: _titleOpacity.value,
                  child: const Text(
                    'WellWiz',
                    style: TextStyle(
                      fontFamily: 'Mulish',
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: ColorPalette.green,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Opacity(
                  opacity: _subtitleOpacity.value,
                  child: const Text(
                    'Your all-in-one medical assistant',
                    style: TextStyle(
                      fontFamily: 'Mulish',
                      fontSize: 16,
                      color: Colors.black54,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
} 