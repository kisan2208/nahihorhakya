import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Real-time high-precision Geotag metadata package with Google Maps location support.
class GeotagData {
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracyMeters;
  final String formattedGoogleAddress;
  final String streetAddress;
  final String locality;
  final String city;
  final String state;
  final String country;
  final String postalCode;
  final DateTime timestamp;
  final String timeZoneName;
  final String timeZoneOffset;
  final bool isRealHardwareGPS;

  const GeotagData({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracyMeters,
    this.formattedGoogleAddress = '',
    required this.streetAddress,
    required this.locality,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
    required this.timestamp,
    required this.timeZoneName,
    required this.timeZoneOffset,
    this.isRealHardwareGPS = false,
  });

  /// High precision Lat/Lng string formatted to 6 decimal places (~0.11m precision).
  String get formattedCoordinates {
    final latDir = latitude >= 0 ? 'N' : 'S';
    final lngDir = longitude >= 0 ? 'E' : 'W';
    return '${latitude.abs().toStringAsFixed(6)}° $latDir, ${longitude.abs().toStringAsFixed(6)}° $lngDir';
  }

  /// Line 1 of street address (House No + Street + Locality/Sublocality)
  String get addressLine1 {
    final parts = <String>[
      if (streetAddress.isNotEmpty) streetAddress,
      if (locality.isNotEmpty && locality != streetAddress && locality != city)
        locality,
    ];
    // Return empty if no real data — never return hardcoded fake addresses
    return parts.isNotEmpty ? parts.join(', ') : city;
  }

  /// Line 2 of street address (City, State Pincode, Country)
  String get addressLine2 {
    final parts = <String>[
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (postalCode.isNotEmpty) postalCode,
      if (country.isNotEmpty) country,
    ];
    return parts.join(', ').trim();
  }

  /// Full Google Maps formatted street address for geotag watermark stamp.
  String get fullFormattedAddress {
    if (formattedGoogleAddress.isNotEmpty) return formattedGoogleAddress;
    final parts = <String>[
      if (streetAddress.isNotEmpty) streetAddress,
      if (locality.isNotEmpty) locality,
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (postalCode.isNotEmpty) postalCode,
      if (country.isNotEmpty) country,
    ];
    return parts.isNotEmpty ? parts.join(', ') : formattedCoordinates;
  }

  /// Formatted date and time with local timezone offset.
  String get formattedDateTime {
    final day = timestamp.day.toString().padLeft(2, '0');
    final month = _monthName(timestamp.month);
    final year = timestamp.year;
    final hour = timestamp.hour > 12
        ? timestamp.hour - 12
        : (timestamp.hour == 0 ? 12 : timestamp.hour);
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final second = timestamp.second.toString().padLeft(2, '0');
    final amPm = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$day $month $year • ${hour.toString().padLeft(2, '0')}:$minute:$second $amPm ($timeZoneOffset)';
  }

  static String _monthName(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[(m - 1) % 12];
  }

  static GeotagData defaultFallback({double lat = 0.0, double lng = 0.0}) {
    final now = DateTime.now();
    final tzOffset = _formatTzOffsetStatic(now.timeZoneOffset);
    return GeotagData(
      latitude: lat,
      longitude: lng,
      altitude: 0.0,
      accuracyMeters: 0.0,
      formattedGoogleAddress: '',
      streetAddress: '',
      locality: '',
      city: '',
      state: '',
      country: '',
      postalCode: '',
      timestamp: now,
      timeZoneName: now.timeZoneName,
      timeZoneOffset: tzOffset,
      isRealHardwareGPS: false,
    );
  }

