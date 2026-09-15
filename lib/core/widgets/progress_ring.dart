import 'package:flutter/material.dart';

/// Anillo de progreso animado dibujado con [CustomPaint].
///
/// El [progress] (0..1) puede representar un valor real o ser puramente
/// decorativo. Muestra: track oscuro, glow sutil y segmento activo con
/// extremos redondeados.
class ProgressRing extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final double progress;
  final Color color;
  final Widget? center;
  final Duration duration;
  final bool animate;

  const ProgressRing({
    super.key,
    this.size = 120,
    this.strokeWidth = 10,
    required this.progress,
    required this.color,
    this.center,
    this.duration = const Duration(milliseconds: 1100),
    this.animate = true,
  });

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
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
        final p = _controller.value * widget.progress;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  progress: p,
                  color: widget.color,
                  strokeWidth: widget.strokeWidth,
                ),
              ),
              if (widget.center != null) widget.center!,
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const tau = 2 * 3.141592653589793;
    const startAngle = -90 * 3.141592653589793 / 180;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = color.withAlpha(28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final glowPaint = Paint()
      ..color = color.withAlpha(45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      progress * tau,
      false,
      glowPaint,
    );

    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      progress * tau,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color || old.strokeWidth != strokeWidth;
}
