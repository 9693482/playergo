import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';

class TeamProfileScreen extends ConsumerWidget {
  const TeamProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final team = ref.watch(currentTeamProvider);

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
                    backgroundColor: const Color(0xFFE65100),
                    backgroundImage: p.photoUrl != null
                        ? NetworkImage(p.photoUrl!)
                        : null,
                    child: p.photoUrl == null
                        ? const Icon(Icons.group, size: 50, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                team.when(
                  data: (t) {
                    if (t == null) {
                      return Center(
                        child: Column(
                          children: [
                            Text(
                              p.fullName ?? 'Sin nombre',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text('Aún no tienes perfil de equipo'),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {},
                              child: const Text('Crear equipo'),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            t.teamName,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _InfoRow(icon: Icons.group, label: 'Equipo', value: t.teamName),
                                const Divider(),
                                _InfoRow(icon: Icons.person, label: 'Capitán', value: t.captainName ?? '-'),
                                const Divider(),
                                _InfoRow(icon: Icons.phone, label: 'Teléfono', value: t.captainPhone ?? '-'),
                                const Divider(),
                                _InfoRow(icon: Icons.email, label: 'Correo', value: p.email ?? '-'),
                                const Divider(),
                                _InfoRow(
                                  icon: Icons.star,
                                  label: 'Calificación',
                                  value: t.rating.toStringAsFixed(1),
                                ),
                                const Divider(),
                                _InfoRow(
                                  icon: Icons.sports,
                                  label: 'Partidos jugados',
                                  value: t.completedMatches.toString(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (t.description != null && t.description!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Descripción',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(t.description!),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
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

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
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
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
