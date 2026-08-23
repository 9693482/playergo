import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../shared/models/reservation.dart';
import '../../../shared/models/enums/enums.dart';
import '../data/reservation_service.dart';
import '../../payments/presentation/payment_screen.dart';

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
        return Colors.orange;
      case ReservationStatus.accepted:
        return Colors.green;
      case ReservationStatus.rejected:
        return Colors.red;
      case ReservationStatus.completed:
        return Colors.blue;
      case ReservationStatus.cancelled:
        return Colors.grey;
      case ReservationStatus.paid:
        return Colors.purple;
      case ReservationStatus.confirmed:
        return Colors.teal;
      default:
        return Colors.grey;
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
      appBar: AppBar(
        title: const Text('Mis Reservas'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reservations.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No tienes reservas aún',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReservations,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reservations.length,
                    itemBuilder: (context, index) {
                      final r = _reservations[index];
                      final statusColor = _getStatusColor(r.status);
                      final statusText = _getStatusText(r.status);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(r.reservationDate),
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
                                      color: statusColor.withAlpha(25),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(
                                        color: statusColor,
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
                                  Text('${r.startTime} - ${r.endTime}'),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                                  Text('\$${r.totalPrice.toStringAsFixed(0)}'),
                                ],
                              ),
                              if (r.status == ReservationStatus.accepted) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PaymentScreen(
                                            reservationId: r.id,
                                            amount: r.totalPrice,
                                            playerName: 'Jugador',
                                          ),
                                        ),
                                      ).then((_) => _loadReservations());
                                    },
                                    icon: const Icon(Icons.payment),
                                    label: const Text('Pagar ahora'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1B5E20),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
