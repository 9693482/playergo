import 'package:flutter/material.dart';

/// Número animado con efecto count-up desde 0 hasta [value].
/// Respeta `animate = false` (mostrado directamente) para
/// `prefers-reduced-motion`.
class CountUpText extends StatefulWidget {
  final int value;
  final Duration duration;
  final TextStyle? style;
  final bool animate;

  const CountUpText({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 1200),
    this.style,
    this.animate = true,
  });

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.animate) {
      _controller.forward(from: 0);
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final v = (_controller.value * widget.value).round();
        return Text('$v', style: widget.style, textAlign: TextAlign.center);
      },
    );
  }
}
