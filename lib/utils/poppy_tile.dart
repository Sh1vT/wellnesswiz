import 'package:flutter/material.dart';

/// A reusable, poppy tile with shadow, rounded corners, and tap scale animation.
/// Place any widget as [child].
class PoppyTile extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final double borderRadius;
  final BorderRadius? customBorderRadius;
  final List<BoxShadow>? boxShadow;

  const PoppyTile({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
    this.backgroundColor = Colors.white,
    this.borderRadius = 20,
    this.customBorderRadius,
    this.boxShadow,
  });

  @override
  State<PoppyTile> createState() => _PoppyTileState();
}

class _PoppyTileState extends State<PoppyTile> with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _controller.addListener(() {
      setState(() {
        _scale = _controller.value;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) _controller.reverse();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.forward();
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      child: Transform.scale(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: widget.customBorderRadius ?? BorderRadius.circular(widget.borderRadius),
            boxShadow: widget.boxShadow ?? [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );
  }
} 