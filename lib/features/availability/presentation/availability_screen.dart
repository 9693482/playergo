import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/availability_service.dart';

class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  ConsumerState<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  final _availabilityService = AvailabilityService();
  List<Map<String, dynamic>> _availability = [];
  bool _isLoading = true;

  final _days = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves',
    'Viernes', 'Sábado', 'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final player = ref.read(currentPlayerProvider).valueOrNull;
    if (player == null) {
      setState(() {
        _availability = [];
        _isLoading = false;
      });
      return;
    }

    try {
      final data = await _availabilityService.getAvailability(player.id);
      setState(() {
        _availability = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _availability = [];
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic>? _getDayAvailability(int dayOfWeek) {
    try {
      return _availability.firstWhere((a) => a['day_of_week'] == dayOfWeek);
    } catch (_) {
      return null;
    }
  }

  Future<void> _toggleDay(int dayOfWeek) async {
    final player = ref.read(currentPlayerProvider).valueOrNull;
    if (player == null) return;

    final current = _getDayAvailability(dayOfWeek);

    if (current != null) {
      await _availabilityService.removeAvailability(player.id, dayOfWeek);
    } else {
      await _availabilityService.setAvailability(
        playerId: player.id,
        dayOfWeek: dayOfWeek,
        startTime: '08:00',
        endTime: '22:00',
      );
    }

    await _loadAvailability();
  }

  int _getAvailableCount() {
    return _availability.where((a) => a['is_available'] == true).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'Mi Disponibilidad',
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
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(AppSpacing.lg),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: AppRadius.medium,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.event_available,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_getAvailableCount()} de 7 días disponibles',
                              style: AppTypography.subtitle1.copyWith(
                                color: AppColors.darkTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Activa los días que puedes jugar',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.darkTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _getAvailableCount() == 0
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.event_busy,
                                size: 64,
                                color: AppColors.darkTextSecondary,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                'Sin disponibilidad',
                                style: AppTypography.subtitle1.copyWith(
                                  color: AppColors.darkTextPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                                child: Text(
                                  'Activa los días de la semana en los que puedes jugar. Los equipos verán tu disponibilidad.',
                                  style: AppTypography.body2.copyWith(
                                    color: AppColors.darkTextSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          itemCount: 7,
                          itemBuilder: (context, index) {
                            final dayAvailability = _getDayAvailability(index);
                            final isAvailable = dayAvailability != null &&
                                dayAvailability['is_available'] == true;

                            return Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: AppColors.darkSurface,
                                borderRadius: AppRadius.medium,
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.xs,
                                ),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: (isAvailable ? AppColors.success : AppColors.darkTextSecondary).withAlpha(25),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isAvailable ? Icons.check_circle : Icons.cancel,
                                    color: isAvailable ? AppColors.success : AppColors.darkTextSecondary,
                                    size: 22,
                                  ),
                                ),
                                title: Text(
                                  _days[index],
                                  style: AppTypography.body1.copyWith(
                                    color: AppColors.darkTextPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: isAvailable
                                    ? Text(
                                        '${dayAvailability['start_time']} - ${dayAvailability['end_time']}',
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.darkTextSecondary,
                                        ),
                                      )
                                    : Text(
                                        'No disponible',
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.darkTextSecondary,
                                        ),
                                      ),
                                trailing: Switch(
                                  value: isAvailable,
                                  onChanged: (_) => _toggleDay(index),
                                  activeThumbColor: AppColors.primary,
                                  inactiveTrackColor: AppColors.darkSurfaceVariant,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
