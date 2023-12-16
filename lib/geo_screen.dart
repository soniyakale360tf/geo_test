import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class GeoScreen extends StatefulWidget {
  const GeoScreen({Key? key}) : super(key: key);

  @override
  _GeoScreenState createState() => _GeoScreenState();
}

class _GeoScreenState extends State<GeoScreen> {
  StreamSubscription<Position>? _positionStreamSubscription;
  bool positionStreamStarted = false;
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  Position? _currentPosition;

  @override
  void initState() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      _getCurrentLocation();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Colors.grey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _currentPosition.toString(),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  _getCurrentLocation() async {
    _checkPermission();
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
      });
      _uploadLocation(
          latitude: _currentPosition?.latitude.toString(),
          longitude: _currentPosition?.longitude.toString());
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  Future<Position> _checkPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  _uploadLocation({String? latitude, String? longitude}) async {
    final apiUrl = 'https://machinetest.encureit.com/locationapi.php';

    // Create FormData
    var formData = {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };

    try {
      // Send POST request with FormData
      var response = await http.post(
        Uri.parse(apiUrl),
        body: formData,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location data uploaded successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        print('Failed to upload location data. Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading location data: $e');
    }
  }
}
