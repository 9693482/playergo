import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/currency.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/models/reservation.dart';
import '../../../shared/models/enums/enums.dart';
import '../data/reservation_service.dart';
import '../../payments/presentation/payment_screen.dart';
import '../../ratings/presentation/rate_screen.dart';
import '../../chat/data/chat_service.dart';
import '../../chat/presentation/chat_screen.dart';

class ReservationsScreen extends ConsumerStatefulWidget {
  const ReservationsScreen({super.key});

  @override
  ConsumerState<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends ConsumerState<ReservationsScreen> {
  final _reservationService = ReservationService();
  List<Reservation> _reservations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    final team = ref.read(currentTeamProvider).valueOrNull;
    if (team == null) return;

    final data = await _reservationService.getTeamReservations(team.id);
    setState(() {
      _reservations = data;
      _isLoading = false;
    });
  }

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return AppColors.warning;
      case ReservationStatus.accepted:
        return AppColors.primary;
      case ReservationStatus.rejected:
        return AppColors.error;
      case ReservationStatus.completed:
        return AppColors.success;
      case ReservationStatus.cancelled:
        return AppColors.darkTextSecondary;
      case ReservationStatus.paid:
        return AppColors.info;
      case ReservationStatus.confirmed:
        return AppColors.primary;
      default:
        return AppColors.darkTextSecondary;
    }
  }

  String _getStatusText(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return 'Pendiente';
      case ReservationStatus.accepted:
        return 'Aceptada';
      case ReservationStatus.rejected:
        return 'Rechazada';
      case ReservationStatus.completed:
        return 'Completada';
      case ReservationStatus.cancelled:
        return 'Cancelada';
      case ReservationStatus.paid:
        return 'Pagada';
      case ReservationStatus.confirmed:
        return 'Confirmada';
      default:
        return status.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'Mis Reservas',
          style: AppTypography.h2.copyWith(
            color: AppColors.darkTextPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _reservations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadReservations,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: _reservations.length,
                    itemBuilder: (context, index) {
                      final r = _reservations[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _ReservationCard(
                          reservation: r,
                          statusColor: _getStatusColor(r.status),
                          statusText: _getStatusText(r.status),
                          onRefresh: _loadReservations,
                          ref: ref,
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.xxl),
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: AppRadius.medium,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_month,
              size: 56,
              color: AppColors.darkTextSecondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No tienes reservas aun',
              style: AppTypography.body1.copyWith(
                color: AppColors.darkTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final Color statusColor;
  final String statusText;
  final VoidCallback onRefresh;
  final WidgetRef ref;

  const _ReservationCard({
    required this.reservation,
    required this.statusColor,
    required this.statusText,
    required this.onRefresh,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: AppRadius.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd/MM/yyyy').format(reservation.reservationDate),
                style: AppTypography.subtitle1.copyWith(
                  color: AppColors.darkTextPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(30),
                  borderRadius: AppRadius.full,
                ),
                child: Text(
                  statusText,
                  style: AppTypography.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: AppColors.darkTextSecondary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${reservation.startTime} - ${reservation.endTime}',
                style: AppTypography.body2.copyWith(
                  color: AppColors.darkTextSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              const Icon(Icons.attach_money, size: 16, color: AppColors.darkTextSecondary),
              Text(
                CurrencyInfo.format(
                  reservation.totalPrice,
                  CurrencyInfo.fromCountryCode('CO'),
                ),
                style: AppTypography.body2.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (reservation.status == ReservationStatus.accepted) ...[
            const SizedBox(height: AppSpacing.lg),
            _ActionButton(
              label: 'Pagar ahora',
              icon: Icons.payment,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentScreen(
                      reservationId: reservation.id,
                      amount: reservation.totalPrice,
                      playerName: 'Jugador',
                    ),
                  ),
                ).then((_) => onRefresh());
              },
            ),
          ],
          if (reservation.status == ReservationStatus.paid ||
              reservation.status == ReservationStatus.confirmed) ...[
            const SizedBox(height: AppSpacing.sm),
            _ActionButton(
              label: 'Chat con el jugador',
              icon: Icons.chat,
              backgroundColor: AppColors.darkSurfaceVariant,
              foregroundColor: AppColors.darkTextPrimary,
              onTap: () async {
                final team = ref.read(currentTeamProvider).valueOrNull;
                if (team == null) return;
                final chatService = ChatService();
                final chat = await chatService.getOrCreateChat(
                  reservation.playerId,
                  team.id,
                  reservationId: reservation.id,
                );
                final playerName = await chatService.getPlayerName(reservation.playerId);
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      chatId: chat.id,
                      otherName: playerName ?? 'Jugador',
                    ),
                  ),
                );
              },
            ),
          ],
          if (reservation.status == ReservationStatus.confirmed ||
              reservation.status == ReservationStatus.paid) ...[
            const SizedBox(height: AppSpacing.sm),
            _ActionButton(
              label: 'Completar reserva',
              icon: Icons.check_circle,
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.textOnPrimary,
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.darkSurface,
                    title: Text(
                      'Completar reserva',
                      style: AppTypography.subtitle1.copyWith(
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                    content: Text(
                      'Confirmas que la reserva se ha completado?',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          'Cancelar',
                          style: AppTypography.body2.copyWith(
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          'Completar',
                          style: AppTypography.body2.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ReservationService().completeReservation(reservation.id);
                  onRefresh();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Reserva completada'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
              },
            ),
          ],
          if (reservation.status == ReservationStatus.completed) ...[
            const SizedBox(height: AppSpacing.sm),
            _ActionButton(
              label: 'Calificar jugador',
              icon: Icons.star_outline,
              backgroundColor: AppColors.darkSurfaceVariant,
              foregroundColor: AppColors.darkTextPrimary,
              onTap: () {
                final team = ref.read(currentTeamProvider).valueOrNull;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RateScreen(
                      reservationId: reservation.id,
                      raterId: team?.userId ?? '',
                      ratedId: reservation.playerId,
                      ratedName: 'Jugador',
                    ),
                  ),
                ).then((_) => onRefresh());
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: AppTypography.button.copyWith(fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.small,
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
