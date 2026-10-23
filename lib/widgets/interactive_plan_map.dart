import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/plan_models.dart';
import '../services/maps_service.dart';
import 'plan_image.dart';

/// Interactive OpenStreetMap / GPS Route Map widget with numbered stop pins,
/// route polyline connecting stops, and one-tap "Google Maps Route" & "Apple Maps Route" buttons.
class InteractivePlanMap extends StatefulWidget {
  final PlanTheme theme;
  final List<PlanBlock> locatedBlocks;
  final String title;
  final String subtitle;
  final ValueChanged<PlanBlock>? onSelectStop;

  const InteractivePlanMap({
    super.key,
    required this.theme,
    required this.locatedBlocks,
    required this.title,
    required this.subtitle,
    this.onSelectStop,
  });

  @override
  State<InteractivePlanMap> createState() => _InteractivePlanMapState();
}

class _InteractivePlanMapState extends State<InteractivePlanMap> {
  int? _selectedStopIndex;
  final MapController _mapController = MapController();

  List<PlanBlock> get _stopsWithCoords => widget.locatedBlocks
      .where((b) => b.location != null && b.location!.hasCoordinates)
      .toList();

  LatLng get _initialCenter {
    final stops = _stopsWithCoords;
    if (stops.isEmpty) {
      return const LatLng(35.6585, 139.7022); // Default Tokyo
    }
    double latSum = 0;
    double lngSum = 0;
    for (final s in stops) {
      latSum += s.location!.latitude!;
      lngSum += s.location!.longitude!;
    }
    return LatLng(latSum / stops.length, lngSum / stops.length);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final stops = _stopsWithCoords;
    final allLocations = widget.locatedBlocks
        .map((b) => b.location)
        .whereType<LocationData>()
        .toList();

    final googleRouteUrl =
        MapsService.buildGoogleMapsMultiStopRouteUrl(allLocations);
    final appleRouteUrl = MapsService.buildAppleMapsRouteUrl(allLocations);

    return Container(
      decoration: planCardDecoration(theme),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Map Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(
                bottom: BorderSide(
                  color: theme.textColor.withValues(alpha: 0.12),
                ),
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primaryAccent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.map_rounded,
                        size: 20,
                        color: theme.primaryAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title.isNotEmpty
                                ? widget.title
                                : 'Interactive GPS Itinerary Map',
                            style: planTextStyle(
                              theme,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (widget.subtitle.isNotEmpty)
                            Text(
                              widget.subtitle,
                              style: planTextStyle(
                                theme,
                                fontSize: 12.5,
                                color: theme.textColor.withValues(alpha: 0.68),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Multi-stop GPS route launcher pills
                if (allLocations.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (googleRouteUrl != null)
                        _RouteLauncherChip(
                          label: 'Full Route in Google Maps',
                          icon: Icons.navigation_rounded,
                          backgroundColor: const Color(0xFF1A73E8),
                          textColor: Colors.white,
                          onTap: () => launchUrl(
                            Uri.parse(googleRouteUrl),
                            mode: LaunchMode.externalApplication,
                          ),
                        ),
                      if (appleRouteUrl != null)
                        _RouteLauncherChip(
                          label: 'Apple Maps GPS',
                          icon: Icons.explore_rounded,
                          backgroundColor: const Color(0xFF1C1C1E),
                          textColor: Colors.white,
                          onTap: () => launchUrl(
                            Uri.parse(appleRouteUrl),
                            mode: LaunchMode.externalApplication,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),

          // Interactive Map Viewport
          SizedBox(
            height: 270,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _initialCenter,
                    initialZoom: stops.length <= 1 ? 14.0 : 12.2,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'app.plaans.itinerary',
                    ),
                    if (stops.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: stops
                                .map((b) => LatLng(
                                      b.location!.latitude!,
                                      b.location!.longitude!,
                                    ))
                                .toList(),
                            strokeWidth: 4.0,
                            color: theme.primaryAccent,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: List.generate(stops.length, (index) {
                        final block = stops[index];
                        final loc = block.location!;
                        final isSelected = _selectedStopIndex == index;
                        return Marker(
                          point: LatLng(loc.latitude!, loc.longitude!),
                          width: isSelected ? 46 : 38,
                          height: isSelected ? 46 : 38,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedStopIndex = index);
                              widget.onSelectStop?.call(block);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF141413)
                                    : theme.primaryAccent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),

                // Stop count badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.pin_drop_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${widget.locatedBlocks.length} GPS Stops Pinned',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Selected Stop Floating Overlay Card
                if (_selectedStopIndex != null &&
                    _selectedStopIndex! < stops.length)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: _SelectedStopMapCard(
                      stopNumber: _selectedStopIndex! + 1,
                      block: stops[_selectedStopIndex!],
                      theme: theme,
                      onClose: () => setState(() => _selectedStopIndex = null),
                    ),
                  ),
              ],
            ),
          ),

          // Horizontal Stop Quick-Jump Strip
          if (stops.isNotEmpty)
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: theme.cardColor,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: stops.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final stop = stops[idx];
                  final isSelected = _selectedStopIndex == idx;
                  return Center(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () {
                        setState(() => _selectedStopIndex = idx);
                        _mapController.move(
                          LatLng(
                            stop.location!.latitude!,
                            stop.location!.longitude!,
                          ),
                          14.5,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.primaryAccent
                              : theme.secondaryBackground,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : theme.primaryAccent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${idx + 1}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? theme.primaryAccent
                                      : Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              stop.location!.placeName.isNotEmpty
                                  ? stop.location!.placeName
                                  : stop.title,
                              style: planTextStyle(
                                theme,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : theme.textColor,
                              ),
                            ),
                          ],
                        ),
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

class _RouteLauncherChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  const _RouteLauncherChip({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: textColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedStopMapCard extends StatelessWidget {
  final int stopNumber;
  final PlanBlock block;
  final PlanTheme theme;
  final VoidCallback onClose;

  const _SelectedStopMapCard({
    required this.stopNumber,
    required this.block,
    required this.theme,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final loc = block.location!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF141413), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.primaryAccent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$stopNumber',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  block.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: Color(0xFF141413),
                  ),
                ),
                Text(
                  loc.displayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF57534E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => MapsService.openGoogleMaps(loc),
            icon: const Icon(Icons.directions_rounded, size: 14),
            label: const Text(
              'Google GPS',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 6),
          TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF1C1C1E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => MapsService.openAppleMaps(loc),
            icon: const Icon(Icons.apple, size: 14),
            label: const Text(
              'Apple GPS',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 16, color: Color(0xFF141413)),
          ),
        ],
      ),
    );
  }
}
