import 'package:flutter/material.dart';

/// Breakpoints y helpers de responsividad para tablet/web.
class AppBreakpoints {
  static const double tablet = 600;
  static const double desktop = 1024;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;

  /// Ancho máximo del contenido según el breakpoint.
  static double contentMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktop) return 960;
    if (width >= tablet) return 720;
    return width;
  }
}

/// Centra y acota el ancho del contenido en pantallas grandes (tablet/web),
/// evitando que los layouts mobile-first se estiren de forma poco legible.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final width = maxWidth ?? AppBreakpoints.contentMaxWidth(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}
