import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/currency.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../search/data/search_service.dart';
import '../data/reservation_service.dart';

class CreateReservationScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> player;

  const CreateReservationScreen({super.key, required this.player});

  @override
  ConsumerState<CreateReservationScreen> createState() =>
      _CreateReservationScreenState();
}

class _CreateReservationScreenState
    extends ConsumerState<CreateReservationScreen> {
  final _reservationService = ReservationService();
  final _searchService = SearchService();
  bool _isLoading = false;

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 22, minute: 0);
  String? _selectedVenueId;
  List<Map<String, dynamic>> _venues = [];
  String? _notes;

  @override
  void initState() {
    super.initState();
    _loadVenues();
  }

  Future<void> _loadVenues() async {
    final venues = await _searchService.getVenues();
    setState(() => _venues = venues);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  double _calculateDuration() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    return (endMinutes - startMinutes) / 60.0;
  }

  double _calculateTotalPrice() {
    final duration = _calculateDuration();
    final pricePerMatch = (widget.player['price_per_match'] as num).toDouble();
    final hours = duration / 2.0;
    return pricePerMatch * hours;
  }

  Future<void> _createReservation() async {
    final team = ref.read(currentTeamProvider).valueOrNull;
    if (team == null) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user?.emailConfirmedAt == null) {
      if (mounted) await _showEmailVerificationDialog();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final duration = _calculateDuration();
      final total = _calculateTotalPrice();

      await _reservationService.createReservation(
        teamId: team.id,
        playerId: widget.player['id'],
        sportId: widget.player['sport_id'],
        positionId: widget.player['position_id'],
        venueId: _selectedVenueId,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        startTime:
            '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
        endTime:
            '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
        durationHours: duration,
        totalPrice: total,
        notes: _notes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reserva creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showEmailVerificationDialog() async {
    final email = Supabase.instance.client.auth.currentUser?.email;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verifica tu correo'),
        content: const Text(
          'Para crear una reserva debes confirmar tu dirección de correo. '
          'Revisa tu bandeja de entrada (y spam) y pulsa el enlace de '
          'confirmación. Si no lo encuentras, puedes reenviarlo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (email != null) {
                try {
                  await Supabase.instance.client.auth.resend(
                    type: OtpType.email,
                    email: email,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Correo de verificación reenviado'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('No se pudo reenviar: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Reenviar correo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerName = widget.player['full_name'] ?? 'Jugador';
    final position = widget.player['position_name'] ?? '';
    final price = (widget.player['price_per_match'] as num?)?.toDouble() ?? 0;
    final emailVerified =
        Supabase.instance.client.auth.currentUser?.emailConfirmedAt != null;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            AnimatedEntrance(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'PlayerGO',
                        style: AppTypography.h2.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withAlpha(0),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ResponsiveContainer(
                  maxWidth: 600,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!emailVerified) ...[
                        AnimatedEntrance(
                          delay: const Duration(milliseconds: 80),
                          child: GlassCard(
                            borderColor: AppColors.warning,
                            glow: AppColors.warning,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'Verifica tu correo para poder reservar.',
                                    style: AppTypography.body2.copyWith(
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _showEmailVerificationDialog,
                                  child: const Text('Reenviar'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 160),
                        child: GlassCard(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: AppColors.primary,
                                child: Text(
                                  playerName[0].toUpperCase(),
                                  style: AppTypography.h2.copyWith(
                                    color: AppColors.darkTextPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      playerName,
                                      style: AppTypography.subtitle1.copyWith(
                                        color: AppColors.darkTextPrimary,
                                      ),
                                    ),
                                    Text(
                                      position,
                                      style: AppTypography.body2.copyWith(
                                        color: AppColors.darkTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                CurrencyInfo.format(
                                  price,
                                  CurrencyInfo.fromCountryCode('CO'),
                                ),
                                style: AppTypography.h3.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 240),
                        child: Text(
                          'Fecha y hora',
                          style: AppTypography.h3.copyWith(
                            color: AppColors.darkTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 320),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.xs,
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.calendar_today,
                              color: AppColors.darkTextSecondary,
                            ),
                            title: Text(
                              DateFormat('dd/MM/yyyy').format(_selectedDate),
                              style: AppTypography.body1.copyWith(
                                color: AppColors.darkTextPrimary,
                              ),
                            ),
                            subtitle: Text(
                              'Fecha del partido',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.darkTextSecondary,
                              ),
                            ),
                            onTap: _selectDate,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 400),
                        child: Row(
                          children: [
                            Expanded(
                              child: GlassCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.xs,
                                ),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.access_time,
                                    color: AppColors.darkTextSecondary,
                                  ),
                                  title: Text(
                                    _startTime.format(context),
                                    style: AppTypography.body1.copyWith(
                                      color: AppColors.darkTextPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Hora inicio',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.darkTextSecondary,
                                    ),
                                  ),
                                  onTap: _selectStartTime,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: GlassCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.xs,
                                ),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.access_time,
                                    color: AppColors.darkTextSecondary,
                                  ),
                                  title: Text(
                                    _endTime.format(context),
                                    style: AppTypography.body1.copyWith(
                                      color: AppColors.darkTextPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Hora fin',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.darkTextSecondary,
                                    ),
                                  ),
                                  onTap: _selectEndTime,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 480),
                        child: Text(
                          'Cancha (opcional)',
                          style: AppTypography.h3.copyWith(
                            color: AppColors.darkTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 560),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.xs,
                          ),
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedVenueId,
                            decoration: InputDecoration(
                              labelText: 'Seleccionar cancha',
                              labelStyle: AppTypography.body2.copyWith(
                                color: AppColors.darkTextSecondary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.medium,
                                borderSide: const BorderSide(
                                  color: AppColors.darkSurfaceVariant,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: AppRadius.medium,
                                borderSide: const BorderSide(
                                  color: AppColors.darkSurfaceVariant,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: AppRadius.medium,
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            dropdownColor: AppColors.darkSurface,
                            items: _venues
                                .map((v) => DropdownMenuItem(
                                      value: v['id'] as String,
                                      child: Text(
                                        v['name'] as String,
                                        style: AppTypography.body1.copyWith(
                                          color: AppColors.darkTextPrimary,
                                        ),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedVenueId = value);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 640),
                        child: Text(
                          'Notas (opcional)',
                          style: AppTypography.h3.copyWith(
                            color: AppColors.darkTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 720),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          child: TextFormField(
                            maxLines: 3,
                            style: AppTypography.body1.copyWith(
                              color: AppColors.darkTextPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Ej: Llevar propio balón...',
                              hintStyle: AppTypography.body2.copyWith(
                                color: AppColors.darkTextSecondary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.medium,
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: AppRadius.medium,
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: AppRadius.medium,
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (value) => _notes = value,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 800),
                        child: GlassCard(
                          color: AppColors.darkSurfaceVariant,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Duración:',
                                    style: AppTypography.body1.copyWith(
                                      color: AppColors.darkTextSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${_calculateDuration().toStringAsFixed(1)} horas',
                                    style: AppTypography.body1.copyWith(
                                      color: AppColors.darkTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(
                                color: AppColors.darkSurfaceVariant,
                                height: AppSpacing.xl,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total:',
                                    style: AppTypography.h3.copyWith(
                                      color: AppColors.darkTextPrimary,
                                    ),
                                  ),
                                  Text(
                                    CurrencyInfo.format(
                                      _calculateTotalPrice(),
                                      CurrencyInfo.fromCountryCode('CO'),
                                    ),
                                    style: AppTypography.h2.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 880),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _createReservation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.darkTextPrimary,
                              disabledBackgroundColor:
                                  AppColors.darkSurfaceVariant,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.medium,
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: AppColors.darkTextPrimary,
                                  )
                                : Text(
                                    'Enviar Solicitud',
                                    style: AppTypography.button.copyWith(
                                      color: AppColors.darkTextPrimary,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
