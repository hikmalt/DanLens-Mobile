// lib/services/location_service.dart
import 'package:geolocator/geolocator.dart';
import '../utils/error_logger.dart';

class LocationService {
  static Position? _lastPosition;
  static Position? get lastPosition => _lastPosition;

  static Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ErrorLogger.w('Location services disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ErrorLogger.w('Location permission denied');
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        ErrorLogger.w('Location permission permanently denied');
        return null;
      }

      _lastPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      ErrorLogger.i('Got location: ${_lastPosition!.latitude}, ${_lastPosition!.longitude}');
      return _lastPosition;
    } catch (e, stack) {
      ErrorLogger.e('getCurrentPosition failed', e, stack);
      return null;
    }
  }

  static Stream<Position> get positionStream => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
}