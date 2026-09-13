import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:howpa_nurse/core/env.dart';

class LocationDetails {
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String area;
  final String city;
  final String district;
  final String state;
  final String country;
  final String pincode;

  LocationDetails({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    required this.area,
    required this.city,
    required this.district,
    required this.state,
    required this.country,
    required this.pincode,
  });

  factory LocationDetails.empty() {
    return LocationDetails(
      latitude: 0.0,
      longitude: 0.0,
      formattedAddress: '',
      area: '',
      city: '',
      district: '',
      state: '',
      country: '',
      pincode: '',
    );
  }
}

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Position? _lastKnownPosition;
  LocationDetails? _cachedLocationDetails;

  /// Default distance filter in meters to prevent GPS jitter and excessive battery/CPU consumption
  static const int defaultDistanceFilterMeters = 10;

  /// Creates platform-optimized LocationSettings with distance filter
  LocationSettings getLocationSettings({
    int distanceFilter = defaultDistanceFilterMeters,
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) {
    if (kIsWeb) {
      return LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      );
    }

    try {
      if (Platform.isAndroid) {
        return AndroidSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
          intervalDuration: const Duration(seconds: 10),
          timeLimit: const Duration(seconds: 15),
        );
      } else if (Platform.isIOS || Platform.isMacOS) {
        return AppleSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
          pauseLocationUpdatesAutomatically: true,
          timeLimit: const Duration(seconds: 15),
        );
      }
    } catch (_) {}

    return LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
      timeLimit: const Duration(seconds: 15),
    );
  }

  /// Returns a filtered stream of position updates that only emits when moving >= distanceFilter meters.
  Stream<Position> getPositionStream({
    int distanceFilter = defaultDistanceFilterMeters,
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) {
    final settings = getLocationSettings(
      distanceFilter: distanceFilter,
      accuracy: accuracy,
    );

    return Geolocator.getPositionStream(locationSettings: settings).where((pos) {
      if (_lastKnownPosition == null) {
        _lastKnownPosition = pos;
        return true;
      }
      final distance = Geolocator.distanceBetween(
        _lastKnownPosition!.latitude,
        _lastKnownPosition!.longitude,
        pos.latitude,
        pos.longitude,
      );

      if (distance >= distanceFilter) {
        _lastKnownPosition = pos;
        return true;
      }
      return false;
    });
  }

  /// Requests permissions and fetches the current GPS location with reverse geocoded address.
  /// Falls back gracefully to Google Geolocation API & IP Geolocation if native plugin isn't yet compiled.
  Future<LocationDetails?> getCurrentLocationDetails({bool forceRefresh = false}) async {
    // 1. Try Native Device GPS
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
      }

      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: getLocationSettings(
              distanceFilter: defaultDistanceFilterMeters,
              accuracy: LocationAccuracy.high,
            ),
          );

          if (!forceRefresh &&
              _cachedLocationDetails != null &&
              _lastKnownPosition != null) {
            final distance = Geolocator.distanceBetween(
              _lastKnownPosition!.latitude,
              _lastKnownPosition!.longitude,
              position.latitude,
              position.longitude,
            );
            if (distance < defaultDistanceFilterMeters) {
              return _cachedLocationDetails;
            }
          }

          _lastKnownPosition = position;
          final details = await reverseGeocode(position.latitude, position.longitude);
          _cachedLocationDetails = details;
          return details;
        }
      }
    } on MissingPluginException {
      // Native plugin not compiled yet in running session; fallback to network geolocation
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Native location check notice: $e');
      }
    }

    // 2. Fallback: Google Geolocation API
    try {
      final googleLoc = await _fetchGoogleGeolocation();
      if (googleLoc != null) {
        final details = await reverseGeocode(googleLoc['lat']!, googleLoc['lng']!);
        _cachedLocationDetails = details;
        return details;
      }
    } catch (_) {}

    // 3. Fallback: IP Geolocation API
    try {
      final ipLoc = await _fetchIpGeolocation();
      if (ipLoc != null) {
        _cachedLocationDetails = ipLoc;
        return ipLoc;
      }
    } catch (_) {}

    return null;
  }

  /// Google Geolocation API fallback
  Future<Map<String, double>?> _fetchGoogleGeolocation() async {
    final url = Uri.parse(
      'https://www.googleapis.com/geolocation/v1/geolocate?key=${Env.googleMapsApiKey}',
    );
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({}),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final location = data['location'];
      if (location != null) {
        final lat = (location['lat'] as num).toDouble();
        final lng = (location['lng'] as num).toDouble();
        return {'lat': lat, 'lng': lng};
      }
    }
    return null;
  }

  /// IP Geolocation fallback
  Future<LocationDetails?> _fetchIpGeolocation() async {
    final url = Uri.parse('https://ipapi.co/json/');
    final response = await http.get(url).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final lat = (data['latitude'] as num?)?.toDouble() ?? 17.4483;
      final lng = (data['longitude'] as num?)?.toDouble() ?? 78.3814;
      final city = data['city']?.toString() ?? 'Hyderabad';
      final region = data['region']?.toString() ?? 'Telangana';
      final country = data['country_name']?.toString() ?? 'India';
      final postal = data['postal']?.toString() ?? '';

      return LocationDetails(
        latitude: lat,
        longitude: lng,
        formattedAddress: '$city, $region, $country $postal'.trim(),
        area: city,
        city: city,
        district: city,
        state: region,
        country: country,
        pincode: postal,
      );
    }
    return null;
  }

  /// Reverse geocodes coordinates via Google Maps Geocoding API
  Future<LocationDetails> reverseGeocode(double lat, double lng) async {
    String formattedAddress = '';
    String area = '';
    String city = '';
    String district = '';
    String state = '';
    String country = 'India';
    String pincode = '';

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=${Env.googleMapsApiKey}',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          final firstResult = data['results'][0];
          formattedAddress = firstResult['formatted_address'] ?? '';

          final addressComponents = firstResult['address_components'] as List<dynamic>? ?? [];
          for (var comp in addressComponents) {
            final types = (comp['types'] as List<dynamic>? ?? []).cast<String>();
            final longName = comp['long_name'] as String? ?? '';

            if (types.contains('sublocality') ||
                types.contains('sublocality_level_1') ||
                types.contains('neighborhood')) {
              if (area.isEmpty) area = longName;
            } else if (types.contains('locality')) {
              city = longName;
            } else if (types.contains('administrative_area_level_2') ||
                types.contains('administrative_area_level_3')) {
              district = longName;
            } else if (types.contains('administrative_area_level_1')) {
              state = longName;
            } else if (types.contains('country')) {
              country = longName;
            } else if (types.contains('postal_code')) {
              pincode = longName;
            }
          }

          if (district.isEmpty && city.isNotEmpty) {
            district = city;
          }
          if (city.isEmpty && district.isNotEmpty) {
            city = district;
          }
        }
      }
    } catch (_) {
      // Fallback
    }

    if (formattedAddress.isEmpty) {
      formattedAddress = '$lat, $lng';
    }

    return LocationDetails(
      latitude: lat,
      longitude: lng,
      formattedAddress: formattedAddress,
      area: area,
      city: city,
      district: district,
      state: state,
      country: country,
      pincode: pincode,
    );
  }
}
