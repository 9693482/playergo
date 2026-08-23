import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    if (player == null) return;

    final data = await _availabilityService.getAvailability(player.id);
    setState(() {
      _availability = data;
      _isLoading = false;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Disponibilidad'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 7,
              itemBuilder: (context, index) {
                final dayAvailability = _getDayAvailability(index);
                final isAvailable = dayAvailability != null &&
                    dayAvailability['is_available'] == true;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      isAvailable ? Icons.check_circle : Icons.cancel,
                      color: isAvailable ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      _days[index],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: isAvailable
                        ? Text(
                            '${dayAvailability['start_time']} - ${dayAvailability['end_time']}',
                          )
                        : const Text('No disponible'),
                    trailing: Switch(
                      value: isAvailable,
                      onChanged: (_) => _toggleDay(index),
                      activeThumbColor: const Color(0xFF1B5E20),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
