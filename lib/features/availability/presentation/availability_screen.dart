import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_entrance.dart';
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
  bool _isSaving = false;

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
      if (mounted) {
        setState(() {
          _availability = [];
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final data = await _availabilityService.getAvailability(player.id);
      if (mounted) {
        setState(() {
          _availability = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _availability = [];
          _isLoading = false;
        });
      }
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
    if (!mounted) return;
    setState(() => _isSaving = true);

    try {
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
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, 'Error al actualizar disponibilidad');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _editTime(int dayOfWeek) async {
    final current = _getDayAvailability(dayOfWeek);
    if (current == null) return;

    final startParts = (current['start_time'] as String? ?? '08:00').split(':');
    final endParts = (current['end_time'] as String? ?? '22:00').split(':');

    TimeOfDay startTime = TimeOfDay(
      hour: int.tryParse(startParts[0]) ?? 8,
      minute: int.tryParse(startParts.length > 1 ? startParts[1] : '0') ?? 0,
    );
    TimeOfDay endTime = TimeOfDay(
      hour: int.tryParse(endParts[0]) ?? 22,
      minute: int.tryParse(endParts.length > 1 ? endParts[1] : '0') ?? 0,
    );

    final pickedStart = await showTimePicker(
      context: context,
      initialTime: startTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.darkSurface,
          ),
        ),
        child: child!,
      ),
    );

    if (pickedStart != null) {
      startTime = pickedStart;
    }

    if (!mounted) return;

    final pickedEnd = await showTimePicker(
      context: context,
      initialTime: endTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.darkSurface,
          ),
        ),
        child: child!,
      ),
    );

    if (pickedEnd != null) {
      endTime = pickedEnd;
    }

    final startStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

    final player = ref.read(currentPlayerProvider).valueOrNull;
    if (player == null) return;
    if (!mounted) return;

    setState(() => _isSaving = true);
    try {
      await _availabilityService.setAvailability(
        playerId: player.id,
        dayOfWeek: dayOfWeek,
        startTime: startStr,
        endTime: endStr,
      );
      await _loadAvailability();
      if (mounted) {
        AppFeedback.showSuccess(context, 'Horario actualizado');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, 'Error al actualizar horario');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  int _getAvailableCount() {
    return _availability.where((a) => a['is_available'] == true).length;
  }

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(animate),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : Column(
                      children: [
                        _buildSummaryCard(),
                        Expanded(
                          child: _getAvailableCount() == 0 && !_isLoading
                              ? _buildEmptyState()
                              : _buildDayList(animate),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool animate) {
    return AnimatedEntrance(
      animate: animate,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.darkTextPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                Text('📅', style: AppTypography.h2),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Mi Disponibilidad',
                    style: AppTypography.h2.copyWith(color: AppColors.darkTextPrimary),
                  ),
                ),
                if (_isSaving)
                  const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                  ),
              ],
            ),
          ),
          Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.success]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return AnimatedEntrance(
      delay: const Duration(milliseconds: 100),
      child: Container(
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
              child: const Icon(Icons.event_available, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_getAvailableCount()} de 7 días disponibles',
                    style: AppTypography.subtitle1.copyWith(color: AppColors.darkTextPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toca el día para activar. Toca la hora para editar.',
                    style: AppTypography.caption.copyWith(color: AppColors.darkTextSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy, size: 64, color: AppColors.darkTextSecondary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Sin disponibilidad',
            style: AppTypography.subtitle1.copyWith(color: AppColors.darkTextPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Text(
              'Activa los días de la semana en los que puedes jugar. Los equipos verán tu disponibilidad.',
              style: AppTypography.body2.copyWith(color: AppColors.darkTextSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayList(bool animate) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: 7,
      itemBuilder: (context, index) {
        final dayAvailability = _getDayAvailability(index);
        final isAvailable = dayAvailability != null && dayAvailability['is_available'] == true;

        return AnimatedEntrance(
          delay: Duration(milliseconds: 80 * index),
          animate: animate,
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: AppRadius.medium,
              border: isAvailable
                  ? Border.all(color: AppColors.primary.withAlpha(60), width: 1)
                  : null,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              leading: GestureDetector(
                onTap: () => _toggleDay(index),
                child: Container(
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
              ),
              title: GestureDetector(
                onTap: () => _toggleDay(index),
                child: Text(
                  _days[index],
                  style: AppTypography.body1.copyWith(
                    color: AppColors.darkTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              subtitle: isAvailable
                  ? GestureDetector(
                      onTap: () => _editTime(index),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${dayAvailability['start_time']} - ${dayAvailability['end_time']}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.edit, size: 12, color: AppColors.primary.withAlpha(150)),
                        ],
                      ),
                    )
                  : Text(
                      'No disponible',
                      style: AppTypography.caption.copyWith(color: AppColors.darkTextSecondary),
                    ),
              trailing: Switch(
                value: isAvailable,
                onChanged: (_) => _toggleDay(index),
                activeThumbColor: AppColors.primary,
                inactiveTrackColor: AppColors.darkSurfaceVariant,
              ),
            ),
          ),
        );
      },
    );
  }
}
