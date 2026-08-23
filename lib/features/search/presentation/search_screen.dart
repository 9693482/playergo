import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/currency.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/geo_helper.dart';
import '../../location/data/location_service.dart';
import '../../reservations/presentation/create_reservation_screen.dart';
import '../data/search_service.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchService = SearchService();
  final _locationService = LocationService();
  List<Map<String, dynamic>> _sports = [];
  List<Map<String, dynamic>> _positions = [];
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  String? _selectedSportId;
  String? _selectedPositionId;
  double? _maxDistanceKm;
  UserLocation? _userLocation;

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

    var results = await _searchService.searchPlayers(
      sportId: _selectedSportId,
      positionId: _selectedPositionId,
    );

    if (_maxDistanceKm != null && _userLocation != null) {
      results = results.where((player) {
        final lat = (player['latitude'] as num?)?.toDouble();
        final lon = (player['longitude'] as num?)?.toDouble();
        if (lat == null || lon == null) return false;
        return GeoHelper.isWithinRadius(
          centerLat: _userLocation!.latitude,
          centerLon: _userLocation!.longitude,
          pointLat: lat,
          pointLon: lon,
          radiusKm: _maxDistanceKm!,
        );
      }).toList();
    }

    setState(() {
      _results = results;
      _isLoading = false;
      _hasSearched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    _buildFiltersCard(),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildResultsSection(),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(
          bottom: BorderSide(color: AppColors.darkSurfaceVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.darkTextPrimary, size: 24),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Buscar Jugadores',
            style: AppTypography.h2.copyWith(
              color: AppColors.darkTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: AppRadius.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros de busqueda',
            style: AppTypography.subtitle1.copyWith(
              color: AppColors.darkTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Deporte',
            style: AppTypography.body2.copyWith(
              color: AppColors.darkTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceVariant,
              borderRadius: AppRadius.small,
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: DropdownButton<String>(
              value: _selectedSportId,
              isExpanded: true,
              dropdownColor: AppColors.darkSurfaceVariant,
              underline: const SizedBox(),
              hint: Text(
                'Seleccionar deporte',
                style: AppTypography.body1.copyWith(
                  color: AppColors.darkTextSecondary,
                ),
              ),
              items: _sports
                  .map((s) => DropdownMenuItem(
                        value: s['id'] as String,
                        child: Text(
                          s['name'] as String,
                          style: AppTypography.body1.copyWith(
                            color: AppColors.darkTextPrimary,
                          ),
                        ),
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
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Posicion',
            style: AppTypography.body2.copyWith(
              color: AppColors.darkTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceVariant,
              borderRadius: AppRadius.small,
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: DropdownButton<String>(
              value: _selectedPositionId,
              isExpanded: true,
              dropdownColor: AppColors.darkSurfaceVariant,
              underline: const SizedBox(),
              hint: Text(
                'Seleccionar posicion',
                style: AppTypography.body1.copyWith(
                  color: AppColors.darkTextSecondary,
                ),
              ),
              items: _positions
                  .map((p) => DropdownMenuItem(
                        value: p['id'] as String,
                        child: Text(
                          p['name'] as String,
                          style: AppTypography.body1.copyWith(
                            color: AppColors.darkTextPrimary,
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedPositionId = value);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Usar mi ubicacion',
              style: AppTypography.body2.copyWith(
                color: AppColors.darkTextPrimary,
              ),
            ),
            subtitle: Text(
              _userLocation != null
                  ? 'Ubicacion activa (${_maxDistanceKm?.round() ?? 0} km)'
                  : 'Activar para buscar cerca',
              style: AppTypography.caption.copyWith(
                color: AppColors.darkTextSecondary,
              ),
            ),
            value: _userLocation != null,
            onChanged: (value) async {
              if (value) {
                final loc = await _locationService.getCurrentLocation();
                if (loc != null) {
                  setState(() {
                    _userLocation = loc;
                    _maxDistanceKm = 10;
                  });
                }
              } else {
                setState(() {
                  _userLocation = null;
                  _maxDistanceKm = null;
                });
              }
            },
          ),
          if (_userLocation != null) ...[
            Row(
              children: [
                Text(
                  'Radio: ',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.darkTextSecondary,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _maxDistanceKm ?? 10,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    activeColor: AppColors.primary,
                    label: '${_maxDistanceKm?.round() ?? 10} km',
                    onChanged: (value) {
                      setState(() => _maxDistanceKm = value);
                    },
                  ),
                ),
                Text(
                  '${_maxDistanceKm?.round() ?? 10} km',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.darkTextPrimary,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 52,
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
              label: Text(
                'Buscar',
                style: AppTypography.button,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.medium,
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resultados',
          style: AppTypography.subtitle1.copyWith(
            color: AppColors.darkTextPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (!_hasSearched)
          _buildEmptyState(
            icon: Icons.search,
            message: 'Selecciona filtros y presiona buscar',
          )
        else if (_results.isEmpty)
          _buildEmptyState(
            icon: Icons.search_off,
            message: 'No se encontraron jugadores',
          )
        else
          ..._results.map(
            (player) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _PlayerCard(
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
          ),
      ],
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: AppRadius.medium,
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.darkTextSecondary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            style: AppTypography.body1.copyWith(
              color: AppColors.darkTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: AppRadius.medium,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.medium,
        child: InkWell(
          borderRadius: AppRadius.medium,
          onTap: onTap,
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary,
                child: Text(
                  name[0].toUpperCase(),
                  style: AppTypography.h2.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.subtitle1.copyWith(
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: AppTypography.body2.copyWith(
                            color: AppColors.darkTextPrimary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          '$matches partidos',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyInfo.format(price, CurrencyInfo.fromCountryCode('CO')),
                    style: AppTypography.subtitle1.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'por partido',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
