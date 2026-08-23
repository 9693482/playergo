import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/currency.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/models/enums/enums.dart';
import '../../ratings/presentation/rating_summary_widget.dart';

class PlayerProfileScreen extends ConsumerWidget {
  const PlayerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final player = ref.watch(currentPlayerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {},
          ),
        ],
      ),
      body: profile.when(
        data: (p) {
          if (p == null) return const Center(child: Text('Perfil no encontrado'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF1B5E20),
                    backgroundImage: p.photoUrl != null
                        ? NetworkImage(p.photoUrl!)
                        : null,
                    child: p.photoUrl == null
                        ? Text(
                            (p.fullName ?? 'J')[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 40,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    p.fullName ?? 'Sin nombre',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: p.role == UserRole.player
                          ? Colors.blue[100]
                          : Colors.orange[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      p.role == UserRole.player ? 'JUGADOR' : 'EQUIPO',
                      style: TextStyle(
                        color: p.role == UserRole.player
                            ? Colors.blue[800]
                            : Colors.orange[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                player.when(
                  data: (pl) {
                    if (pl == null) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.sports_soccer, size: 48, color: Colors.grey),
                              const SizedBox(height: 8),
                              const Text('Aún no tienes perfil de jugador'),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {},
                                child: const Text('Completar perfil'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoRow(icon: Icons.email, label: 'Correo', value: p.email ?? '-'),
                            const Divider(),
                            _InfoRow(icon: Icons.phone, label: 'Teléfono', value: p.phone ?? '-'),
                            const Divider(),
                            _InfoRow(
                              icon: Icons.star,
                              label: 'Calificación',
                              value: pl.rating.toStringAsFixed(1),
                            ),
                            const Divider(),
                            _InfoRow(
                              icon: Icons.sports,
                              label: 'Partidos',
                              value: pl.completedMatches.toString(),
                            ),
                            const Divider(),
                            _InfoRow(
                              icon: Icons.attach_money,
                              label: 'Precio/partido',
                              value: CurrencyInfo.format(pl.pricePerMatch, CurrencyInfo.fromCountryCode('CO')),
                            ),
                            const Divider(),
                            _InfoRow(
                              icon: Icons.work,
                              label: 'Experiencia',
                              value: '${pl.experienceYears} años',
                            ),
                            const Divider(),
                            _InfoRow(
                              icon: Icons.circle,
                              label: 'Disponible',
                              value: pl.availabilityStatus ? 'Sí' : 'No',
                              valueColor: pl.availabilityStatus ? Colors.green : Colors.red,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
                if (p.id.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Calificaciones',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  RatingSummaryWidget(userId: p.id),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: TextStyle(color: Colors.grey[600])),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
