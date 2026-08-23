import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/search_service.dart';
import '../../reservations/presentation/create_reservation_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchService = SearchService();
  List<Map<String, dynamic>> _sports = [];
  List<Map<String, dynamic>> _positions = [];
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  String? _selectedSportId;
  String? _selectedPositionId;

  @override
  void initState() {
    super.initState();
    _loadSports();
  }

  Future<void> _loadSports() async {
    final sports = await _searchService.getSports();
    setState(() => _sports = sports);
  }

  Future<void> _loadPositions(String sportId) async {
    final positions = await _searchService.getPositions(sportId);
    setState(() => _positions = positions);
  }

  Future<void> _search() async {
    setState(() => _isLoading = true);

    final results = await _searchService.searchPlayers(
      sportId: _selectedSportId,
      positionId: _selectedPositionId,
    );

    setState(() {
      _results = results;
      _isLoading = false;
      _hasSearched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Jugadores'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtros de búsqueda',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSportId,
                      decoration: InputDecoration(
                        labelText: 'Deporte',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _sports
                          .map((s) => DropdownMenuItem(
                                value: s['id'] as String,
                                child: Text(s['name'] as String),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSportId = value;
                          _selectedPositionId = null;
                          _positions = [];
                        });
                        if (value != null) _loadPositions(value);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPositionId,
                      decoration: InputDecoration(
                        labelText: 'Posición',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _positions
                          .map((p) => DropdownMenuItem(
                                value: p['id'] as String,
                                child: Text(p['name'] as String),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedPositionId = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _search,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search),
                        label: const Text('Buscar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Resultados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (!_hasSearched)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.search, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Selecciona filtros y presiona buscar',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else if (_results.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No se encontraron jugadores',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._results.map(
                (player) => _PlayerCard(
                  player: player,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateReservationScreen(player: player),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final Map<String, dynamic> player;
  final VoidCallback onTap;

  const _PlayerCard({required this.player, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final profile = player['profiles'] as Map<String, dynamic>?;
    final name = profile?['full_name'] ?? 'Jugador';
    final price = (player['price_per_match'] as num?)?.toDouble() ?? 0;
    final rating = (player['rating'] as num?)?.toDouble() ?? 0;
    final matches = player['completed_matches'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: const Color(0xFF1B5E20),
          child: Text(
            name[0].toUpperCase(),
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.star, size: 14, color: Colors.amber),
            Text(' ${rating.toStringAsFixed(1)}'),
            const SizedBox(width: 12),
            Text('$matches partidos'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
                fontSize: 16,
              ),
            ),
            const Text(
              'por partido',
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
