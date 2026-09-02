import 'dart:convert';
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

  /// Requests permissions and fetches the current GPS location with reverse geocoded address.
  /// Falls back gracefully to Google Geolocation API & IP Geolocation if native plugin isn't yet compiled.
  Future<LocationDetails?> getCurrentLocationDetails() async {
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
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 10),
            ),
          );
          return await reverseGeocode(position.latitude, position.longitude);
        }
      }
    } on MissingPluginException {
      // Native plugin not compiled yet in running session; fallback to network geolocation
    } catch (_) {
      // Continue to fallback
    }

    // 2. Fallback: Google Geolocation API
    try {
      final googleLoc = await _fetchGoogleGeolocation();
      if (googleLoc != null) {
        return await reverseGeocode(googleLoc['lat']!, googleLoc['lng']!);
      }
    } catch (_) {}

    // 3. Fallback: IP Geolocation API
    try {
      final ipLoc = await _fetchIpGeolocation();
      if (ipLoc != null) {
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
