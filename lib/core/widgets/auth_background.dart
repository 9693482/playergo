import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Fondo con glow radial sutil en la parte superior para reforzar la identidad
/// "deportiva / tecnológica" en las pantallas de auth, sin recargar.
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        gradient: RadialGradient(
          center: const Alignment(0, -0.9),
          radius: 1.1,
          colors: [
            AppColors.primary.withAlpha(38),
            AppColors.darkBackground.withAlpha(0),
          ],
        ),
      ),
    );
  }
}
