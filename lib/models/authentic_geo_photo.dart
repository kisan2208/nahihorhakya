import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'action_category.dart';
import '../services/ai_verification_service.dart';
import '../services/geotag_service.dart';

/// Represents an authentic geotagged photo capture with AI proof and high-precision GeotagData.
class AuthenticGeoPhoto {
  final String id;
  final ActionCategory category;
  final GeotagData geotag;
  final bool isLiveCamera;
  final bool exifIntact;
  final String? imagePath;
  final String cryptoHash;

  /// AI Verification Result (Real Photo vs AI Generated)
  final AIVerificationResult aiVerification;

  /// Secondary photo path & timestamp for dual-photo categories (Recycle BEFORE / AFTER)
  final String? secondaryImagePath;
  final DateTime? secondaryTimestamp;

  AuthenticGeoPhoto({
    required this.id,
    required this.category,
    GeotagData? geotag,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    double altitude = 560.0,
    double accuracyMeters = 3.5,
    String? address,
    this.isLiveCamera = true,
    this.exifIntact = true,
    this.imagePath,
    String? cryptoHash,
    AIVerificationResult? aiVerification,
    this.secondaryImagePath,
    this.secondaryTimestamp,
  })  : geotag = geotag ??
            GeotagData(
              latitude: latitude ?? 18.520420,
              longitude: longitude ?? 73.856730,
              altitude: altitude,
              accuracyMeters: accuracyMeters,
              streetAddress: address ?? 'Ward 12, Pune',
              locality: 'Ward 12',
              city: 'Pune',
              state: 'Maharashtra',
              country: 'India',
              postalCode: '411005',
              timestamp: timestamp ?? DateTime.now(),
              timeZoneName: 'IST',
              timeZoneOffset: 'UTC+05:30',
            ),
        cryptoHash = cryptoHash ?? _generateCryptoHash(id, (geotag?.timestamp ?? timestamp ?? DateTime.now()), (geotag?.latitude ?? latitude ?? 18.520420), (geotag?.longitude ?? longitude ?? 73.856730), isLiveCamera),
        aiVerification = aiVerification ?? AIVerificationResult.analyzeImage(imagePath: imagePath ?? '', isLiveCamera: isLiveCamera);

  /// Convenient getters
  DateTime get timestamp => geotag.timestamp;
  double get latitude => geotag.latitude;
  double get longitude => geotag.longitude;
  double get altitude => geotag.altitude;
  double get accuracyMeters => geotag.accuracyMeters;
  String get address => geotag.fullFormattedAddress;
  String get formattedGeotag => geotag.formattedCoordinates;
  String get formattedDateTime => geotag.formattedDateTime;

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

  /// Returns whether this photo passed all authenticity integrity checks.
  bool get isVerifiedAuthentic => isLiveCamera && exifIntact && accuracyMeters <= 20.0 && aiVerification.isRealPhoto;

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': category.id,
        'timestamp': timestamp.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'accuracyMeters': accuracyMeters,
        'address': address,
        'formattedGeotag': formattedGeotag,
        'formattedDateTime': formattedDateTime,
        'isLiveCamera': isLiveCamera,
        'exifIntact': exifIntact,
        'imagePath': imagePath,
        'cryptoHash': cryptoHash,
        'aiConfidenceScore': aiVerification.confidenceScore,
        'isAiGenerated': aiVerification.isAiGenerated,
        'secondaryImagePath': secondaryImagePath,
        'secondaryTimestamp': secondaryTimestamp?.toIso8601String(),
      };
}
