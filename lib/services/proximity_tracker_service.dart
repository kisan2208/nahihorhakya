import 'dart:math';

/// A record of a previously planted tree stored in database.
class PlantedTreeRecord {
  final String id;
  final double latitude;
  final double longitude;
  final DateTime plantedAt;
  final String planterName;
  final String treeSpecies;
  final String address;

  const PlantedTreeRecord({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.plantedAt,
    required this.planterName,
    required this.treeSpecies,
    required this.address,
  });

  /// Calculates distance in meters from given target coordinates to this tree.
  double distanceTo(double targetLat, double targetLng) {
    return ProximityTrackerService.calculateDistanceMeters(
      latitude,
      longitude,
      targetLat,
      targetLng,
    );
  }
}

enum ProximityWarningLevel {
  none,
  warning, // 15.0m to 30.0m
  critical, // < 15.0m
}

/// Outcome of checking user's current GPS location against previous tree plantings.
class ProximityCheckResult {
  final bool hasNearbyTree;
  final double closestDistanceMeters;
  final List<PlantedTreeRecord> nearbyTrees;
  final ProximityWarningLevel warningLevel;
  final String warningMessage;

  const ProximityCheckResult({
    required this.hasNearbyTree,
    required this.closestDistanceMeters,
    required this.nearbyTrees,
    required this.warningLevel,
    required this.warningMessage,
  });

  static const clear = ProximityCheckResult(
    hasNearbyTree: false,
    closestDistanceMeters: double.infinity,
    nearbyTrees: [],
    warningLevel: ProximityWarningLevel.none,
    warningMessage: 'Location clear! No existing trees recorded within 30 meters.',
  );
}

/// Service that tracks previous tree plantings and checks 30m proximity rule.
class ProximityTrackerService {
  final List<PlantedTreeRecord> _treeDatabase = [];

  ProximityTrackerService({List<PlantedTreeRecord>? initialDatabase}) {
    if (initialDatabase != null && initialDatabase.isNotEmpty) {
      _treeDatabase.addAll(initialDatabase);
    } else {
      _seedDefaultDatabase();
    }
  }

  /// Earth radius in meters.
  static const double earthRadiusMeters = 6371000.0;

  /// Default distance threshold for duplicate tree warning (30 meters).
  static const double defaultThresholdMeters = 30.0;

  /// Calculates exact distance in meters between two lat/lng points using the Haversine formula.
  static double calculateDistanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final radLat1 = _toRadians(lat1);
    final radLat2 = _toRadians(lat2);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLng / 2) * sin(dLng / 2) * cos(radLat1) * cos(radLat2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  static double _toRadians(double degree) => degree * (pi / 180.0);

  /// Checks if there is any previously planted tree within [radiusMeters] (default 30m) of [currentLat], [currentLng].
  ProximityCheckResult checkTreeProximity(
    double currentLat,
    double currentLng, {
    double radiusMeters = defaultThresholdMeters,
  }) {
    final nearby = <PlantedTreeRecord>[];
    double minDistance = double.infinity;

    for (final tree in _treeDatabase) {
      final distance = tree.distanceTo(currentLat, currentLng);
      if (distance <= radiusMeters) {
        nearby.add(tree);
        if (distance < minDistance) {
          minDistance = distance;
        }
      }
    }

    if (nearby.isEmpty) {
      return ProximityCheckResult.clear;
    }

    // Sort by closest distance first
    nearby.sort((a, b) => a.distanceTo(currentLat, currentLng).compareTo(b.distanceTo(currentLat, currentLng)));

    final warningLevel = minDistance < 15.0
        ? ProximityWarningLevel.critical
        : ProximityWarningLevel.warning;

    final formattedDist = minDistance.toStringAsFixed(1);
    final nearestTree = nearby.first;

    final message = warningLevel == ProximityWarningLevel.critical
        ? '⚠️ CRITICAL: Existing tree "${nearestTree.treeSpecies}" planted only ${formattedDist}m away by ${nearestTree.planterName}!'
        : '⚠️ WARNING: A tree was already planted ${formattedDist}m near this spot on ${_formatDate(nearestTree.plantedAt)}.';

    return ProximityCheckResult(
      hasNearbyTree: true,
      closestDistanceMeters: minDistance,
      nearbyTrees: nearby,
      warningLevel: warningLevel,
      warningMessage: message,
    );
  }

  /// Adds a new tree record to the database.
  void registerTreePlanting(PlantedTreeRecord tree) {
    _treeDatabase.add(tree);
  }

  /// Seed database with realistic demo tree entries for testing.
  void _seedDefaultDatabase() {
    _treeDatabase.addAll([
      // Reference anchor: Ward 12, Pune center (~18.5204, 73.8567)
      PlantedTreeRecord(
        id: 'TREE_001',
        latitude: 18.52055, // ~17m away from (18.5204, 73.8567)
        longitude: 73.85678,
        plantedAt: DateTime.now().subtract(const Duration(days: 14)),
        planterName: 'Rohan Verma',
        treeSpecies: 'Neem Sapling (Azadirachta indica)',
        address: 'Sector 4, Ward 12 Park, Pune',
      ),
      PlantedTreeRecord(
        id: 'TREE_002',
        latitude: 18.52042, // ~5m away from (18.5204, 73.8567)
        longitude: 73.85673,
        plantedAt: DateTime.now().subtract(const Duration(days: 30)),
        planterName: 'Priya Nair',
        treeSpecies: 'Banyan Sapling (Ficus benghalensis)',
        address: 'Green Belt Walkway, Ward 12, Pune',
      ),
      PlantedTreeRecord(
        id: 'TREE_003',
        latitude: 18.52180, // ~160m away (Outside 30m zone)
        longitude: 73.85800,
        plantedAt: DateTime.now().subtract(const Duration(days: 45)),
        planterName: 'Amit Patel',
        treeSpecies: 'Gulmohar Tree',
        address: 'Community Center Courtyard, Pune',
      ),
    ]);
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
