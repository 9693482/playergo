import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/currency.dart';
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

  @override
  Widget build(BuildContext context) {
    final playerName = widget.player['full_name'] ?? 'Jugador';
    final position = widget.player['position_name'] ?? '';
    final price = (widget.player['price_per_match'] as num?)?.toDouble() ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Reserva'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFF1B5E20),
                      child: Text(
                        playerName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playerName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            position,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyInfo.format(price, CurrencyInfo.fromCountryCode('CO')),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Fecha y hora',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
              subtitle: const Text('Fecha del partido'),
              onTap: _selectDate,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: Text(_startTime.format(context)),
                    subtitle: const Text('Hora inicio'),
                    onTap: _selectStartTime,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: Text(_endTime.format(context)),
                    subtitle: const Text('Hora fin'),
                    onTap: _selectEndTime,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Cancha (opcional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedVenueId,
              decoration: InputDecoration(
                labelText: 'Seleccionar cancha',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _venues
                  .map((v) => DropdownMenuItem(
                        value: v['id'] as String,
                        child: Text(v['name'] as String),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedVenueId = value);
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Notas (opcional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ej: Llevar propio balón...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => _notes = value,
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Duración:'),
                        Text('${_calculateDuration().toStringAsFixed(1)} horas'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          CurrencyInfo.format(_calculateTotalPrice(), CurrencyInfo.fromCountryCode('CO')),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createReservation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Enviar Solicitud',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
