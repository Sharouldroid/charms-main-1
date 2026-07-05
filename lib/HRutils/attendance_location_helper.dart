import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

// Reads the device GPS position, formatted as "lat, lng".
Future<String?> getCurrentLocationString() async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    return '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
  } catch (e) {
    return null;
  }
}

// Reverse geocodes coordinates to a human-readable place name (Nominatim).
Future<String?> getPlaceName(double lat, double lng) async {
  try {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json',
    );
    final response = await http.get(url, headers: {'User-Agent': 'charms-app'});
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['display_name'];
    }
  } catch (_) {}
  return null;
}

// Resolves the current GPS coordinates into a display string of
// "Place name\n(lat, lng)", falling back to just coordinates if the
// place name can't be resolved, or null if location can't be read at all.
Future<String?> resolveDisplayLocation() async {
  final locationStr = await getCurrentLocationString();
  if (locationStr == null) return null;

  final parts = locationStr.split(', ');
  if (parts.length == 2) {
    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);
    if (lat != null && lng != null) {
      final placeName = await getPlaceName(lat, lng);
      if (placeName != null) {
        return '$placeName\n($locationStr)';
      }
    }
  }
  return locationStr;
}
