import 'dart:math';
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
      latitude,
      longitude,
      targetLat,
      targetLng,
    );
  }
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
class EcoActionBackend {
  final List<SavedEcoAction> _database = [];

  EcoActionBackend({List<SavedEcoAction>? seedData}) {
    if (seedData != null && seedData.isNotEmpty) {
      _database.addAll(seedData);
    } else {
      _seedDefaultBackendData();
    }
  }

  static const double earthRadiusMeters = 6371000.0;
  static const double default30mThreshold = 30.0;

  /// Haversine distance formula.
  static double calculateDistanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
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

  /// Saves a new authentic geotagged photo action to the backend.
  Future<bool> saveAction(AuthenticGeoPhoto photo) async {
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
    return true;
  }

  /// Checks if there is any previous entry for [categoryId] within [radiusMeters] (30m).
  /// Strictly evaluated for Tree Planting (`tree_planted`) & Beach Clean (`beach_clean`).
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

    if (nearby.isEmpty) {
      return ProximityCheckResult.clear;
    }

    nearby.sort((a, b) => a.distanceTo(currentLat, currentLng).compareTo(b.distanceTo(currentLat, currentLng)));

    final nearest = nearby.first;
    final categoryName = categoryId == 'tree_planted' ? 'Tree Planting' : 'Cleanliness Drive';
    final formattedDist = minDistance.toStringAsFixed(1);

    final warning = '⚠️ 30m PROXIMITY DUPLICATE: A previous $categoryName action was already recorded ${formattedDist}m near this location on ${_formatDate(nearest.timestamp)}.';

    return ProximityCheckResult(
      hasNearbyAction: true,
      closestDistanceMeters: minDistance,
      nearbyActions: nearby,
      warningMessage: warning,
    );
  }

  /// Retrieves all saved eco-actions stored in backend.
  List<SavedEcoAction> getAllSavedActions() => List.unmodifiable(_database);

  /// Seeds default realistic sample records for testing 30m proximity.
  void _seedDefaultBackendData() {
    _database.addAll([
      // Tree Planting Anchor (Ward 12, Pune)
      SavedEcoAction(
        id: 'TREE_PREV_1',
        categoryId: 'tree_planted',
        latitude: 18.52042, // 5m near center
        longitude: 73.85673,
        timestamp: DateTime.now().subtract(const Duration(days: 12)),
        address: 'Ward 12 Park, Pune',
        cryptoHash: 'AUTH_8829A',
        aiScore: 0.985,
      ),
      // Beach Clean / Cleanliness Drive Anchor
      SavedEcoAction(
        id: 'BEACH_PREV_1',
        categoryId: 'beach_clean',
        latitude: 18.52045, // 10m near center
        longitude: 73.85675,
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        address: 'Riverside Walkway, Ward 12',
        cryptoHash: 'AUTH_9912B',
        aiScore: 0.972,
      ),
    ]);
  }

  static String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}
