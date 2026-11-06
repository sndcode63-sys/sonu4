import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Plain-data result of a successful location fetch.
class LocationResult {
  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.capturedAt,
    this.city = '',
    this.state = '',
    this.country = '',
    this.address = '',
    this.pinCode = '',
  });

  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime? capturedAt;

  /// Reverse-geocoded from lat/lng — best-effort, may be empty if the
  /// device couldn't resolve a placemark (no network, unsupported
  /// platform, etc). Never blocks login/registration.
  final String city;
  final String state;
  final String country;
  final String address;
  final String pinCode;

  /// Matches the backend's actual expected shape for the `location` field:
  /// `{ "location": { "longitude": ..., "latitude": ... } }`
  /// (flat lng/lat — NOT the GeoJSON `coordinates.coordinates` array).
  /// Sending the old nested GeoJSON shape was why the backend response
  /// wasn't returning location back.
  Map<String, dynamic> toLocationPayload() => {
    'longitude': longitude,
    'latitude': latitude,
  };

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    if (accuracy != null) 'accuracy': accuracy,
    if (capturedAt != null) 'capturedAt': capturedAt!.toIso8601String(),
    'city': city,
    'state': state,
    'country': country,
    'address': address,
    'pinCode': pinCode,
  };

  factory LocationResult.fromJson(Map<String, dynamic> json) => LocationResult(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    accuracy: (json['accuracy'] as num?)?.toDouble(),
    capturedAt: json['capturedAt'] != null
        ? DateTime.tryParse(json['capturedAt'] as String)
        : null,
    city: json['city'] as String? ?? '',
    state: json['state'] as String? ?? '',
    country: json['country'] as String? ?? '',
    address: json['address'] as String? ?? '',
    pinCode: json['pinCode'] as String? ?? '',
  );

  @override
  String toString() => 'LocationResult(lat: $latitude, lng: $longitude, city: $city)';
}

/// Thrown whenever the location couldn't be captured (services off,
/// permission denied, permission permanently denied, etc). The message is
/// safe to show directly to the user.
class LocationException implements Exception {
  LocationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Wraps `geolocator` with the "ask nicely, fail safely" flow the app
/// needs on the login/registration screens: check that location services
/// are on, request permission if needed, then fetch a single fix.
class LocationService {
  final Geocoding _geocoding = Geocoding();

  /// Opens the system "Allow location access?" dialog if needed and
  /// returns the device's current position, reverse-geocoded into an
  /// address/city/state/country/pinCode where possible.
  ///
  /// Throws a [LocationException] with a user-friendly message if location
  /// can't be obtained — callers on auth screens should treat this as
  /// best-effort and never block login/registration on it.
  Future<LocationResult> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        'Location services are turned off. Please enable them to share your location.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // This is the call that actually pops the native "Allow location
      // access?" dialog the user asked for.
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw LocationException('Location permission was denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Location permission is permanently denied. Enable it from app settings.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    final placemark = await _reverseGeocode(position.latitude, position.longitude);

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      capturedAt: DateTime.now(),
      city: placemark?.city ?? '',
      state: placemark?.state ?? '',
      country: placemark?.country ?? '',
      address: placemark?.address ?? '',
      pinCode: placemark?.pinCode ?? '',
    );
  }

  /// Best-effort reverse geocode. Returns null (never throws) if the
  /// device/platform can't resolve a placemark — city/state/address are
  /// a nice-to-have, not something that should block login/registration.
  Future<_Placemark?> _reverseGeocode(double latitude, double longitude) async {
    try {
      final placemarks = await _geocoding.placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      final addressLine = [p.street, p.subLocality, p.locality]
          .where((s) => s != null && s.trim().isNotEmpty)
          .join(', ');
      return _Placemark(
        city: p.locality ?? p.subAdministrativeArea ?? '',
        state: p.administrativeArea ?? '',
        country: p.country ?? '',
        address: addressLine,
        pinCode: p.postalCode ?? '',
      );
    } catch (_) {
      // No network, unsupported platform, geocoding API unavailable, etc.
      return null;
    }
  }
}

class _Placemark {
  const _Placemark({
    required this.city,
    required this.state,
    required this.country,
    required this.address,
    required this.pinCode,
  });

  final String city;
  final String state;
  final String country;
  final String address;
  final String pinCode;
}