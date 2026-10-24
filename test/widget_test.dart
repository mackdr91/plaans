import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plaans/models/plan_models.dart';
import 'package:plaans/providers/plan_studio_provider.dart';
import 'package:plaans/services/maps_service.dart';

void main() {
  group('LocationData & MapsService GPS Deep Links', () {
    test('Generates valid Google Maps and Apple Maps GPS URLs', () {
      const loc = LocationData(
        placeName: 'Shibuya Sky Observation Deck',
        address: '2-24-12 Shibuya, Tokyo',
        latitude: 35.6585,
        longitude: 139.7022,
      );

      expect(loc.hasCoordinates, isTrue);
      expect(loc.googleMapsSearchUrl, contains('google.com/maps/search'));
      expect(loc.googleMapsDirectionsUrl, contains('google.com/maps/dir'));
      expect(loc.appleMapsSearchUrl, contains('maps.apple.com'));
      expect(loc.appleMapsDirectionsUrl, contains('daddr=35.6585,139.7022'));
    });

    test('Generates multi-stop Google Maps route URL', () {
      const stops = [
        LocationData(
          placeName: 'Tsukiji',
          latitude: 35.6655,
          longitude: 139.7707,
        ),
        LocationData(
          placeName: 'teamLab Planets',
          latitude: 35.6491,
          longitude: 139.7898,
        ),
        LocationData(
          placeName: 'Shibuya Sky',
          latitude: 35.6585,
          longitude: 139.7022,
        ),
      ];

      final routeUrl = MapsService.buildGoogleMapsMultiStopRouteUrl(stops);
      expect(routeUrl, isNotNull);
      expect(routeUrl, contains('origin='));
      expect(routeUrl, contains('destination='));
      expect(routeUrl, contains('waypoints='));
    });
  });

  group('PlanModel Shareable Payload & Provider Drag-and-Drop', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Round-trips PlanModel through URL-safe shareable payload', () {
      final original = PlanModel(
        id: 'test_1',
        slug: 'paris-weekend',
        title: 'Paris Art & Bistro Weekend',
        subtitle: 'Louvre, Le Marais & Seine sunset',
        theme: PlanTheme.presets[2],
        updatedAt: DateTime(2026, 10, 23),
        blocks: const [
          PlanBlock(
            id: 'b1',
            type: BlockType.placeEvent,
            title: 'Eiffel Tower Picnic',
            location: LocationData(
              placeName: 'Champ de Mars',
              latitude: 48.8584,
              longitude: 2.2945,
            ),
          ),
        ],
      );

      final encoded = original.toShareablePayload();
      final decoded = PlanModel.fromShareablePayload(encoded);

      expect(decoded, isNotNull);
      expect(decoded!.title, equals('Paris Art & Bistro Weekend'));
      expect(decoded.slug, equals('paris-weekend'));
      expect(decoded.blocks.length, equals(1));
      expect(decoded.blocks.first.location?.placeName, equals('Champ de Mars'));
    });

    test('PlanStudioProvider supports adding and reordering blocks', () async {
      final provider = PlanStudioProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final plan = await provider.createNewPlan(title: 'Test Roadtrip');
      expect(plan.blocks.length, equals(3));

      final firstId = provider.visibleBlocks[0].id;
      final secondId = provider.visibleBlocks[1].id;

      await provider.reorderBlocks(0, 1);
      expect(provider.visibleBlocks[0].id, equals(secondId));
      expect(provider.visibleBlocks[1].id, equals(firstId));
    });

    test('Supports custom vanity slug, PIN-protected visibility, and PIN unlock',
        () async {
      final provider = PlanStudioProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await provider.createNewPlan(title: 'Kyoto Private Retreat');
      await provider.updatePlanSharingConfig(
        slug: 'kyoto-vip-2026',
        visibility: PlanVisibility.pinProtected,
        pinCode: '7788',
      );

      expect(provider.activePlan?.slug, equals('kyoto-vip-2026'));
      expect(
        provider.activePlan?.visibility,
        equals(PlanVisibility.pinProtected),
      );
      expect(provider.activePlan?.hasPin, isTrue);

      provider.setVisitorView(true);
      expect(provider.isVisitorPinLocked, isTrue);

      final badAttempt = await provider.unlockActivePlanWithPin('0000');
      expect(badAttempt, isFalse);
      expect(provider.isVisitorPinLocked, isTrue);

      final goodAttempt = await provider.unlockActivePlanWithPin('7788');
      expect(goodAttempt, isTrue);
      expect(provider.isVisitorPinLocked, isFalse);
    });

    test('Supports multi-step Undo/Redo, Visited check-off, and Haversine leg ETA',
        () async {
      final provider = PlanStudioProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final plan = await provider.createNewPlan(title: 'Rome Food Tour');
      final initialBlockCount = plan.blocks.length;

      final added = await provider.addBlock(BlockType.placeEvent);
      expect(provider.activePlan!.blocks.length, equals(initialBlockCount + 1));
      expect(provider.canUndo, isTrue);

      await provider.undo();
      expect(provider.activePlan!.blocks.length, equals(initialBlockCount));
      expect(provider.canRedo, isTrue);

      await provider.redo();
      expect(provider.activePlan!.blocks.length, equals(initialBlockCount + 1));

      // Test Visited check-off toggle
      expect(provider.isBlockCompleted(added!.id), isFalse);
      await provider.toggleBlockCompleted(added.id);
      expect(provider.isBlockCompleted(added.id), isTrue);

      // Test Haversine distance & walk/drive leg formatter
      const stopA = LocationData(
        placeName: 'Balthazar',
        latitude: 40.7226,
        longitude: -73.9982,
      );
      const stopB = LocationData(
        placeName: 'Dante NYC',
        latitude: 40.7288,
        longitude: -74.0016,
      );
      final leg = MapsService.formatTravelLegSummary(stopA, stopB);
      expect(leg, isNotNull);
      expect(leg, contains('walk'));
    });

    test('Supports Email/Password authentication', () async {
      final provider = PlanStudioProvider();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // 1. Email/Password Registration validation (short password fails)
      final shortPass = await provider.registerWithEmail(
        email: 'creator@plaans.co',
        password: '123',
        displayName: 'Alex Rivera',
      );
      expect(shortPass, isFalse);
      expect(provider.authError, isNotNull);

      // 2. Valid Email/Password Registration
      final emailOk = await provider.registerWithEmail(
        email: 'creator@plaans.co',
        password: 'password123',
        displayName: 'Alex Rivera',
      );
      expect(emailOk, isTrue);
      expect(provider.creatorUser?.email, equals('creator@plaans.co'));
      expect(provider.creatorUser?.providerLabel, equals('Email'));

      // 3. Sign Out
      await provider.signOutCreator();
      expect(provider.creatorUser, isNull);
    });
  });
}
