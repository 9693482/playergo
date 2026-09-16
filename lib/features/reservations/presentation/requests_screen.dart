import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/currency.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/models/reservation.dart';
import '../../../shared/models/enums/enums.dart';
import '../data/reservation_service.dart';
import '../../checkin/presentation/qr_display_screen.dart';
import '../../disputes/presentation/open_dispute_screen.dart';
import '../../chat/data/chat_service.dart';
import '../../chat/presentation/chat_screen.dart';

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
  final _reservationService = ReservationService();
  List<Reservation> _reservations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    final player = ref.read(currentPlayerProvider).valueOrNull;
    if (player == null) return;

    final data = await _reservationService.getPlayerReservations(player.id);
    setState(() {
      _reservations = data;
      _isLoading = false;
    });
  }

  Future<void> _acceptReservation(Reservation reservation) async {
    await _reservationService.acceptReservation(reservation.id);
    await _loadReservations();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reserva aceptada'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _rejectReservation(Reservation reservation) async {
    await _reservationService.rejectReservation(reservation.id);
    await _loadReservations();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reserva rechazada'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showQR(Reservation reservation) {
    final player = ref.read(currentPlayerProvider).valueOrNull;
    if (player == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRDisplayScreen(
          reservationId: reservation.id,
          playerId: player.id,
          teamId: reservation.teamId,
        ),
      ),
    );
  }

  void _openDispute(Reservation reservation) {
    final profile = ref.read(currentProfileProvider).valueOrNull;
    if (profile == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OpenDisputeScreen(
          reservationId: reservation.id,
          userId: profile.id,
        ),
      ),
    );
  }

  Future<void> _openChat(Reservation reservation) async {
    final player = ref.read(currentPlayerProvider).valueOrNull;
    if (player == null) return;

    final chatService = ChatService();
    final chat = await chatService.getOrCreateChat(
      player.id,
      reservation.teamId,
      reservationId: reservation.id,
    );

    final teamName = await chatService.getTeamName(reservation.teamId);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chat.id,
          otherName: teamName ?? 'Equipo',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingReservations =
        _reservations.where((r) => r.status == ReservationStatus.pending).toList();
    final otherReservations =
        _reservations.where((r) => r.status != ReservationStatus.pending).toList();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'Mis Solicitudes',
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _reservations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox_outlined, size: 64, color: AppColors.darkTextSecondary),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'No tienes solicitudes',
                        style: AppTypography.subtitle1.copyWith(
                          color: AppColors.darkTextPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Cuando un equipo te invite, aparecerá aquí.',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.darkTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReservations,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (pendingReservations.isNotEmpty) ...[
                        Text(
                          'Pendientes',
                          style: AppTypography.subtitle1.copyWith(
                            color: AppColors.darkTextPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...pendingReservations.map(
                          (r) => _ReservationCard(
                            reservation: r,
                            isPending: true,
                            onAccept: () => _acceptReservation(r),
                            onReject: () => _rejectReservation(r),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (otherReservations.isNotEmpty) ...[
                        Text(
                          'Historial',
                          style: AppTypography.subtitle1.copyWith(
                            color: AppColors.darkTextPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...otherReservations.map(
                          (r) => _ReservationCard(
                            reservation: r,
                            isPending: false,
                            onShowQR: (r.status == ReservationStatus.accepted ||
                                    r.status == ReservationStatus.confirmed)
                                ? () => _showQR(r)
                                : null,
                            onOpenDispute: (r.status == ReservationStatus.cancelled ||
                                    r.status == ReservationStatus.rejected)
                                ? () => _openDispute(r)
                                : null,
                            onChat: (r.status == ReservationStatus.accepted ||
                                    r.status == ReservationStatus.confirmed)
                                ? () => _openChat(r)
                                : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final bool isPending;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onShowQR;
  final VoidCallback? onOpenDispute;
  final VoidCallback? onChat;

  const _ReservationCard({
    required this.reservation,
    required this.isPending,
    this.onAccept,
    this.onReject,
    this.onShowQR,
    this.onOpenDispute,
    this.onChat,
  });

  Color _getStatusColor() {
    switch (reservation.status) {
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

  String _getStatusText() {
    switch (reservation.status) {
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
        return reservation.status.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: AppRadius.medium,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withAlpha(30),
                    borderRadius: AppRadius.full,
                  ),
                  child: Text(
                    _getStatusText(),
                    style: AppTypography.caption.copyWith(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: AppColors.darkTextSecondary),
                const SizedBox(width: 4),
                Text(
                  '${reservation.startTime} - ${reservation.endTime}',
                  style: AppTypography.body2.copyWith(color: AppColors.darkTextSecondary),
                ),
                const SizedBox(width: AppSpacing.md),
                const Icon(Icons.attach_money, size: 16, color: AppColors.darkTextSecondary),
                Text(
                  CurrencyInfo.format(reservation.totalPrice, CurrencyInfo.fromCountryCode('CO')),
                  style: AppTypography.body2.copyWith(color: AppColors.darkTextSecondary),
                ),
              ],
            ),
            if (isPending) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.medium,
                        ),
                      ),
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.medium,
                        ),
                      ),
                      child: const Text('Aceptar'),
                    ),
                  ),
                ],
              ),
            ],
            if (reservation.status == ReservationStatus.accepted ||
                reservation.status == ReservationStatus.confirmed) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onShowQR,
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Mostrar QR de Check-in'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.medium,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onChat,
                  icon: const Icon(Icons.chat),
                  label: const Text('Chat con el equipo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.info,
                    side: const BorderSide(color: AppColors.info),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.medium,
                    ),
                  ),
                ),
              ),
            ],
            if (reservation.status == ReservationStatus.cancelled ||
                reservation.status == ReservationStatus.rejected) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onOpenDispute,
                  icon: const Icon(Icons.gavel),
                  label: const Text('Abrir disputa'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warning,
                    side: const BorderSide(color: AppColors.warning),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.medium,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
