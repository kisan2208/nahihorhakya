import 'package:flutter_test/flutter_test.dart';
import 'package:greencredit/models/action_category.dart';
import 'package:greencredit/models/authentic_geo_photo.dart';
import 'package:greencredit/services/proximity_tracker_service.dart';

void main() {
  group('ProximityTrackerService & Haversine Distance Tests', () {
    late ProximityTrackerService service;

    setUp(() {
      service = ProximityTrackerService(initialDatabase: [
        PlantedTreeRecord(
          id: 'TREE_TEST_1',
          latitude: 18.52040,
          longitude: 73.85670,
          plantedAt: DateTime.now().subtract(const Duration(days: 5)),
          planterName: 'Test Planter',
          treeSpecies: 'Mango Sapling',
          address: 'Test Park',
        ),
      ]);
    });

    test('Identifies tree within 30 meters and returns warning', () {
      // Coordinates ~10 meters away from 18.52040, 73.85670
      const testLat = 18.52045;
      const testLng = 73.85675;

      final result = service.checkTreeProximity(testLat, testLng, radiusMeters: 30.0);

      expect(result.hasNearbyTree, isTrue);
      expect(result.closestDistanceMeters, lessThan(30.0));
      expect(result.warningLevel, isNot(ProximityWarningLevel.none));
      expect(result.nearbyTrees.length, equals(1));
    });

    test('Returns clear result when user is outside 30 meters zone', () {
      // Coordinates ~200 meters away
      const testLat = 18.52200;
      const testLng = 73.85800;

      final result = service.checkTreeProximity(testLat, testLng, radiusMeters: 30.0);

      expect(result.hasNearbyTree, isFalse);
      expect(result.warningLevel, equals(ProximityWarningLevel.none));
      expect(result.nearbyTrees, isEmpty);
    });

    test('Haversine distance formula accuracy', () {
      // Distance between 18.5204, 73.8567 and 18.5204, 73.8568 (approx 10.5 meters)
      final distance = ProximityTrackerService.calculateDistanceMeters(
        18.5204, 73.8567,
        18.5204, 73.8568,
      );

      expect(distance, greaterThan(9.0));
      expect(distance, lessThan(12.0));
    });
  });

  group('AuthenticGeoPhoto & Category Tests', () {
    test('Generates valid SHA-256 cryptographic verification token', () {
      final photo = AuthenticGeoPhoto(
        id: 'CAP_1001',
        category: ActionCategory.allCategories.first,
        timestamp: DateTime(2026, 8, 1, 10, 30),
        latitude: 18.5204,
        longitude: 73.8567,
        address: 'Ward 12, Pune',
        isLiveCamera: true,
      );

      expect(photo.cryptoHash.length, equals(16));
      expect(photo.isVerifiedAuthentic, isTrue);
      expect(photo.formattedGeotag, contains('18.5204° N'));
    });

    test('ActionCategory list contains Tree Planted and Beach Clean', () {
      final categories = ActionCategory.allCategories;
      expect(categories.any((c) => c.id == 'tree_planted'), isTrue);
      expect(categories.any((c) => c.id == 'beach_clean'), isTrue);
      expect(categories.any((c) => c.id == 'recycle'), isTrue);

      final treeCategory = ActionCategory.findById('tree_planted');
      expect(treeCategory.requiresProximityCheck, isTrue);
      expect(treeCategory.proximityRadiusMeters, equals(30.0));
    });
  });
}
