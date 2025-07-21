import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class ConfirmLocationPage extends StatefulWidget {
  final String currentAddress;
  const ConfirmLocationPage({super.key, required this.currentAddress});

  @override
  _ConfirmLocationPageState createState() => _ConfirmLocationPageState();
}

class _ConfirmLocationPageState extends State<ConfirmLocationPage> {
  Map<String, dynamic>? _selectedLocation;
  String _locationAddress = "Fetching location...";
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  static const String apiKey = "rchX4ibNhBMuC0u0CIt4lRRZPv1YXNnXpoqsytwU";


  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    PermissionStatus permissionStatus = await Permission.location.request();
    if (permissionStatus.isGranted) {
      _getCurrentLocation();
    } else {
      print("Location permission denied");
      setState(() {
        _locationAddress = "Location permission denied";
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String address =
          await _getAddressFromLatLng(position.latitude, position.longitude);

      setState(() {
        _selectedLocation = {
          "latitude": position.latitude,
          "longitude": position.longitude,
        };
        _locationAddress = address;
      });
    } catch (e) {
      print("Error getting current location: $e");
      setState(() {
        _locationAddress = "Location not available";
      });
    }
  }

  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      Placemark place = placemarks.first;
      return "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
    } catch (e) {
      print("Error getting address: $e");
      return "Unknown Location";
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) return;
    try {
      String url =
          "https://api.olamaps.io/places/v1/autocomplete?input=$query&api_key=$apiKey";
      final response = await http.get(Uri.parse(url), headers: {
        "X-Request-Id": DateTime.now().millisecondsSinceEpoch.toString(),
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> suggestions = data["predictions"] ?? [];

        List<Map<String, dynamic>> results = [];

        for (var place in suggestions) {
          String placeId = place["place_id"];
          String detailsUrl =
              "https://api.olamaps.io/places/v1/details?place_id=$placeId&api_key=$apiKey";

          final detailsResponse = await http.get(Uri.parse(detailsUrl));

          if (detailsResponse.statusCode == 200) {
            final detailsData = json.decode(detailsResponse.body);
            double latitude =
                detailsData["result"]["geometry"]["location"]["lat"];
            double longitude =
                detailsData["result"]["geometry"]["location"]["lng"];

            double? distance;
            if (_selectedLocation != null) {
              distance = Geolocator.distanceBetween(
                    _selectedLocation!["latitude"],
                    _selectedLocation!["longitude"],
                    latitude,
                    longitude,
                  ) /
                  1000;
            }

            results.add({
              "name": place["structured_formatting"]["main_text"],
              "address": place["description"],
              "latitude": latitude,
              "longitude": longitude,
              "distance": distance?.toStringAsFixed(2),
            });
          }
        }

        setState(() {
          _searchResults = results;
        });
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching places: $e");
    }
  }

  Future<void> _selectPlace(Map<String, dynamic> place) async {
    setState(() {
      _locationAddress = place['address'];
      _selectedLocation = {
        "latitude": place["latitude"],
        "longitude": place["longitude"],
      };
      _searchResults = [];
    });
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0.0,
        title: Text(
          'Confirm Location',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  hintText: 'Search location',
                  hintStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.grey,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey, width: 1),
                  ),
                ),
                cursorColor: Colors.black,
                cursorWidth: 0.9,
                onChanged: (query) {
                  if (query.isEmpty) {
                    setState(() {
                      _searchResults = [];
                    });
                  } else {
                    _searchPlaces(query);
                  }
                },
              ),
              const SizedBox(height: 20),
              if (_searchResults.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final place = _searchResults[index];
                      return ListTile(
                        title: Text(
                          place['name'] ?? '',
                          style: const TextStyle(fontFamily: 'Poppins'),
                        ),
                        subtitle: Text(
                          place['address'] ?? '',
                          style: const TextStyle(fontFamily: 'Poppins'),
                        ),
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          _selectPlace(place);
                        },
                      );
                    },
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_pin,
                        color: const Color(0xFF1B6FF5),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _locationAddress,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Your current / selected location',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _getCurrentLocation,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF1B6FF5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.my_location, color: Color(0xFF1B6FF5)),
                label: const Text(
                  'Use Current Location',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFF1B6FF5),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedLocation != null &&
                      _locationAddress != "Fetching location...") {
                    Navigator.pop(context, {
                      'address': _locationAddress,
                      'latitude': _selectedLocation!["latitude"],
                      'longitude': _selectedLocation!["longitude"],
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Location is not yet fetched. Please wait.',
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B6FF5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Confirm Location',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}