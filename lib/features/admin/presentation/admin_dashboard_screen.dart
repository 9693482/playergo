import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/admin_service.dart';
import 'admin_users_screen.dart';
import 'admin_reservations_screen.dart';
import 'admin_disputes_screen.dart';
import '../../verification/presentation/admin_verification_screen.dart';
import 'widgets/hero_summary.dart';
import 'widgets/kpi_ring_card.dart';
import 'widgets/management_tile.dart';
import 'widgets/dashboard_skeleton.dart';

/// Color turquesa para "Reservas activas" (verde/turquesa según guía visual).
const Color _turquoise = Color(0xFF1DE9B6);

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final _adminService = AdminService();
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _adminService.getDashboardStats();
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final animate = !reduceMotion;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkTextPrimary),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Volver',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Centro de Control',
              style: AppTypography.h3.copyWith(
                color: AppColors.darkTextPrimary,
              ),
            ),
            Text(
              'Gestión deportiva',
              style: AppTypography.caption.copyWith(
                color: AppColors.darkTextSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.darkTextPrimary),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) {
                Navigator.of(context).popUntil((r) => r.isFirst);
              }
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: AppColors.primary,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ResponsiveContainer(
            maxWidth: 960,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Línea indicadora sutil bajo el header.
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withAlpha(0),
                        AppColors.primary,
                        AppColors.primary.withAlpha(0),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _isLoading
                    ? const DashboardSkeleton()
                    : _Body(
                        stats: _stats,
                        animate: animate,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool animate;

  const _Body({required this.stats, required this.animate});

  @override
  Widget build(BuildContext context) {
    final users = (stats['totalUsers'] as int?) ?? 0;
    final players = (stats['totalPlayers'] as int?) ?? 0;
    final teams = (stats['totalTeams'] as int?) ?? 0;
    final reservations = (stats['totalReservations'] as int?) ?? 0;
    final active = (stats['activeReservations'] as int?) ?? 0;
    final disputes = (stats['openDisputes'] as int?) ?? 0;

    final usersKpi = KpiRingCard(
      icon: Icons.people,
      label: 'Usuarios',
      value: users,
      color: AppColors.info,
      ringProgress: 0.72,
      statusLabel: 'Operativo',
      animate: animate,
    );
    final playersKpi = KpiRingCard(
      icon: Icons.sports_soccer,
      label: 'Jugadores',
      value: players,
      color: AppColors.primary,
      ringProgress: 0.58,
      statusLabel: 'Registrados',
      animate: animate,
    );
    final teamsKpi = KpiRingCard(
      icon: Icons.groups,
      label: 'Equipos',
      value: teams,
      color: AppColors.warning,
      ringProgress: 0.46,
      statusLabel: 'Activos',
      animate: animate,
    );
    final reservationsKpi = KpiRingCard(
      icon: Icons.calendar_month,
      label: 'Reservas',
      value: reservations,
      color: AppColors.primary,
      ringProgress: 0.82,
      statusLabel: 'Histórico',
      wide: true,
      animate: animate,
    );
    final activeKpi = KpiRingCard(
      icon: Icons.pending_actions,
      label: 'Reservas activas',
      value: active,
      color: _turquoise,
      ringProgress: 0.66,
      statusLabel: 'En curso',
      animate: animate,
    );
    final disputesKpi = KpiRingCard(
      icon: Icons.gavel,
      label: 'Disputas abiertas',
      value: disputes,
      color: AppColors.error,
      ringProgress: 0.54,
      statusLabel: disputes > 0 ? 'Requiere atención' : 'Sin abiertas',
      animate: animate,
    );

    final gap = const SizedBox(width: AppSpacing.md);
    final gapH = const SizedBox(height: AppSpacing.md);

    final w = MediaQuery.of(context).size.width;
    final threeCol = w >= 720;
    final twoCol = w >= 460;

    Widget kpiSection;
    if (threeCol) {
      kpiSection = Column(
        children: [
          Row(children: [Expanded(child: usersKpi), gap, Expanded(child: playersKpi), gap, Expanded(child: teamsKpi)]),
          gapH,
          reservationsKpi,
          gapH,
          Row(children: [Expanded(child: activeKpi), gap, Expanded(child: disputesKpi)]),
        ],
      );
    } else if (twoCol) {
      kpiSection = Column(
        children: [
          Row(children: [Expanded(child: usersKpi), gap, Expanded(child: playersKpi)]),
          gapH,
          Row(children: [Expanded(child: teamsKpi), gap, Expanded(child: reservationsKpi)]),
          gapH,
          Row(children: [Expanded(child: activeKpi), gap, Expanded(child: disputesKpi)]),
        ],
      );
    } else {
      kpiSection = Column(
        children: [
          usersKpi, gapH, playersKpi, gapH, teamsKpi, gapH,
          reservationsKpi, gapH, activeKpi, gapH, disputesKpi,
        ],
      );
    }

    final management = [
      ManagementTile(
        icon: Icons.people_outline,
        title: 'Gestionar usuarios',
        subtitle: 'Ver, banear, verificar usuarios',
        animate: animate,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
        ),
      ),
      ManagementTile(
        icon: Icons.verified_user_outlined,
        title: 'Verificaciones pendientes',
        subtitle: 'Aprobar o rechazar documentos de identidad',
        animate: animate,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminVerificationScreen()),
        ),
      ),
      ManagementTile(
        icon: Icons.calendar_month_outlined,
        title: 'Gestionar reservas',
        subtitle: 'Ver todas las reservas',
        animate: animate,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminReservationsScreen()),
        ),
      ),
      ManagementTile(
        icon: Icons.gavel,
        title: 'Gestionar disputas',
        subtitle: 'Resolver disputas abiertas',
        animate: animate,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminDisputesScreen()),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedEntrance(
          animate: animate,
          child: HeroSummary(stats: stats, animate: animate),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Indicadores',
          style: AppTypography.h3.copyWith(color: AppColors.darkTextPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        AnimatedEntrance(
          delay: const Duration(milliseconds: 120),
          animate: animate,
          child: kpiSection,
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Gestión',
          style: AppTypography.h3.copyWith(color: AppColors.darkTextPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Administra los recursos de la plataforma',
          style: AppTypography.body2.copyWith(color: AppColors.darkTextSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        ...management.asMap().entries.map((e) {
          return AnimatedEntrance(
            delay: Duration(milliseconds: 240 + e.key * 80),
            animate: animate,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: e.value,
            ),
          );
        }),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
