import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_view.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/widgets/circular_kpi.dart';
import '../../../core/widgets/position_pod.dart';
import '../../../core/widgets/quick_action_circular.dart';
import '../../../core/widgets/circular_nav_bar.dart';
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
    final useRail = AppBreakpoints.isTablet(context);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Row(
        children: [
          if (useRail)
            NavigationRail(
              backgroundColor: AppColors.darkSurface,
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) => setState(() => _currentIndex = i),
              labelType: NavigationRailLabelType.all,
              selectedIconTheme:
                  const IconThemeData(color: AppColors.primary, size: 24),
              unselectedIconTheme: const IconThemeData(
                color: AppColors.darkTextSecondary,
                size: 24,
              ),
              selectedLabelTextStyle: AppTypography.caption
                  .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
              unselectedLabelTextStyle: AppTypography.caption
                  .copyWith(color: AppColors.darkTextSecondary),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Inicio'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.search),
                  selectedIcon: Icon(Icons.search),
                  label: Text('Buscar'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.chat_bubble_outline),
                  selectedIcon: Icon(Icons.chat_bubble),
                  label: Text('Chats'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outlined),
                  selectedIcon: Icon(Icons.person),
                  label: Text('Perfil'),
                ),
              ],
            ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                const _TeamDashboard(),
                const SearchScreen(),
                const ChatListScreen(),
                const TeamProfileScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: useRail
          ? null
          : CircularNavBar(
              items: const [
                CircularNavItemData(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Inicio'),
                CircularNavItemData(icon: Icons.search, activeIcon: Icons.search, label: 'Buscar'),
                CircularNavItemData(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Chats'),
                CircularNavItemData(icon: Icons.person_outlined, activeIcon: Icons.person, label: 'Perfil'),
              ],
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
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final animate = !reduceMotion;

    return SafeArea(
      child: team.when(
        data: (t) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(currentTeamProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: ResponsiveContainer(
              maxWidth: 960,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  AnimatedEntrance(
                    animate: animate,
                    child: _buildHeader(context, ref, s),
                  ),
                  const SizedBox(height: AppSpacing.lg),
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
                  AnimatedEntrance(
                    delay: const Duration(milliseconds: 80),
                    animate: animate,
                    child: _buildGreeting(t?.teamName ?? 'Equipo'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AnimatedEntrance(
                    delay: const Duration(milliseconds: 120),
                    animate: animate,
                    child: _buildSubtitle(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AnimatedEntrance(
                    delay: const Duration(milliseconds: 200),
                    animate: animate,
                    child: _buildKpiRow(animate),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AnimatedEntrance(
                    delay: const Duration(milliseconds: 280),
                    animate: animate,
                    child: _buildPositionGrid(context),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AnimatedEntrance(
                    delay: const Duration(milliseconds: 340),
                    animate: animate,
                    child: _buildSearchButton(context),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AnimatedEntrance(
                    delay: const Duration(milliseconds: 400),
                    animate: animate,
                    child: _buildQuickActions(context),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AnimatedEntrance(
                    delay: const Duration(milliseconds: 480),
                    animate: animate,
                    child: _buildUpcomingSection(context, ref, t?.id),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
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

  Widget _buildHeader(BuildContext context, WidgetRef ref, AppLocalizations s) {
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            IconButton(
              onPressed: () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                }
              },
              icon: const Icon(
                Icons.logout,
                color: AppColors.error,
                size: 26,
              ),
              tooltip: 'Cerrar sesión',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGreeting(String teamName) {
    return Text(
      'Hola, $teamName 👋',
      style: AppTypography.h1.copyWith(
        color: AppColors.darkTextPrimary,
      ),
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

  Widget _buildKpiRow(bool animate) {
    return Row(
      children: [
        Expanded(
          child: CircularKPI(
            icon: Icons.group,
            label: 'Equipo',
            value: 0,
            color: AppColors.primary,
            ringProgress: 0,
            statusLabel: 'Tu equipo',
            animate: animate,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: CircularKPI(
            icon: Icons.search,
            label: 'Búsquedas',
            value: 0,
            color: AppColors.info,
            ringProgress: 0,
            statusLabel: 'Operativo',
            animate: animate,
          ),
        ),
      ],
    );
  }

  Widget _buildPositionGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.0,
      children: [
        PositionPod(
          emoji: '🧤',
          label: 'Arquero',
          color: AppColors.warning,
          onTap: () => context.go('/search?position=Arquero'),
        ),
        PositionPod(
          emoji: '🛡',
          label: 'Defensa',
          color: AppColors.info,
          onTap: () => context.go('/search?position=Defensa'),
        ),
        PositionPod(
          emoji: '⚽',
          label: 'Mediocampista',
          color: AppColors.primary,
          onTap: () => context.go('/search?position=Mediocampista'),
        ),
        PositionPod(
          emoji: '🏃',
          label: 'Delantero',
          color: AppColors.error,
          onTap: () => context.go('/search?position=Delantero'),
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
          child: QuickActionCircular(
            icon: Icons.qr_code_scanner,
            label: 'Escanear QR',
            color: AppColors.primary,
            onTap: () {},
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: QuickActionCircular(
            icon: Icons.calendar_month,
            label: 'Mis reservas',
            color: AppColors.info,
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
        _TeamUpcomingReservations(teamId: teamId),
      ],
    );
  }
}

class _TeamUpcomingReservations extends StatefulWidget {
  final String teamId;

  const _TeamUpcomingReservations({required this.teamId});

  @override
  State<_TeamUpcomingReservations> createState() =>
      _TeamUpcomingReservationsState();
}

class _TeamUpcomingReservationsState extends State<_TeamUpcomingReservations> {
  late Future<List<Reservation>> _future;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Reservation>> _load() async {
    setState(() => _error = null);
    try {
      return await ReservationService().getTeamReservations(widget.teamId);
    } catch (e) {
      _error = e;
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StateView(
      isLoading: false,
      error: _error,
      onRetry: () => setState(() => _future = _load()),
      child: FutureBuilder<List<Reservation>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _error == null) {
            return const SkeletonList(itemCount: 3);
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
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final Reservation reservation;

  const _ReservationCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(reservation.status);

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
    return SizedBox(
      width: double.infinity,
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.xxl),
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
      ),
    );
  }
}
