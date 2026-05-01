import 'package:geolocator/geolocator.dart';

/// Wraps the `geolocator` plugin so screens don't have to deal with the
/// permission request flow directly.
///
/// All public methods either return a usable [Position]/[double] or throw a
/// [LocationException] with a user-readable message that the UI can show in
/// a snackbar / inline banner.
class LocationService {
  /// Returns the device's current position, requesting permission if
  /// necessary. Throws [LocationException] when:
  ///   * Location services are off on the device,
  ///   * The user denied permission, or
  ///   * The permission was permanently denied (we cannot re-prompt).
  Future<Position> getCurrentPosition() async {
    final servicesEnabled = await Geolocator.isLocationServiceEnabled();
    if (!servicesEnabled) {
      throw const LocationException(
        'Location services are turned off. Please enable them in your '
        'phone settings to see clinics near you.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Location permission is permanently denied. Please enable it in '
        'app settings to see nearby clinics.',
      );
    }

    if (permission == LocationPermission.denied) {
      throw const LocationException(
        'Location permission was denied. We need it to find clinics near '
        'you.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );
  }

  /// Distance between two coordinates, in meters. Wraps Geolocator's
  /// helper so callers don't have to import the plugin.
  double distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}

/// Thrown when we cannot obtain a usable location for the user. The
/// [message] is intentionally user-readable so the UI can display it
/// directly.
class LocationException implements Exception {
  final String message;
  const LocationException(this.message);

  @override
  String toString() => message;
}
