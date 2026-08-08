import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/authentic_geo_photo.dart';

/// Database model for previously saved action entries in backend.
class SavedEcoAction {
  final String id;
  final String categoryId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String address;
  final String cryptoHash;
  final double aiScore;
  final String? beforeImagePath;
  final String? afterImagePath;

  const SavedEcoAction({
    required this.id,
    required this.categoryId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.address,
    required this.cryptoHash,
    required this.aiScore,
    this.beforeImagePath,
    this.afterImagePath,
  });

  /// Calculates distance in meters from given target coordinates to this saved action.
  double distanceTo(double targetLat, double targetLng) {
    return EcoActionBackend.calculateDistanceMeters(
      latitude, longitude, targetLat, targetLng,
    );
  }

  /// Serialize to JSON map for SharedPreferences persistence.
  Map<String, dynamic> toJson() => {
    'id': id,
    'categoryId': categoryId,
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.toIso8601String(),
    'address': address,
    'cryptoHash': cryptoHash,
    'aiScore': aiScore,
    'beforeImagePath': beforeImagePath,
    'afterImagePath': afterImagePath,
  };

  /// Deserialize from JSON map loaded from SharedPreferences.
  factory SavedEcoAction.fromJson(Map<String, dynamic> json) => SavedEcoAction(
    id: json['id'] as String,
    categoryId: json['categoryId'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp'] as String),
    address: json['address'] as String,
    cryptoHash: json['cryptoHash'] as String,
    aiScore: (json['aiScore'] as num).toDouble(),
    beforeImagePath: json['beforeImagePath'] as String?,
    afterImagePath: json['afterImagePath'] as String?,
  );
}

/// Result of checking 30m proximity against backend database.
class ProximityCheckResult {
  final bool hasNearbyAction;
  final double closestDistanceMeters;
  final List<SavedEcoAction> nearbyActions;
  final String warningMessage;

  const ProximityCheckResult({
    required this.hasNearbyAction,
    required this.closestDistanceMeters,
    required this.nearbyActions,
    required this.warningMessage,
  });

  static const clear = ProximityCheckResult(
    hasNearbyAction: false,
    closestDistanceMeters: double.infinity,
    nearbyActions: [],
    warningMessage: 'Location clear! No existing entries recorded within 30 meters.',
  );
}

/// Persistent local backend repository managing saved actions & proximity checks.
/// Data is persisted to device storage using SharedPreferences — survives app restarts.
class EcoActionBackend {
  final List<SavedEcoAction> _database = [];
  static const String _prefsKey = 'eco_actions_v1';
  bool _initialized = false;

  EcoActionBackend();

  static const double earthRadiusMeters = 6371000.0;
  static const double default30mThreshold = 30.0;

  /// Must be called once at app startup before using the backend.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(raw) as List;
        _database.clear();
        for (final item in jsonList) {
          try {
            _database.add(SavedEcoAction.fromJson(item as Map<String, dynamic>));
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// Persists the current database to device storage.
  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = json.encode(_database.map((e) => e.toJson()).toList());
      await prefs.setString(_prefsKey, jsonStr);
    } catch (_) {}
  }

  /// Haversine distance formula.
  static double calculateDistanceMeters(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    final dLat = (lat2 - lat1) * (pi / 180.0);
    final dLng = (lng2 - lng1) * (pi / 180.0);
    final radLat1 = lat1 * (pi / 180.0);
    final radLat2 = lat2 * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLng / 2) * sin(dLng / 2) * cos(radLat1) * cos(radLat2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  /// Saves a new authentic geotagged photo action to the backend and persists to device.
  Future<bool> saveAction(AuthenticGeoPhoto photo) async {
    if (!_initialized) await initialize();

    final entry = SavedEcoAction(
      id: photo.id,
      categoryId: photo.category.id,
      latitude: photo.latitude,
      longitude: photo.longitude,
      timestamp: photo.timestamp,
      address: photo.address,
      cryptoHash: photo.cryptoHash,
      aiScore: photo.aiVerification.confidenceScore,
      beforeImagePath: photo.imagePath,
      afterImagePath: photo.secondaryImagePath,
    );

    _database.add(entry);
    await _persist(); // Save to device storage immediately
    return true;
  }

  /// Checks if there is any previous entry for [categoryId] within [radiusMeters] (30m).
  ProximityCheckResult check30mProximity({
    required double currentLat,
    required double currentLng,
    required String categoryId,
    double radiusMeters = default30mThreshold,
  }) {
    // Only tree_planted and beach_clean trigger 30m proximity rule
    if (categoryId != 'tree_planted' && categoryId != 'beach_clean') {
      return ProximityCheckResult.clear;
    }

    final nearby = <SavedEcoAction>[];
    double minDistance = double.infinity;

    for (final action in _database) {
      if (action.categoryId == categoryId) {
        final distance = action.distanceTo(currentLat, currentLng);
        if (distance <= radiusMeters) {
          nearby.add(action);
          if (distance < minDistance) {
            minDistance = distance;
          }
        }
      }
    }

    if (nearby.isEmpty) return ProximityCheckResult.clear;

    nearby.sort((a, b) =>
        a.distanceTo(currentLat, currentLng)
            .compareTo(b.distanceTo(currentLat, currentLng)));

    final nearest = nearby.first;
    final categoryName =
        categoryId == 'tree_planted' ? 'Tree Planting' : 'Cleanliness Drive';
    final formattedDist = minDistance.toStringAsFixed(1);

    final warning =
        '⚠️ 30m PROXIMITY DUPLICATE: A previous $categoryName action was already '
        'recorded ${formattedDist}m near this location on ${_formatDate(nearest.timestamp)}.';

    return ProximityCheckResult(
      hasNearbyAction: true,
      closestDistanceMeters: minDistance,
      nearbyActions: nearby,
      warningMessage: warning,
    );
  }

  /// Retrieves all saved eco-actions stored in backend.
  List<SavedEcoAction> getAllSavedActions() => List.unmodifiable(_database);

  /// Clears all actions (for testing only).
  Future<void> clearAll() async {
    _database.clear();
    await _persist();
  }

  static String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}
