import 'package:flutter/material.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/widgets/state_view.dart';
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
  bool _isLoadingMore = false;
  bool _hasMore = true;
  Object? _error;
  String? _filterStatus;

  static const int _pageSize = 30;

  @override
  void initState() {
    super.initState();
    _loadReservations(reset: true);
  }

  Future<void> _loadReservations({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _error = null;
        _reservations = [];
        _hasMore = true;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final offset = reset ? 0 : _reservations.length;
      final data = await _adminService.getAllReservations(
        status: _filterStatus,
        limit: _pageSize,
        offset: offset,
      );
      setState(() {
        if (reset) {
          _reservations = data;
        } else {
          _reservations.addAll(data);
        }
        _hasMore = data.length >= _pageSize;
        _isLoading = false;
        _isLoadingMore = false;
        _error = null;
      });
    } catch (e) {
      AppLogger.error('Error cargando reservas (admin)', e);
      setState(() {
        _error = e;
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return AppColors.warning;
      case 'ACCEPTED':
        return AppColors.success;
      case 'REJECTED':
        return AppColors.error;
      case 'COMPLETED':
        return AppColors.info;
      case 'CANCELLED':
        return AppColors.darkTextSecondary;
      case 'PAID':
        return AppColors.primary;
      case 'CONFIRMED':
        return AppColors.primary;
      default:
        return AppColors.darkTextSecondary;
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
              _loadReservations(reset: true);
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
      body: ResponsiveContainer(
        maxWidth: 960,
        child: StateView(
          isLoading: _isLoading,
          error: _error,
          onRetry: () => _loadReservations(reset: true),
          child: _reservations.isEmpty
            ? EmptyState(
                illustration: Icons.event_busy_outlined,
                title: 'No hay reservas',
                message:
                    'Las reservas de las canchas aparecerán aquí en tiempo real.',
              )
            : RefreshIndicator(
                onRefresh: () => _loadReservations(reset: true),
                color: AppColors.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: _reservations.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _reservations.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Center(
                          child: _isLoadingMore
                              ? const CircularProgressIndicator(
                                  color: AppColors.primary,
                                )
                              : ElevatedButton.icon(
                                  onPressed: () => _loadReservations(),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Cargar mas'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.darkSurface,
                                    foregroundColor: AppColors.darkTextPrimary,
                                  ),
                                ),
                        ),
                      );
                    }

                    final r = _reservations[index];
                    final status = r['status'] ?? '';
                    final statusColor = _getStatusColor(status);

                    return AnimatedEntrance(
                      delay: Duration(milliseconds: index * 60),
                      child: GlassCard(
                        padding: EdgeInsets.zero,
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
                      ),
                    );
                  },
                ),
              ),
          ),
        ),
    );
  }
}
