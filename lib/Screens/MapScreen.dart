import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'SingleGemScreen.dart';
import 'EditGemScreen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapScreen extends StatefulWidget {
  final String userId;
  final String idToken;

  const MapScreen({
    super.key,
    required this.userId,
    required this.idToken
    });

  @override
  State<MapScreen> createState() => _MapScreenState();
}


class _MapScreenState extends State<MapScreen> {
  Set<Marker> _gemMarkers = {};
  Set<Marker> _tapMarker = {};
  Map<String, dynamic> gemData = {};

  Color selectedColor = Colors.grey;
  double? _latitude;
  double? _longitude;

  final String databaseUrl = dotenv.get('DATA_BASE_URL');

  late GoogleMapController _mapController;
  bool _locationEnabled = false;
  Position? _currentPosition;
  
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(56.1625, 15.5801),
    zoom: 11.5,
    );

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permission denied
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permission permanently denied
      return;
    }

    // Permission granted - enable location
    setState(() {
      _locationEnabled = true;
    });

    // Get current position and move camera
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentPosition = position;
      });

      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15.0,
        ),
      );
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  void _loadGems() async {
    final url = Uri.parse('$databaseUrl/Users/${widget.userId}/Gems.json?auth=${widget.idToken}');
    final response = await http.get(url);

    print("Loading gems... Status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("Found ${data?.length ?? 0} gems in database");

      if(data != null && data is Map<String, dynamic>) {
        createMarkersFromMap(data);
        setState(() {
                gemData = data;
              });
      } else {
        print("No gems found or invalid data format");
        tutorial();
        setState(() {
        gemData = {};
      });
      }
    } else {
      print("Failed to load gems: ${response.body}");

      setState(() {
        gemData = {};
      });
    }
  }

  void tutorial() {
    print("No gems where found so is displaying Tutorial.");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Gems!!'),
        content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'To add a Gem click on the Map and a pin will appear. \n'
          ),
          Text(
            'Then you click on Save Location. \nFill in Name and Description and click Save Gem.'
          ),
          Text(
            '\nYou can later add Pictures to your Gems.'
          )
        ],
        ),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ]
      )
    );
  }

  void createMarkersFromMap(Map<String, dynamic> gemsData) {
    print("Creating markers from map data: $gemsData");
    
    Set<Marker> newMarkers = {};
    
    gemsData.forEach((gemId, gemData) {
      if (gemData != null) {
        final double lat = (gemData['Latitude']);
        final double lng = (gemData['Longitude']);
        
        newMarkers.add(Marker(
          markerId: MarkerId(gemId),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: gemData['Name'],
            onTap: () {
            print("Tapped on gem: ${gemData['Name']}");
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SingleGemScreen(
                  userId: widget.userId,
                  idToken: widget.idToken,
                  gemName: gemData['Name'],
                  description: gemData['Decoration']?.toString() ?? "No Description",
                  lat: lat,
                  lng: lng,
                  image: gemData['Image'],
                  index : 0,
                ),
              ),
            );
          },
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet), // Here you can change the color of the gems.
        ));
      }
    });

    print("Created ${newMarkers.length} markers");
    setState(() {
      _gemMarkers = newMarkers;
      print("Markers set updated with ${_gemMarkers.length} markers");
    });
  }

  @override
    Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            zoomControlsEnabled: true,
            initialCameraPosition: _initialCameraPosition,
            myLocationEnabled: _locationEnabled,
            myLocationButtonEnabled: true,
            markers: _gemMarkers.union(_tapMarker),
            onTap: (LatLng latLng) {
              setState(() {
                _latitude = latLng.latitude;
                _longitude = latLng.longitude;
                selectedColor = Colors.blue;
                _tapMarker = {
                Marker(
                  markerId: MarkerId('selected_location'),
                  position: latLng,
                  icon: BitmapDescriptor.defaultMarker,
                  infoWindow: InfoWindow(title: "Current"),
                ),
              };
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FilledButton.icon(
                onPressed: () => {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditScreen(
                        userId: widget.userId,
                        idToken: widget.idToken,
                        lat: _latitude,
                        lng: _longitude,
                        index: 0,
                      ),
                    ),
                  )
                },
              icon: const Icon(Icons.location_on),
              label: const Text('Save Location'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: selectedColor,
              ),
            ),
          ))
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadGems();
    _checkLocationPermission();
  }
}
