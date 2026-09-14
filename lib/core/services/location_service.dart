import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class LocationDetails {
  final String formattedAddress;
  final String country;
  final String state;
  final String district;
  final String area;
  final double latitude;
  final double longitude;

  const LocationDetails({
    required this.formattedAddress,
    required this.country,
    required this.state,
    required this.district,
    required this.area,
    required this.latitude,
    required this.longitude,
  });

  @override
  String toString() {
    return 'LocationDetails(area: $area, district: $district, state: $state, country: $country, address: $formattedAddress)';
  }
}

class LocationService {
  static final LocationService instance = LocationService._internal();
  LocationService._internal();

  /// Check and request location permissions
  Future<bool> handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current GPS Position
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await handleLocationPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (_) {
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  /// Reverse geocode coordinates using Google Maps Geocoding API
  Future<LocationDetails?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final apiKey = AppConstants.googleMapsApiKey;
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          final result = data['results'][0];
          final formattedAddress = result['formatted_address'] as String? ?? '';
          final addressComponents = result['address_components'] as List<dynamic>? ?? [];

          String country = 'India';
          String state = '';
          String district = '';
          String area = '';
          String sublocality = '';
          String neighborhood = '';
          String route = '';
          String streetNumber = '';

          for (final comp in addressComponents) {
            final types = List<String>.from(comp['types'] ?? []);
            final longName = comp['long_name'] as String? ?? '';

            if (types.contains('country')) {
              country = longName;
            } else if (types.contains('administrative_area_level_1')) {
              state = longName;
            } else if (types.contains('administrative_area_level_2')) {
              district = longName;
            } else if (types.contains('administrative_area_level_3') && district.isEmpty) {
              district = longName;
            } else if (types.contains('locality') && district.isEmpty) {
              district = longName;
            } else if (types.contains('sublocality_level_1') || types.contains('sublocality')) {
              sublocality = longName;
            } else if (types.contains('neighborhood')) {
              neighborhood = longName;
            } else if (types.contains('route')) {
              route = longName;
            } else if (types.contains('street_number')) {
              streetNumber = longName;
            }
          }

          // Format area and street address
          area = sublocality.isNotEmpty
              ? sublocality
              : (neighborhood.isNotEmpty ? neighborhood : route);

          String detailedLocation = formattedAddress;
          if (detailedLocation.isEmpty) {
            detailedLocation = [streetNumber, route, area, district, state, country]
                .where((s) => s.isNotEmpty)
                .join(', ');
          }

          return LocationDetails(
            formattedAddress: detailedLocation,
            country: country.isNotEmpty ? country : 'India',
            state: state,
            district: district,
            area: area,
            latitude: latitude,
            longitude: longitude,
          );
        }
      }
    } catch (_) {}

    // Fallback if API response or parsing fails
    return LocationDetails(
      formattedAddress: 'Latitude: $latitude, Longitude: $longitude',
      country: 'India',
      state: '',
      district: '',
      area: '',
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Helper to directly fetch current location details (GPS -> Reverse Geocoding)
  Future<LocationDetails?> fetchCurrentLocationDetails() async {
    final pos = await getCurrentPosition();
    if (pos == null) return null;
    return await reverseGeocode(latitude: pos.latitude, longitude: pos.longitude);
  }
}
