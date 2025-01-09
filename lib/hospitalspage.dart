import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Hospital {
  final String name;
  final String address;
  final String phone;
  final LatLng location;
  final double distance; // Distance from user in meters

  Hospital({
    required this.name,
    required this.address,
    required this.phone,
    required this.location,
    this.distance = 0,
  });
}

class HospitalsPage extends StatefulWidget {
  @override
  _HospitalsPageState createState() => _HospitalsPageState();
}

class _HospitalsPageState extends State<HospitalsPage> {
  final MapController _mapController = MapController();
  final double searchRadius = 5000; // 5km radius

  // Remove the hardcoded list and make it dynamic
  List<Hospital> hospitals = [];

  // Add loading state for hospitals
  bool _isLoadingHospitals = true;

  // Center on Tagbilaran City, Bohol
  final LatLng _center = LatLng(9.6474, 123.8535);

  // Add selected hospital state
  Hospital? _selectedHospital;

  // Add location state
  LatLng? _currentLocation;
  bool _isLoadingLocation = true;

  Future<void> _findNearbyHospitals(LatLng userLocation) async {
    setState(() {
      _isLoadingHospitals = true;
    });

    try {
      // Modified query to include more hospital-related tags
      final query = '''
        [out:json][timeout:25];
        (
          node["amenity"="hospital"](around:${searchRadius.toInt()},${userLocation.latitude},${userLocation.longitude});
          node["healthcare"="hospital"](around:${searchRadius.toInt()},${userLocation.latitude},${userLocation.longitude});
          way["amenity"="hospital"](around:${searchRadius.toInt()},${userLocation.latitude},${userLocation.longitude});
          way["healthcare"="hospital"](around:${searchRadius.toInt()},${userLocation.latitude},${userLocation.longitude});
          relation["amenity"="hospital"](around:${searchRadius.toInt()},${userLocation.latitude},${userLocation.longitude});
          relation["healthcare"="hospital"](around:${searchRadius.toInt()},${userLocation.latitude},${userLocation.longitude});
        );
        out body center;
        >;
        out skel qt;
      ''';

      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: query,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Hospital> nearbyHospitals = [];

        for (var element in data['elements']) {
          // Get coordinates based on element type
          double lat, lon;
          if (element['type'] == 'node') {
            lat = element['lat'].toDouble();
            lon = element['lon'].toDouble();
          } else if (element['type'] == 'way' ||
              element['type'] == 'relation') {
            // For ways and relations, use the center coordinates
            if (element['center'] != null) {
              lat = element['center']['lat'].toDouble();
              lon = element['center']['lon'].toDouble();
            } else {
              continue; // Skip if no coordinates available
            }
          } else {
            continue; // Skip unknown types
          }

          LatLng hospitalLocation = LatLng(lat, lon);

          // Calculate distance between user and hospital
          double distanceInMeters = Geolocator.distanceBetween(
            userLocation.latitude,
            userLocation.longitude,
            hospitalLocation.latitude,
            hospitalLocation.longitude,
          );

          // Get hospital details from tags
          var tags = element['tags'] ?? {};
          String name = tags['name'] ?? 'Unknown Hospital';
          String phone = tags['phone'] ?? tags['contact:phone'] ?? 'N/A';
          String address = tags['addr:full'] ??
              [tags['addr:street'], tags['addr:housenumber'], tags['addr:city']]
                  .where((s) => s != null)
                  .join(', ') ??
              'Address not available';

          nearbyHospitals.add(Hospital(
            name: name,
            address: address,
            phone: phone,
            location: hospitalLocation,
            distance: distanceInMeters,
          ));
        }

        // Sort hospitals by distance
        nearbyHospitals.sort((a, b) => a.distance.compareTo(b.distance));

        setState(() {
          hospitals = nearbyHospitals;
          _isLoadingHospitals = false;
        });

        // Debug print
        print('Found ${nearbyHospitals.length} hospitals');
        for (var hospital in nearbyHospitals) {
          print('Hospital: ${hospital.name} at ${hospital.location}');
        }
      } else {
        print('Failed to fetch hospitals: ${response.statusCode}');
        setState(() {
          _isLoadingHospitals = false;
        });
      }
    } catch (e) {
      print('Error finding nearby hospitals: $e');
      setState(() {
        _isLoadingHospitals = false;
      });
    }
  }

  Future<void> _initializeLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final userLocation = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _currentLocation = userLocation;
          _isLoadingLocation = false;
        });

        // Find nearby hospitals once we have the user's location
        await _findNearbyHospitals(userLocation);
      }
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _openDirections(Hospital hospital) async {
    if (_currentLocation == null) return;

    // Create Google Maps URL
    final url = 'https://www.google.com/maps/dir/?api=1'
        '&origin=${_currentLocation!.latitude},${_currentLocation!.longitude}'
        '&destination=${hospital.location.latitude},${hospital.location.longitude}'
        '&travelmode=driving';

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // If Google Maps app is not installed, open in browser
      final browserUrl = 'https://www.google.com/maps/search/?api=1'
          '&query=${hospital.location.latitude},${hospital.location.longitude}';
      final browserUri = Uri.parse(browserUrl);
      if (await canLaunchUrl(browserUri)) {
        await launchUrl(browserUri, mode: LaunchMode.externalApplication);
      } else {
        print('Could not launch maps');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  Widget build(BuildContext context) {
    print('Building with location: $_currentLocation');
    print('Loading status: $_isLoadingLocation');

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hospitals Nearby',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isLoadingHospitals)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                    )
                  else
                    Text(
                      '${hospitals.length} results',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),

            // Map
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentLocation ?? _center,
                      initialZoom: 14.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                      ),
                      MarkerLayer(
                        markers: _isLoadingHospitals
                            ? [] // Don't show markers while loading
                            : [
                                // Current location marker
                                if (_currentLocation != null)
                                  Marker(
                                    point: _currentLocation!,
                                    width: 60,
                                    height: 60,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.4),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.blue,
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                // Hospital markers
                                ...hospitals.map((hospital) => Marker(
                                      point: hospital.location,
                                      width: 40,
                                      height: 40,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedHospital = hospital;
                                          });
                                        },
                                        child: Icon(
                                          Icons.local_hospital,
                                          color: _selectedHospital == hospital
                                              ? Color(0xFF4CAF50)
                                              : Colors.red,
                                          size: 40,
                                        ),
                                      ),
                                    )),
                              ],
                      ),
                    ],
                  ),

                  // Show loading indicator while getting location
                  if (_isLoadingLocation)
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text('Getting your location...'),
                          ],
                        ),
                      ),
                    ),

                  // Hospital Details Card
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _isLoadingHospitals
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 8),
                                    Text('Finding nearby hospitals...'),
                                  ],
                                ),
                              )
                            : _selectedHospital != null
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedHospital!.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        _selectedHospital!.address,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        _selectedHospital!.phone,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () => _openDirections(
                                              _selectedHospital!),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xFF4CAF50),
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                                vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Text('Get directions'),
                                        ),
                                      ),
                                    ],
                                  )
                                : Center(
                                    child: Text(
                                      'Select a hospital to see details',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _currentLocation != null
          ? FloatingActionButton(
              onPressed: () {
                _mapController.move(_currentLocation!, 15.0);
              },
              backgroundColor: Colors.blue,
              child: Icon(Icons.my_location),
            )
          : null,
    );
  }
}