  /// Preserves the cached GPS/address lookup but updates the timestamp at the
  /// exact moment the shutter is pressed.
  GeotagData withCaptureTimestamp(DateTime capturedAt) {
    return GeotagData(
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      accuracyMeters: accuracyMeters,
      formattedGoogleAddress: formattedGoogleAddress,
      streetAddress: streetAddress,
      locality: locality,
      city: city,
      state: state,
      country: country,
      postalCode: postalCode,
      timestamp: capturedAt,
      timeZoneName: capturedAt.timeZoneName,
      timeZoneOffset: _formatTzOffsetStatic(capturedAt.timeZoneOffset),
      isRealHardwareGPS: isRealHardwareGPS,
    );
  }

  static String _formatTzOffsetStatic(Duration offset) {
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final sign = offset.isNegative ? '-' : '+';
    return 'UTC$sign$hours:$minutes';
  }
}

/// Service managing location permissions, hardware GPS, and reverse geocoding.
class GeotagService {
  /// Explicitly requests location permission from Android OS.
  Future<bool> requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await Geolocator.openLocationSettings();
        if (!serviceEnabled) return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return false;
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Captures real-time accurate location and reverse-geocodes address.
  /// Uses geocode.maps.co as primary geocoding API for detailed street addresses.
  Future<GeotagData> captureRealGeotag({
    double? forcedLat,
    double? forcedLng,
    String? googleApiKey,
    bool requestPermission = true,
  }) async {
    // ── Geocode.maps.co API key — loaded securely from build environment ────────
    // Local build:  flutter build apk --dart-define=MAPS_CO_API_KEY=your_key_here
    // GitHub CI:    set via repository secret MAPS_CO_API_KEY (see .github/workflows)
    const mapsCoApiKey = String.fromEnvironment(
      'MAPS_CO_API_KEY',
      defaultValue: '',
    );

    final now = DateTime.now();
    final tzOffset = _formatTzOffset(now.timeZoneOffset);
    final tzName = now.timeZoneName;

    double lat = forcedLat ?? 0.0;
    double lng = forcedLng ?? 0.0;
    double altitude = 0.0;
    double accuracy = 0.0;
    bool isRealHardware = false;

    // ── Step 1: Get real GPS coordinates ──────────────────────────────────────
    if (forcedLat == null && forcedLng == null && !kIsWeb) {
      final hasPerm = requestPermission
          ? await requestLocationPermission()
          : await _hasLocationPermission();
      if (hasPerm) {
        try {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.best,
              distanceFilter: 0,
            ),
          ).timeout(const Duration(seconds: 15));
          lat = pos.latitude;
          lng = pos.longitude;
          altitude = pos.altitude;
          accuracy = pos.accuracy;
          isRealHardware = true;
        } catch (_) {}
      }
    }

    // If we still have no coordinates, return a minimal fallback
    if (lat == 0.0 && lng == 0.0) {
      return GeotagData(
        latitude: lat,
        longitude: lng,
        altitude: altitude,
        accuracyMeters: accuracy,
        formattedGoogleAddress: 'Location unavailable — enable GPS',
        streetAddress: '',
        locality: '',
        city: 'Unknown',
        state: '',
        country: '',
        postalCode: '',
        timestamp: now,
        timeZoneName: tzName,
        timeZoneOffset: tzOffset,
        isRealHardwareGPS: false,
      );
    }

    // ── Step 2: Reverse Geocode the real GPS coordinates ──────────────────────
    String googleFormatted = '';
    String street = '';
    String locality = '';
    String city = '';
    String state = '';
    String country = '';
    String postalCode = '';

    // 2a. geocode.maps.co — PRIMARY (free, OSM data, reliable, no payment needed)
    if (!kIsWeb) {
      try {
        final client = HttpClient();
        final uri = Uri.parse(
          'https://geocode.maps.co/reverse'
          '?lat=$lat&lon=$lng&api_key=$mapsCoApiKey',
        );
        final req =
            await client.getUrl(uri).timeout(const Duration(seconds: 8));
        req.headers.set('Accept', 'application/json');
        req.headers.set('Accept-Language', 'en');
        final res = await req.close();
        if (res.statusCode == 200) {
          final body = await res.transform(utf8.decoder).join();
          final data = json.decode(body) as Map<String, dynamic>;
          final address = data['address'] as Map<String, dynamic>?;
          if (address != null) {
            // Build street: house_number + road/pedestrian/path
            final houseNum = address['house_number'] as String? ?? '';
            final road = address['road'] as String? ??
                address['pedestrian'] as String? ??
                address['footway'] as String? ??
                address['path'] as String? ??
                address['street'] as String? ??
                '';
            street = [
              if (houseNum.isNotEmpty) houseNum,
              if (road.isNotEmpty) road,
            ].join(', ');

            // Build locality: neighbourhood > quarter > suburb > city_district
            locality = address['neighbourhood'] as String? ??
                address['quarter'] as String? ??
                address['suburb'] as String? ??
                address['city_district'] as String? ??
                address['residential'] as String? ??
                '';

            city = address['city'] as String? ??
                address['town'] as String? ??
                address['village'] as String? ??
                address['municipality'] as String? ??
                address['county'] as String? ??
                '';

            state = address['state'] as String? ?? '';
            country = address['country'] as String? ?? '';
            postalCode = address['postcode'] as String? ?? '';

            // Use the full display_name as formatted address if individual parts found
            final addrParts = <String>[
              if (street.isNotEmpty) street,
              if (locality.isNotEmpty) locality,
              if (city.isNotEmpty) city,
              if (state.isNotEmpty) state,
              if (postalCode.isNotEmpty) postalCode,
              if (country.isNotEmpty) country,
            ];
            if (addrParts.isNotEmpty) {
              googleFormatted = addrParts.join(', ');
            }
          }
        }
        client.close();
      } catch (_) {}
    }

    // 2b. Google Maps Geocoding API (most accurate, requires API key)
    if (googleFormatted.isEmpty &&
        googleApiKey != null &&
        googleApiKey.isNotEmpty &&
        !kIsWeb) {
      try {
        final client = HttpClient();
        final uri = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=$lat,$lng&key=$googleApiKey&language=en',
        );
        final req =
            await client.getUrl(uri).timeout(const Duration(seconds: 5));
        final res = await req.close();
        if (res.statusCode == 200) {
          final body = await res.transform(utf8.decoder).join();
          final data = json.decode(body) as Map<String, dynamic>;
          if (data['status'] == 'OK') {
            final results = data['results'] as List;
            if (results.isNotEmpty) {
              googleFormatted = results[0]['formatted_address'] ?? '';
              // Parse individual address components
              final components =
                  results[0]['address_components'] as List? ?? [];
              for (final comp in components) {
                final types = (comp['types'] as List).cast<String>();
                final value = comp['long_name'] as String? ?? '';
                if (types.contains('street_number')) {
                  street = value.isNotEmpty
                      ? '$value ${street.isEmpty ? "" : street}'
                      : street;
                } else if (types.contains('route')) {
                  street = street.isEmpty ? value : '$street $value';
                } else if (types.contains('sublocality_level_1') ||
                    types.contains('sublocality')) {
                  locality = value;
                } else if (types.contains('locality')) {
                  city = value;
                } else if (types.contains('administrative_area_level_1')) {
                  state = value;
                } else if (types.contains('country')) {
                  country = value;
                } else if (types.contains('postal_code')) {
                  postalCode = value;
                }
              }
            }
          }
        }
        client.close();
      } catch (_) {}
    }

    // 2c. OpenStreetMap Nominatim (free, no key needed — secondary fallback)
    if (googleFormatted.isEmpty && !kIsWeb) {
      try {
        final client = HttpClient();
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse'
          '?lat=$lat&lon=$lng&format=json&addressdetails=1&zoom=18',
        );
        final req =
            await client.getUrl(uri).timeout(const Duration(seconds: 6));
        req.headers.set(
          'User-Agent',
          'GreenCreditApp/1.0 (contact@greencredit.app)',
        );
        req.headers.set('Accept-Language', 'en');
        final res = await req.close();
        if (res.statusCode == 200) {
          final body = await res.transform(utf8.decoder).join();
          final data = json.decode(body) as Map<String, dynamic>;
          final address = data['address'] as Map<String, dynamic>?;
          if (address != null) {
            // Build street: house_number + road/street
            final houseNum = address['house_number'] as String? ?? '';
            final road = address['road'] as String? ??
                address['pedestrian'] as String? ??
                address['footway'] as String? ??
                address['path'] as String? ??
                '';
            street = [
              if (houseNum.isNotEmpty) houseNum,
              if (road.isNotEmpty) road,
            ].join(', ');

            // Build locality: neighbourhood > suburb > city_district > town
            locality = address['neighbourhood'] as String? ??
                address['suburb'] as String? ??
                address['city_district'] as String? ??
                address['quarter'] as String? ??
                '';

            city = address['city'] as String? ??
                address['town'] as String? ??
                address['municipality'] as String? ??
                address['county'] as String? ??
                '';

            state = address['state'] as String? ?? '';
            country = address['country'] as String? ?? '';
            postalCode = address['postcode'] as String? ?? '';

            // Build the formatted address from parts
            final addrParts = <String>[
              if (street.isNotEmpty) street,
              if (locality.isNotEmpty) locality,
              if (city.isNotEmpty) city,
              if (state.isNotEmpty) state,
              if (postalCode.isNotEmpty) postalCode,
              if (country.isNotEmpty) country,
            ];
            googleFormatted = addrParts.join(', ');
          }
        }
        client.close();
      } catch (_) {}
    }

    // 2c. BigDataCloud (last resort — gives at least city/state)
    if (googleFormatted.isEmpty && !kIsWeb) {
      try {
        final client = HttpClient();
        final uri = Uri.parse(
          'https://api.bigdatacloud.net/data/reverse-geocode-client'
          '?latitude=$lat&longitude=$lng&localityLanguage=en',
        );
        final req =
            await client.getUrl(uri).timeout(const Duration(seconds: 5));
        final res = await req.close();
        if (res.statusCode == 200) {
          final body = await res.transform(utf8.decoder).join();
          final data = json.decode(body) as Map<String, dynamic>;
          if (city.isEmpty) city = data['city'] as String? ?? '';
          if (locality.isEmpty) {
            locality = data['locality'] as String? ??
                data['subLocality'] as String? ??
                '';
          }
          if (state.isEmpty) {
            state = data['principalSubdivision'] as String? ?? '';
          }
          if (country.isEmpty) {
            country = data['countryName'] as String? ?? '';
          }
          if (postalCode.isEmpty) {
            postalCode = data['postcode'] as String? ?? '';
          }

          if (city.isNotEmpty) {
            googleFormatted = <String>[
              if (locality.isNotEmpty && locality != city) locality,
              if (city.isNotEmpty) city,
              if (state.isNotEmpty) state,
              if (postalCode.isNotEmpty) postalCode,
              if (country.isNotEmpty) country,
            ].join(', ');
          }
        }
        client.close();
      } catch (_) {}
    }

    // ── Step 3: Final coordinate-based fallback (city only, no fake streets) ──
    if (city.isEmpty) {
      final regional = _resolveLocationFromCoordinates(lat, lng);
      city = regional.city;
      if (state.isEmpty) state = regional.state;
      if (country.isEmpty) country = regional.country;
      // Do NOT fill in locality/street from regional fallback — keep them empty
      // so we don't show fake street names
    }

    if (googleFormatted.isEmpty) {
      googleFormatted = <String>[
        if (street.isNotEmpty) street,
        if (locality.isNotEmpty) locality,
        if (city.isNotEmpty) city,
        if (state.isNotEmpty) state,
        if (postalCode.isNotEmpty) postalCode,
        if (country.isNotEmpty) country,
      ].join(', ');
    }

    if (googleFormatted.isEmpty) {
      googleFormatted = formattedCoordinatesString(lat, lng);
    }

    return GeotagData(
      latitude: lat,
      longitude: lng,
      altitude: altitude,
      accuracyMeters: accuracy,
      formattedGoogleAddress: googleFormatted,
      streetAddress: street,
      locality: locality,
      city: city,
      state: state,
      country: country,
      postalCode: postalCode,
      timestamp: now,
      timeZoneName: tzName,
      timeZoneOffset: tzOffset,
      isRealHardwareGPS: isRealHardware,
    );
  }

  static String formattedCoordinatesString(double lat, double lng) {
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(6)}° $latDir, ${lng.abs().toStringAsFixed(6)}° $lngDir';
  }

  /// Calculates dynamic real city based on exact Lat/Lng bounds when offline.
  /// Returns empty locality/postalCode to prevent showing fake street names.
  static _RegionalInfo _resolveLocationFromCoordinates(double lat, double lng) {
    // Mumbai Region
    if (lat >= 18.80 && lat <= 19.35 && lng >= 72.75 && lng <= 73.15) {
      return _RegionalInfo(
        city: 'Mumbai',
        state: 'Maharashtra',
        country: 'India',
      );
    }
    // Pune Region
    if (lat >= 18.35 && lat <= 18.75 && lng >= 73.70 && lng <= 74.00) {
      return _RegionalInfo(
        city: 'Pune',
        state: 'Maharashtra',
        country: 'India',
      );
    }
    // Delhi NCR Region
    if (lat >= 28.30 && lat <= 28.90 && lng >= 76.80 && lng <= 77.50) {
      return _RegionalInfo(city: 'New Delhi', state: 'Delhi', country: 'India');
    }
    // Bengaluru Region
    if (lat >= 12.80 && lat <= 13.20 && lng >= 77.40 && lng <= 77.80) {
      return _RegionalInfo(
        city: 'Bengaluru',
        state: 'Karnataka',
        country: 'India',
      );
    }
    // Hyderabad Region
    if (lat >= 17.20 && lat <= 17.65 && lng >= 78.20 && lng <= 78.75) {
      return _RegionalInfo(
        city: 'Hyderabad',
        state: 'Telangana',
        country: 'India',
      );
    }
    // Chennai Region
    if (lat >= 12.80 && lat <= 13.25 && lng >= 80.10 && lng <= 80.35) {
      return _RegionalInfo(
        city: 'Chennai',
        state: 'Tamil Nadu',
        country: 'India',
      );
    }
    // Kolkata Region
    if (lat >= 22.40 && lat <= 22.75 && lng >= 88.20 && lng <= 88.55) {
      return _RegionalInfo(
        city: 'Kolkata',
        state: 'West Bengal',
        country: 'India',
      );
    }
    // Ahmedabad Region
    if (lat >= 22.90 && lat <= 23.15 && lng >= 72.45 && lng <= 72.75) {
      return _RegionalInfo(
        city: 'Ahmedabad',
        state: 'Gujarat',
        country: 'India',
      );
    }
    // Generic India fallback
    if (lat >= 6.0 && lat <= 37.0 && lng >= 68.0 && lng <= 98.0) {
      return _RegionalInfo(city: '', state: '', country: 'India');
    }
    return _RegionalInfo(city: '', state: '', country: '');
  }

  static String _formatTzOffset(Duration offset) {
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final sign = offset.isNegative ? '-' : '+';
    return 'UTC$sign$hours:$minutes';
  }

  Future<bool> _hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  }
}

class _RegionalInfo {
  final String city;
  final String state;
  final String country;

  _RegionalInfo({
    required this.city,
    required this.state,
    required this.country,
  });
}
