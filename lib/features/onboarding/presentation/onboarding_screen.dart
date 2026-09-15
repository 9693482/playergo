import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Onboarding inicial mostrado en el primer arranque de la app.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardingPageData(
      icon: Icons.sports_soccer_outlined,
      title: 'Encuentra tu cancha',
      body:
          'Reserva canchas de fútbol, pádel y más en tu ciudad con unos pocos toques.',
    ),
    _OnboardingPageData(
      icon: Icons.group_add_outlined,
      title: 'Crea o únete a un equipo',
      body:
          'Forma tu equipo o busca jugadores para completar tu plantel y competir.',
    ),
    _OnboardingPageData(
      icon: Icons.verified_user_outlined,
      title: 'Verifica tu identidad',
      body:
          'Sube tu documento para una comunidad segura y reservas sin sorpresas.',
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 520,
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    final p = _pages[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            p.icon,
                            size: 64,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxxl),
                        Text(
                          p.title,
                          style: AppTypography.h2.copyWith(
                            color: AppColors.darkTextPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          p.body,
                          style: AppTypography.body1.copyWith(
                            color: AppColors.darkTextSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _page == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _page == i
                          ? AppColors.primary
                          : AppColors.darkSurfaceVariant,
                      borderRadius: AppRadius.small,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLast
                      ? _finish
                      : () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.medium,
                    ),
                    elevation: 0,
                  ),
                  child: Text(isLast ? 'Empezar' : 'Continuar'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (!isLast)
                TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Omitir',
                    style: AppTypography.body2.copyWith(
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String body;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.body,
  });
}
