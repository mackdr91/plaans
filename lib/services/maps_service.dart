import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/plan_models.dart';

/// Service for Google Maps & Apple Maps GPS deep-linking, multi-stop routes, and geocoding lookup.
class MapsService {
  /// Launches Google Maps (Search/Pin or GPS Turn-by-Turn Directions)
  static Future<bool> openGoogleMaps(
    LocationData location, {
    bool directions = true,
  }) async {
    final urlString = directions
        ? location.googleMapsDirectionsUrl
        : location.googleMapsSearchUrl;
    final uri = Uri.parse(urlString);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Launches Apple Maps (Search/Pin or GPS Turn-by-Turn Directions)
  static Future<bool> openAppleMaps(
    LocationData location, {
    bool directions = true,
  }) async {
    final urlString =
        directions ? location.appleMapsDirectionsUrl : location.appleMapsSearchUrl;
    final uri = Uri.parse(urlString);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Generates a multi-stop Google Maps route URL for an entire day or itinerary
  static String? buildGoogleMapsMultiStopRouteUrl(List<LocationData> locations) {
    final valid = locations.where((l) => l.isNotEmpty).toList();
    if (valid.isEmpty) return null;
    if (valid.length == 1) return valid.first.googleMapsDirectionsUrl;

    String encodeLoc(LocationData loc) {
      if (loc.hasCoordinates) {
        return '${loc.latitude},${loc.longitude}';
      }
      return [loc.placeName.trim(), loc.address.trim()]
          .where((s) => s.isNotEmpty)
          .join(', ');
    }

    final origin = Uri.encodeComponent(encodeLoc(valid.first));
    final destination = Uri.encodeComponent(encodeLoc(valid.last));

    if (valid.length == 2) {
      return 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&travelmode=driving';
    }

    final waypoints = valid
        .sublist(1, valid.length - 1)
        .map((l) => Uri.encodeComponent(encodeLoc(l)))
        .join('%7C');

    return 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&waypoints=$waypoints&travelmode=driving';
  }

  /// Generates an Apple Maps multi-stop / destination route URL
  static String? buildAppleMapsRouteUrl(List<LocationData> locations) {
    final valid = locations.where((l) => l.isNotEmpty).toList();
    if (valid.isEmpty) return null;
    if (valid.length == 1) return valid.first.appleMapsDirectionsUrl;

    String encodeLoc(LocationData loc) {
      if (loc.hasCoordinates) {
        return '${loc.latitude},${loc.longitude}';
      }
      return [loc.placeName.trim(), loc.address.trim()]
          .where((s) => s.isNotEmpty)
          .join(', ');
    }

    final saddr = Uri.encodeComponent(encodeLoc(valid.first));
    final daddr = Uri.encodeComponent(encodeLoc(valid.last));
    return 'https://maps.apple.com/?saddr=$saddr&daddr=$daddr&dirflg=d';
  }

  /// Curated instant landmarks for zero-latency autocomplete & offline resilience
  static const List<LocationData> curatedLandmarks = [
    LocationData(
      placeName: 'Shibuya Sky Observation Deck',
      address: '2-24-12 Shibuya, Tokyo 150-6145, Japan',
      latitude: 35.6585,
      longitude: 139.7022,
    ),
    LocationData(
      placeName: 'Tsukiji Outer Market',
      address: '4 Chome-16-2 Tsukiji, Chuo City, Tokyo, Japan',
      latitude: 35.6655,
      longitude: 139.7707,
    ),
    LocationData(
      placeName: 'teamLab Planets TOKYO',
      address: '6 Chome-1-16 Toyosu, Koto City, Tokyo, Japan',
      latitude: 35.6491,
      longitude: 139.7898,
    ),
    LocationData(
      placeName: 'Balthazar Brasserie',
      address: '80 Spring St, SoHo, New York, NY 10012',
      latitude: 40.7226,
      longitude: -73.9982,
    ),
    LocationData(
      placeName: 'The Whitney Museum of American Art',
      address: '99 Gansevoort St, New York, NY 10014',
      latitude: 40.7396,
      longitude: -74.0089,
    ),
    LocationData(
      placeName: 'Dante NYC Cocktail Bar',
      address: '79-81 MacDougal St, Greenwich Village, NY 10012',
      latitude: 40.7288,
      longitude: -74.0016,
    ),
    LocationData(
      placeName: 'Positano Spiaggia Grande',
      address: 'Via del Brigantino, 84017 Positano SA, Italy',
      latitude: 40.6281,
      longitude: 14.4850,
    ),
    LocationData(
      placeName: 'Villa Cimbrone Gardens',
      address: 'Via Santa Chiara 26, 84010 Ravello SA, Italy',
      latitude: 40.6433,
      longitude: 14.6114,
    ),
    LocationData(
      placeName: 'Eiffel Tower (Tour Eiffel)',
      address: 'Champ de Mars, 5 Av. Anatole France, 75007 Paris, France',
      latitude: 48.8584,
      longitude: 2.2945,
    ),
    LocationData(
      placeName: 'Golden Gate Bridge Vista Point',
      address: 'San Francisco, CA 94129',
      latitude: 37.8199,
      longitude: -122.4783,
    ),
  ];

  /// Searches for places and resolves GPS coordinates using OpenStreetMap Nominatim + curated presets
  static Future<List<LocationData>> searchPlaces(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return curatedLandmarks.take(5).toList();

    final lower = trimmed.toLowerCase();
    final localMatches = curatedLandmarks
        .where((l) =>
            l.placeName.toLowerCase().contains(lower) ||
            l.address.toLowerCase().contains(lower))
        .toList();

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&limit=5&q=${Uri.encodeComponent(trimmed)}',
      );
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        final remoteMatches = data.map((item) {
          final map = item as Map<String, dynamic>;
          final displayName = map['display_name'] as String? ?? trimmed;
          final parts = displayName.split(',');
          final name = parts.first.trim();
          final addr = parts.length > 1
              ? parts.sublist(1).map((e) => e.trim()).join(', ')
              : displayName;
          final lat = double.tryParse(map['lat']?.toString() ?? '');
          final lon = double.tryParse(map['lon']?.toString() ?? '');
          return LocationData(
            placeName: name,
            address: addr,
            latitude: lat,
            longitude: lon,
          );
        }).toList();

        return [...localMatches, ...remoteMatches];
      }
    } catch (_) {
      // Fallback gracefully to local matches if offline or CORS restricted
    }

    return localMatches;
  }
}
