import 'package:flutter_test/flutter_test.dart';
import 'package:greencredit/models/action_category.dart';
import 'package:greencredit/models/authentic_geo_photo.dart';
import 'package:greencredit/services/ai_verification_service.dart';
import 'package:greencredit/services/eco_action_backend.dart';

void main() {
  group('AI Authenticity Verification Tests', () {
    test('Live camera capture passes AI verification with high score', () {
      final result = AIVerificationResult.analyzeImage(
        imagePath: 'camera_stream.jpg',
        isLiveCamera: true,
      );

      expect(result.isRealPhoto, isTrue);
      expect(result.isAiGenerated, isFalse);
      expect(result.confidenceScore, greaterThan(0.90));
      expect(result.formattedPercentage, contains('%'));
    });
  });

  group('EcoActionBackend & 30m Proximity Rules (Tree & Beach Clean ONLY)', () {
    late EcoActionBackend backend;

    setUp(() {
      backend = EcoActionBackend(seedData: [
        SavedEcoAction(
          id: 'SAVED_TREE_1',
          categoryId: 'tree_planted',
          latitude: 18.52042,
          longitude: 73.85673,
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          address: 'Ward 12 Park, Pune',
          cryptoHash: 'AUTH_TEST1',
          aiScore: 0.985,
        ),
        SavedEcoAction(
          id: 'SAVED_BEACH_1',
          categoryId: 'beach_clean',
          latitude: 18.52045,
          longitude: 73.85675,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          address: 'Riverside Walkway',
          cryptoHash: 'AUTH_TEST2',
          aiScore: 0.970,
        ),
      ]);
    });

    test('Tree planting triggers 30m duplicate proximity warning', () {
      final proximity = backend.check30mProximity(
        currentLat: 18.52044, // ~3m away
        currentLng: 73.85674,
        categoryId: 'tree_planted',
      );

      expect(proximity.hasNearbyAction, isTrue);
      expect(proximity.closestDistanceMeters, lessThan(30.0));
      expect(proximity.warningMessage, contains('PROXIMITY DUPLICATE'));
    });

    test('Beach clean triggers 30m duplicate proximity warning', () {
      final proximity = backend.check30mProximity(
        currentLat: 18.52046, // ~2m away
        currentLng: 73.85676,
        categoryId: 'beach_clean',
      );

      expect(proximity.hasNearbyAction, isTrue);
      expect(proximity.closestDistanceMeters, lessThan(30.0));
    });

    test('Recycling category DOES NOT trigger 30m proximity warning', () {
      final proximity = backend.check30mProximity(
        currentLat: 18.52044,
        currentLng: 73.85674,
        categoryId: 'recycle_ewaste',
      );

      expect(proximity.hasNearbyAction, isFalse);
      expect(proximity.warningMessage, contains('clear'));
    });

    test('Dual photo recycling proof saves before and after images to backend', () async {
      final photo = AuthenticGeoPhoto(
        id: 'RECYCLE_101',
        category: ActionCategory.findById('recycle_ewaste'),
        timestamp: DateTime.now(),
        latitude: 18.5204,
        longitude: 73.8567,
        address: 'Ward 12, Pune',
        imagePath: 'before_recycle.jpg',
        secondaryImagePath: 'after_recycle.jpg',
        secondaryTimestamp: DateTime.now(),
      );

      final success = await backend.saveAction(photo);
      expect(success, isTrue);

      final savedList = backend.getAllSavedActions();
      final savedRecycle = savedList.firstWhere((a) => a.id == 'RECYCLE_101');
      expect(savedRecycle.beforeImagePath, equals('before_recycle.jpg'));
      expect(savedRecycle.afterImagePath, equals('after_recycle.jpg'));
    });
  });
}
