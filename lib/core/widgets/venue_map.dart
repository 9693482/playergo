import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class VenueMap extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String? venueName;
  final double height;
  final bool interactive;
  final VoidCallback? onTap;

  const VenueMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.venueName,
    this.height = 200,
    this.interactive = true,
    this.onTap,
  });

  @override
  State<VenueMap> createState() => _VenueMapState();
}

class _VenueMapState extends State<VenueMap> {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};

  bool get _hasApiKey => Env.mapsApiKey.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _markers = {
      Marker(
        markerId: MarkerId('venue_${widget.latitude}_${widget.longitude}'),
        position: LatLng(widget.latitude, widget.longitude),
        infoWindow: widget.venueName != null
            ? InfoWindow(title: widget.venueName)
            : InfoWindow.noText,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasApiKey) {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(widget.latitude, widget.longitude),
            zoom: 15,
          ),
          markers: _markers,
          onMapCreated: (controller) => _controller = controller,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: widget.interactive,
          scrollGesturesEnabled: widget.interactive,
          tiltGesturesEnabled: false,
          rotateGesturesEnabled: widget.interactive,
          onTap: widget.onTap != null ? (_) => widget.onTap!() : null,
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.darkSurfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkSurfaceVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.map_outlined,
              size: 48,
              color: AppColors.darkTextSecondary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.venueName ?? 'Ubicación',
              style: AppTypography.subtitle2.copyWith(
                color: AppColors.darkTextPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${widget.latitude.toStringAsFixed(4)}, ${widget.longitude.toStringAsFixed(4)}',
              style: AppTypography.caption.copyWith(
                color: AppColors.darkTextSecondary,
              ),
            ),
            if (!_hasApiKey) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Configure MAPS_API_KEY para ver el mapa',
                style: AppTypography.caption.copyWith(
                  color: AppColors.warning,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

class VenueMapScreen extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? venueName;

  const VenueMapScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    this.venueName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          venueName ?? 'Mapa',
          style: AppTypography.subtitle1.copyWith(
            color: AppColors.darkTextPrimary,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
      ),
      body: VenueMap(
        latitude: latitude,
        longitude: longitude,
        venueName: venueName,
        height: double.infinity,
        interactive: true,
      ),
    );
  }
}
