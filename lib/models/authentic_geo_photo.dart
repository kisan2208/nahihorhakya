import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'action_category.dart';

/// Represents an authentic geotagged photo capture with anti-spoof proof.
class AuthenticGeoPhoto {
  final String id;
  final ActionCategory category;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracyMeters;
  final String address;
  final bool isLiveCamera;
  final bool exifIntact;
  final String? imagePath;
  final String cryptoHash;

  AuthenticGeoPhoto({
    required this.id,
    required this.category,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.altitude = 560.0,
    this.accuracyMeters = 3.5,
    required this.address,
    this.isLiveCamera = true,
    this.exifIntact = true,
    this.imagePath,
    String? cryptoHash,
  }) : cryptoHash = cryptoHash ?? _generateCryptoHash(id, timestamp, latitude, longitude, isLiveCamera);

  /// Generates a SHA-256 cryptographic verification token anchoring time, location & camera mode.
  static String _generateCryptoHash(
    String id,
    DateTime timestamp,
    double lat,
    double lng,
    bool isLive,
  ) {
    final payload = '$id|${timestamp.toIso8601String()}|${lat.toStringAsFixed(6)}|${lng.toStringAsFixed(6)}|$isLive|GREEN_CREDIT_SALT_2026';
    final bytes = utf8.encode(payload);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16).toUpperCase();
  }

  /// Formatted Geotag string for visual watermark rendering.
  String get formattedGeotag {
    final latDir = latitude >= 0 ? 'N' : 'S';
    final lngDir = longitude >= 0 ? 'E' : 'W';
    final latStr = '${latitude.abs().toStringAsFixed(4)}° $latDir';
    final lngStr = '${longitude.abs().toStringAsFixed(4)}° $lngDir';
    return '$latStr, $lngStr';
  }

  /// Formatted date time string for geotag stamp.
  String get formattedDateTime {
    final day = timestamp.day.toString().padLeft(2, '0');
    final month = _monthName(timestamp.month);
    final year = timestamp.year;
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final min = timestamp.minute.toString().padLeft(2, '0');
    final sec = timestamp.second.toString().padLeft(2, '0');
    return '$day $month $year • $hour:$min:$sec UTC';
  }

  static String _monthName(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[(m - 1) % 12];
  }

  /// Returns whether this photo passed all authenticity integrity checks.
  bool get isVerifiedAuthentic => isLiveCamera && exifIntact && accuracyMeters <= 20.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': category.id,
        'timestamp': timestamp.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'accuracyMeters': accuracyMeters,
        'address': address,
        'isLiveCamera': isLiveCamera,
        'exifIntact': exifIntact,
        'imagePath': imagePath,
        'cryptoHash': cryptoHash,
      };
}
