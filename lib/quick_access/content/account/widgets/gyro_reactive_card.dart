import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';

class GyroReactiveCard extends StatefulWidget {
  final Widget child;
  const GyroReactiveCard({required this.child, super.key});

  @override
  State<GyroReactiveCard> createState() => _GyroReactiveCardState();
}

class _GyroReactiveCardState extends State<GyroReactiveCard> with SingleTickerProviderStateMixin {
  double _currentX = 0.0, _currentY = 0.0;
  double? _neutralX, _neutralY;
  late final StreamSubscription _subscription;
  late final AnimationController _controller;
  late Animation<double> _xAnim, _yAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _xAnim = AlwaysStoppedAnimation(_currentX);
    _yAnim = AlwaysStoppedAnimation(_currentY);

    _subscription = accelerometerEvents.listen((AccelerometerEvent event) {
      _neutralX ??= event.x;
      _neutralY ??= event.y;
      final relX = event.x - _neutralX!;
      final relY = event.y - _neutralY!;
      final newX = (relY / 9.8).clamp(-1.0, 1.0) * 0.5;
      final newY = (-relX / 9.8).clamp(-1.0, 1.0) * 0.5;

      _xAnim = Tween<double>(begin: _currentX, end: newX).animate(_controller);
      _yAnim = Tween<double>(begin: _currentY, end: newY).animate(_controller);

      _controller.reset();
      _controller.forward();
    });

    _controller.addListener(() {
      setState(() {
        _currentX = _xAnim.value;
        _currentY = _yAnim.value;
      });
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(_currentX)
                ..rotateY(_currentY),
              child: widget.child,
            ),
          ],
        );
      },
    );
  }
}

class _ShinePainter extends CustomPainter {
  final double x;
  final double y;
  _ShinePainter({required this.x, required this.y});

  @override
  void paint(Canvas canvas, Size size) {
    // Map tilt to shine position (diagonal movement)
    final double shineWidth = size.shortestSide * 0.22;
    // Shine offset: -0.5 to 0.5 mapped to 0 to 1
    final double offset = ((x + y) / 1.0).clamp(-1.0, 1.0) * 0.35 + 0.5;
    // Diagonal start/end
    final start = Offset(size.width * (offset - 0.2), size.height * (offset - 0.2));
    final end = Offset(size.width * (offset + 0.2), size.height * (offset + 0.2));
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.10),
          Colors.grey.withOpacity(0.18),
          Colors.white.withOpacity(0.10),
          Colors.transparent,
        ],
        stops: [0.0, 0.40, 0.5, 0.60, 1.0],
        // The shine band is centered at 'offset'
        transform: GradientRotation(pi / 4),
      ).createShader(Rect.fromPoints(start, end));
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _ShinePainter oldDelegate) {
    return oldDelegate.x != x || oldDelegate.y != y;
  }
} 