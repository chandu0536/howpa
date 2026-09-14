import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/services/location_service.dart';

class MapPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const MapPickerScreen({
    super.key,
    this.initialLat = 17.385044, // Default to Hyderabad
    this.initialLng = 78.486671,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  late LatLng _currentCenter;
  LocationDetails? _selectedDetails;
  bool _isGeocoding = false;
  bool _isLoadingGps = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _currentCenter = LatLng(widget.initialLat, widget.initialLng);
    _initCurrentLocation();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initCurrentLocation() async {
    setState(() => _isLoadingGps = true);
    final pos = await LocationService.instance.getCurrentPosition();
    if (pos != null && mounted) {
      _currentCenter = LatLng(pos.latitude, pos.longitude);
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentCenter, zoom: 16),
        ),
      );
      _fetchAddressForCoordinates(_currentCenter);
    } else {
      _fetchAddressForCoordinates(_currentCenter);
    }
    if (mounted) {
      setState(() => _isLoadingGps = false);
    }
  }

  void _onCameraMove(CameraPosition position) {
    _currentCenter = position.target;
  }

  void _onCameraIdle() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _fetchAddressForCoordinates(_currentCenter);
    });
  }

  Future<void> _fetchAddressForCoordinates(LatLng coords) async {
    if (!mounted) return;
    setState(() => _isGeocoding = true);

    final details = await LocationService.instance.reverseGeocode(
      latitude: coords.latitude,
      longitude: coords.longitude,
    );

    if (mounted) {
      setState(() {
        _selectedDetails = details;
        _isGeocoding = false;
      });
    }
  }

  Future<void> _animateToUserLocation() async {
    setState(() => _isLoadingGps = true);
    final pos = await LocationService.instance.getCurrentPosition();
    if (pos != null && mounted) {
      final target = LatLng(pos.latitude, pos.longitude);
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 16.5),
        ),
      );
      _fetchAddressForCoordinates(target);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not access current GPS location. Please check permissions.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
    if (mounted) {
      setState(() => _isLoadingGps = false);
    }
  }

  void _onConfirmLocation() {
    if (_selectedDetails != null) {
      Navigator.pop(context, _selectedDetails);
    } else {
      // Fallback
      Navigator.pop(
        context,
        LocationDetails(
          formattedAddress: 'Latitude: ${_currentCenter.latitude}, Longitude: ${_currentCenter.longitude}',
          country: 'India',
          state: '',
          district: '',
          area: '',
          latitude: _currentCenter.latitude,
          longitude: _currentCenter.longitude,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Select Location on Map',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Google Map View
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentCenter,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
          ),

          // Center Pin Marker with shadow & animation
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 38.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Text(
                      _isGeocoding ? 'Locating...' : 'Set Location',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.location_on,
                    size: 44,
                    color: Color(0xFFFF5C00),
                  ),
                ],
              ),
            ),
          ),

          // GPS "My Location" Floating Action Button
          Positioned(
            right: 16,
            bottom: 230,
            child: FloatingActionButton(
              heroTag: 'gps_btn',
              onPressed: _isLoadingGps ? null : _animateToUserLocation,
              backgroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: _isLoadingGps
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0052FF)),
                    )
                  : const Icon(Icons.my_location, color: Color(0xFF0052FF)),
            ),
          ),

          // Bottom Address Card & Confirm Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0x1AFF5C00),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.pin_drop_rounded, color: Color(0xFFFF5C00), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedDetails?.area.isNotEmpty == true
                                  ? _selectedDetails!.area
                                  : (_selectedDetails?.district.isNotEmpty == true
                                      ? _selectedDetails!.district
                                      : 'Selected Location'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedDetails != null
                                  ? '${_selectedDetails!.district}, ${_selectedDetails!.state}'
                                  : 'Coordinates: ${_currentCenter.latitude.toStringAsFixed(4)}, ${_currentCenter.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (_isGeocoding)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFF5C00),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      _selectedDetails?.formattedAddress.isNotEmpty == true
                          ? _selectedDetails!.formattedAddress
                          : 'Drag map to pin exact clinic or residential address',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF334155),
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Location Button
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0052FF),
                          Color(0xFFFF5C00),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x260052FF),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isGeocoding ? null : _onConfirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'Confirm Location Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
