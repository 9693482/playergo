import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/admin_service.dart';

class AdminReservationsScreen extends StatefulWidget {
  const AdminReservationsScreen({super.key});

  @override
  State<AdminReservationsScreen> createState() =>
      _AdminReservationsScreenState();
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
      case 'PENDING': return AppColors.warning;
      case 'ACCEPTED': return AppColors.success;
      case 'REJECTED': return AppColors.error;
      case 'COMPLETED': return AppColors.info;
      case 'CANCELLED': return AppColors.darkTextSecondary;
      case 'PAID': return AppColors.primary;
      case 'CONFIRMED': return AppColors.primary;
      default: return AppColors.darkTextSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'Gestionar Reservas',
          style: AppTypography.h2.copyWith(
            color: AppColors.darkTextPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list, color: AppColors.darkTextPrimary),
            onSelected: (value) {
              setState(() => _filterStatus = value);
              _loadReservations();
            },
            color: AppColors.darkSurface,
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
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _reservations.isEmpty
              ? Center(
                  child: Text(
                    'No hay reservas',
                    style: AppTypography.body1.copyWith(
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReservations,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: _reservations.length,
                    itemBuilder: (context, index) {
                      final r = _reservations[index];
                      final status = r['status'] ?? '';
                      final statusColor = _getStatusColor(status);

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.darkSurface,
                          borderRadius: AppRadius.medium,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Reserva ${r['id'].toString().substring(0, 8)}...',
                                      style: AppTypography.subtitle2.copyWith(
                                        color: AppColors.darkTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${r['reservation_date']} • ${r['start_time']}-${r['end_time']}',
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
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withAlpha(25),
                                  borderRadius: AppRadius.small,
                                ),
                                child: Text(
                                  status,
                                  style: AppTypography.caption.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
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
