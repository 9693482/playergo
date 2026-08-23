import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/currency.dart';
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
      appBar: AppBar(
        title: const Text('Mis Solicitudes'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reservations.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No tienes solicitudes aún',
                        style: TextStyle(color: Colors.grey),
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
                        const Text(
                          'Pendientes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                        const Text(
                          'Historial',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
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
        return Colors.orange;
      case ReservationStatus.accepted:
        return Colors.green;
      case ReservationStatus.rejected:
        return Colors.red;
      case ReservationStatus.completed:
        return Colors.blue;
      case ReservationStatus.cancelled:
        return Colors.grey;
      default:
        return Colors.grey;
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(reservation.reservationDate),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${reservation.startTime} - ${reservation.endTime}'),
                const SizedBox(width: 16),
                const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                Text(CurrencyInfo.format(reservation.totalPrice, CurrencyInfo.fromCountryCode('CO'))),
              ],
            ),
            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Aceptar'),
                    ),
                  ),
                ],
              ),
            ],
            if (reservation.status == ReservationStatus.accepted ||
                reservation.status == ReservationStatus.confirmed) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onShowQR,
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Mostrar QR de Check-in'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1B5E20),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onChat,
                  icon: const Icon(Icons.chat),
                  label: const Text('Chat con el equipo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
            if (reservation.status == ReservationStatus.cancelled ||
                reservation.status == ReservationStatus.rejected) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onOpenDispute,
                  icon: const Icon(Icons.gavel),
                  label: const Text('Abrir disputa'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
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
