import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Tarjeta con apariencia "glass" sutil: fondo semitransparente, borde fino,
/// gradiente de luz y sombra suave. Prioriza legibilidad sobre decoración.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;
  final Color? glow;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.borderColor,
    this.glow,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: (color ?? AppColors.darkSurface).withAlpha(235),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: (borderColor ?? Colors.white).withAlpha(16),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: glow != null
                ? glow!.withAlpha(80)
                : Colors.black.withAlpha(130),
            blurRadius: glow != null ? 26 : 16,
            spreadRadius: glow != null ? 1 : 0,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x14FFFFFF), Colors.transparent],
        ),
      ),
      child: child,
    );
  }
}
