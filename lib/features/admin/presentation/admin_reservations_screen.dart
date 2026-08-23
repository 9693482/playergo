import 'package:flutter/material.dart';

import '../data/admin_service.dart';

class AdminReservationsScreen extends StatefulWidget {
  const AdminReservationsScreen({super.key});

  @override
  State<AdminReservationsScreen> createState() => _AdminReservationsScreenState();
}

class _AdminReservationsScreenState extends State<AdminReservationsScreen> {
  final _adminService = AdminService();
  List<Map<String, dynamic>> _reservations = [];
  bool _isLoading = true;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() => _isLoading = true);
    final data = await _adminService.getAllReservations(status: _filterStatus);
    setState(() {
      _reservations = data;
      _isLoading = false;
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING': return Colors.orange;
      case 'ACCEPTED': return Colors.green;
      case 'REJECTED': return Colors.red;
      case 'COMPLETED': return Colors.blue;
      case 'CANCELLED': return Colors.grey;
      case 'PAID': return Colors.purple;
      case 'CONFIRMED': return Colors.teal;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Reservas'),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _filterStatus = value);
              _loadReservations();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('Todas')),
              const PopupMenuItem(value: 'PENDING', child: Text('Pendientes')),
              const PopupMenuItem(value: 'ACCEPTED', child: Text('Aceptadas')),
              const PopupMenuItem(value: 'COMPLETED', child: Text('Completadas')),
              const PopupMenuItem(value: 'CANCELLED', child: Text('Canceladas')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reservations.isEmpty
              ? const Center(child: Text('No hay reservas'))
              : RefreshIndicator(
                  onRefresh: _loadReservations,
                  child: ListView.builder(
                    itemCount: _reservations.length,
                    itemBuilder: (context, index) {
                      final r = _reservations[index];
                      final status = r['status'] ?? '';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          title: Text(
                            'Reserva ${r['id'].toString().substring(0, 8)}...',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${r['reservation_date']} • ${r['start_time']}-${r['end_time']}',
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
