import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../generated/app_localizations.dart';
import '../../../shared/models/enums/enums.dart';
import '../../../shared/models/reservation.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/presentation/chat_list_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../profile/presentation/team_profile_screen.dart';
import '../../reservations/data/reservation_service.dart';
import '../../reservations/presentation/reservations_screen.dart';
import '../../search/presentation/search_screen.dart';

class TeamHomeScreen extends ConsumerStatefulWidget {
  const TeamHomeScreen({super.key});

  @override
  ConsumerState<TeamHomeScreen> createState() => _TeamHomeScreenState();
}

class _TeamHomeScreenState extends ConsumerState<TeamHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const _TeamDashboard(),
          const SearchScreen(),
          const ChatListScreen(),
          const TeamProfileScreen(),
        ],
      ),
      bottomNavigationBar: _CustomBottomNav(
        selectedIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _TeamDashboard extends ConsumerWidget {
  const _TeamDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context)!;
    final team = ref.watch(currentTeamProvider);

    return SafeArea(
      child: team.when(
        data: (t) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(currentTeamProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),
                _buildHeader(context, s),
                const SizedBox(height: AppSpacing.xxl),
                _buildGreeting(t?.teamName ?? 'Equipo'),
                const SizedBox(height: AppSpacing.xxl),
                _buildSubtitle(),
                const SizedBox(height: AppSpacing.lg),
                _buildPositionGrid(context),
                const SizedBox(height: AppSpacing.xxl),
                _buildSearchButton(context),
                const SizedBox(height: AppSpacing.xxl),
                _buildQuickActions(context),
                const SizedBox(height: AppSpacing.xxl),
                _buildUpcomingSection(context, ref, t?.id),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations s) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Player',
                style: AppTypography.h2.copyWith(
                  color: AppColors.darkTextPrimary,
                ),
              ),
              TextSpan(
                text: 'GO',
                style: AppTypography.h2.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.darkTextPrimary,
            size: 26,
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting(String teamName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hola, $teamName 👋',
          style: AppTypography.h1.copyWith(
            color: AppColors.darkTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle() {
    return Text(
      '¿Qué jugador necesitas hoy?',
      style: AppTypography.body1.copyWith(
        color: AppColors.darkTextSecondary,
      ),
    );
  }

  Widget _buildPositionGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.6,
      children: const [
        _PositionCard(
          emoji: '🧤',
          label: 'Arquero',
          color: Color(0xFFFFF3E0),
        ),
        _PositionCard(
          emoji: '🛡',
          label: 'Defensa',
          color: Color(0xFFE3F2FD),
        ),
        _PositionCard(
          emoji: '⚽',
          label: 'Mediocampista',
          color: Color(0xFFE8F5E9),
        ),
        _PositionCard(
          emoji: '🏃',
          label: 'Delantero',
          color: Color(0xFFFCE4EC),
        ),
      ],
    );
  }

  Widget _buildSearchButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        ),
        icon: const Icon(Icons.search, size: 22),
        label: Text(
          'Buscar jugadores',
          style: AppTypography.button,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.medium,
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.qr_code_scanner,
            label: 'Escanear QR',
            onTap: () {},
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.calendar_month,
            label: 'Mis reservas',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReservationsScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingSection(
    BuildContext context,
    WidgetRef ref,
    String? teamId,
  ) {
    if (teamId == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reservas próximas',
          style: AppTypography.subtitle1.copyWith(
            color: AppColors.darkTextPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FutureBuilder<List<Reservation>>(
          future: ReservationService().getTeamReservations(teamId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }

            final reservations = snapshot.data ?? [];
            final upcoming = reservations
                .where((r) =>
                    r.status != ReservationStatus.cancelled &&
                    r.status != ReservationStatus.completed &&
                    r.status != ReservationStatus.rejected)
                .take(3)
                .toList();

            if (upcoming.isEmpty) {
              return _EmptyStateCard(
                icon: Icons.calendar_today,
                message: 'No tienes reservas próximas',
              );
            }

            return Column(
              children: upcoming
                  .map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _ReservationCard(reservation: r),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _PositionCard extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;

  const _PositionCard({
    required this.emoji,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.medium,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.medium,
        child: InkWell(
          borderRadius: AppRadius.medium,
          onTap: () => context.go('/search?position=$label'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  label,
                  style: AppTypography.subtitle2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: AppRadius.medium,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.medium,
        child: InkWell(
          borderRadius: AppRadius.medium,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.lg,
              horizontal: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.darkTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final Reservation reservation;

  const _ReservationCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(reservation.status);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: AppRadius.medium,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(reservation.reservationDate),
                  style: AppTypography.body2.copyWith(
                    color: AppColors.darkTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${reservation.startTime} - ${reservation.endTime}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.darkTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(30),
              borderRadius: AppRadius.small,
            ),
            child: Text(
              _getStatusLabel(reservation.status),
              style: AppTypography.caption.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return AppColors.warning;
      case ReservationStatus.accepted:
        return AppColors.primary;
      case ReservationStatus.paid:
        return AppColors.info;
      case ReservationStatus.confirmed:
        return AppColors.primary;
      case ReservationStatus.completed:
        return AppColors.success;
      default:
        return AppColors.darkTextSecondary;
    }
  }

  String _getStatusLabel(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return 'Pendiente';
      case ReservationStatus.accepted:
        return 'Aceptada';
      case ReservationStatus.paid:
        return 'Pagada';
      case ReservationStatus.confirmed:
        return 'Confirmada';
      case ReservationStatus.completed:
        return 'Completada';
      default:
        return status.name;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Hoy';
    }
    return DateFormat('d MMM', 'es').format(date);
  }
}

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyStateCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: AppRadius.medium,
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.darkTextSecondary),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: AppTypography.body2.copyWith(
              color: AppColors.darkTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _CustomBottomNav({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(
          top: BorderSide(color: AppColors.darkSurfaceVariant, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Inicio',
                isActive: selectedIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.search,
                activeIcon: Icons.search,
                label: 'Buscar',
                isActive: selectedIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: 'Chats',
                isActive: selectedIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.person_outlined,
                activeIcon: Icons.person,
                label: 'Perfil',
                isActive: selectedIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            color: isActive ? AppColors.primary : AppColors.darkTextSecondary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isActive ? AppColors.primary : AppColors.darkTextSecondary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
