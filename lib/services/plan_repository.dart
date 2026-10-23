import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plan_models.dart';

/// Repository abstraction for saving, loading, and resolving shared Plans.
/// Supports local browser storage (`SharedPreferences`), self-contained URL share payloads,
/// and is structured to plug directly into Firebase Firestore or a Django REST backend.
class PlanRepository {
  static const String _storageKey = 'plaans_saved_itineraries_v2';

  Future<List<PlanModel>> loadAllPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      final seeded = defaultSamplePlans();
      await saveAllPlans(seeded);
      return seeded;
    }

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final plans = list
          .map((item) => PlanModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return plans.isEmpty ? defaultSamplePlans() : plans;
    } catch (_) {
      return defaultSamplePlans();
    }
  }

  Future<void> saveAllPlans(List<PlanModel> plans) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(plans.map((p) => p.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> savePlan(PlanModel plan) async {
    final plans = await loadAllPlans();
    final idx = plans.indexWhere((p) => p.id == plan.id);
    if (idx >= 0) {
      plans[idx] = plan;
    } else {
      plans.insert(0, plan);
    }
    await saveAllPlans(plans);
  }

  Future<void> deletePlan(String planId) async {
    final plans = await loadAllPlans();
    plans.removeWhere((p) => p.id == planId);
    await saveAllPlans(plans);
  }

  Future<PlanModel?> findBySlugOrId(String slugOrId, {String? encodedData}) async {
    if (encodedData != null && encodedData.isNotEmpty) {
      final decoded = PlanModel.fromShareablePayload(encodedData);
      if (decoded != null) return decoded;
    }

    final plans = await loadAllPlans();
    for (final p in plans) {
      if (p.slug.toLowerCase() == slugOrId.toLowerCase() || p.id == slugOrId) {
        return p;
      }
    }
    return null;
  }

  /// Rich, realistic starter itineraries showcasing all Liinks.co + Squarespace features
  static List<PlanModel> defaultSamplePlans() {
    final now = DateTime.now();
    return [
      PlanModel(
        id: 'plan_tokyo_weekend',
        slug: 'tokyo-72-hours',
        title: '72 Hours in Tokyo',
        subtitle:
            'Architectural coffee spots, digital art museums, Tsukiji street food & vinyl listening bars.',
        dateRangeLabel: 'Nov 14 – Nov 16 · 3 Days',
        authorName: '@maya.travels',
        coverImageUrl:
            'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&w=1200&q=80',
        avatarImageUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
        theme: PlanTheme.presets[0], // Liinks Neo-Pop
        updatedAt: now,
        blocks: const [
          PlanBlock(
            id: 'tok_map_overview',
            type: BlockType.mapOverview,
            size: BlockSize.featured,
            dayTag: 'Day 1',
            title: 'Tokyo Interactive Route Map',
            subtitle: 'Tap any pin or open the full multi-stop route in GPS',
          ),
          PlanBlock(
            id: 'tok_day1',
            type: BlockType.dayHeader,
            size: BlockSize.standard,
            dayTag: 'Day 1',
            title: 'Day 1 — Tsukiji Markets & Shibuya Skyline',
            subtitle: 'Friday · Central & West Tokyo',
          ),
          PlanBlock(
            id: 'tok_stop1',
            type: BlockType.placeEvent,
            size: BlockSize.featured,
            dayTag: 'Day 1',
            startTime: '08:30 AM',
            endTime: '10:30 AM',
            category: 'Food & Drink',
            title: 'Tsukiji Outer Market Street Breakfast',
            subtitle: 'Fresh uni bowls, tamagoyaki skewers & ceremonial matcha',
            description:
                'Arrive before 9 AM to beat the lines at Marutake for warm dashi rolled omelette and strawberry daifuku.',
            costEstimate: '\$25 / person',
            externalUrl: 'https://www.tsukiji.or.jp/english/',
            externalUrlLabel: 'Market Guide & Map',
            location: LocationData(
              placeName: 'Tsukiji Outer Market',
              address: '4 Chome-16-2 Tsukiji, Chuo City, Tokyo 104-0045, Japan',
              latitude: 35.6655,
              longitude: 139.7707,
            ),
            imageUrls: [
              'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?auto=format&fit=crop&w=900&q=80',
            ],
          ),
          PlanBlock(
            id: 'tok_stop2',
            type: BlockType.placeEvent,
            size: BlockSize.standard,
            dayTag: 'Day 1',
            startTime: '01:00 PM',
            endTime: '03:30 PM',
            category: 'Activity',
            title: 'teamLab Planets TOKYO',
            subtitle: 'Immersive barefoot water & crystal light installations',
            description:
                'Wear pants that roll up above the knee! QR tickets are linked in our shared folder below.',
            costEstimate: '\$32 Ticket',
            externalUrl: 'https://www.teamlab.art/e/planets/',
            externalUrlLabel: 'View Timed Entry Ticket',
            location: LocationData(
              placeName: 'teamLab Planets TOKYO',
              address: '6 Chome-1-16 Toyosu, Koto City, Tokyo 135-0061, Japan',
              latitude: 35.6491,
              longitude: 139.7898,
            ),
            imageUrls: [
              'https://images.unsplash.com/photo-1518998053901-5348d3961a04?auto=format&fit=crop&w=900&q=80',
            ],
          ),
          PlanBlock(
            id: 'tok_stop3',
            type: BlockType.placeEvent,
            size: BlockSize.standard,
            dayTag: 'Day 1',
            startTime: '05:15 PM',
            endTime: '07:00 PM',
            category: 'Nightlife',
            title: 'Shibuya Sky Sunset Rooftop',
            subtitle: '360° open-air helipad views above Shibuya Crossing',
            description:
                'Sunset is at 5:38 PM. Lockers are required for bags & tripods before heading onto the sky deck.',
            costEstimate: '\$18 Reserved',
            externalUrl: 'https://www.shibuya-scramble-square.com/sky/',
            externalUrlLabel: 'Shibuya Sky Portal',
            location: LocationData(
              placeName: 'Shibuya Sky Observation Deck',
              address: '2-24-12 Shibuya, Tokyo 150-6145, Japan',
              latitude: 35.6585,
              longitude: 139.7022,
            ),
            imageUrls: [
              'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=600&q=80',
            ],
          ),
          PlanBlock(
            id: 'tok_link1',
            type: BlockType.linkCard,
            size: BlockSize.halfWidth,
            dayTag: 'Day 1',
            title: 'Suica IC Transit Card Setup',
            subtitle: 'Add to Apple Wallet before landing at Haneda',
            externalUrl: 'https://support.apple.com/en-us/HT207155',
            externalUrlLabel: 'Apple Pay Transit Guide',
          ),
          PlanBlock(
            id: 'tok_link2',
            type: BlockType.linkCard,
            size: BlockSize.halfWidth,
            dayTag: 'Day 1',
            title: 'Group Splitwise Board',
            subtitle: 'Track shared izakaya tabs & train tickets',
            externalUrl: 'https://www.splitwise.com/',
            externalUrlLabel: 'Open Splitwise',
          ),
          PlanBlock(
            id: 'tok_day2',
            type: BlockType.dayHeader,
            size: BlockSize.standard,
            dayTag: 'Day 2',
            title: 'Day 2 — Daikanyama Coffee & Shinjuku Jazz',
            subtitle: 'Saturday · Boutiques, Matcha & Golden Gai',
          ),
          PlanBlock(
            id: 'tok_stop4',
            type: BlockType.placeEvent,
            size: BlockSize.standard,
            dayTag: 'Day 2',
            startTime: '10:00 AM',
            endTime: '12:00 PM',
            category: 'Food & Drink',
            title: 'Daikanyama T-Site & Anjin Lounge',
            subtitle: 'Curated art bookstore, vintage magazines & pour-over coffee',
            description:
                'One of the world’s most beautiful bookstores tucked inside interlocking forest pavilions.',
            costEstimate: '\$14 Coffee',
            externalUrl: 'https://store.tsite.jp/daikanyama/',
            externalUrlLabel: 'T-Site Campus Info',
            location: LocationData(
              placeName: 'Daikanyama T-Site',
              address: '17-5 Sarugakucho, Shibuya City, Tokyo 150-0033, Japan',
              latitude: 35.6489,
              longitude: 139.6997,
            ),
            imageUrls: [
              'https://images.unsplash.com/photo-1515823064-d6e0c04616a7?auto=format&fit=crop&w=900&q=80',
            ],
          ),
          PlanBlock(
            id: 'tok_note1',
            type: BlockType.textNote,
            size: BlockSize.standard,
            dayTag: 'Day 2',
            title: 'Crew Packing & Etiquette Reminders',
            subtitle: 'Quick tips for everyone on the trip',
            description:
                '• Bring a small coin pouch for ¥100 & ¥500 coins.\n• Pocket Wi-Fi pickup is at Terminal 3 Counter B.\n• Most Golden Gai bars seat 6–8 people max, so we can split into two teams!',
          ),
        ],
      ),
      PlanModel(
        id: 'plan_soho_date',
        slug: 'nyc-downtown-saturday',
        title: 'NYC Downtown Saturday',
        subtitle:
            'SoHo cast-iron galleries, West Village aperitivo & late-night jazz.',
        dateRangeLabel: 'Saturday · Full Day Plan',
        authorName: '@alex_and_sam',
        coverImageUrl:
            'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?auto=format&fit=crop&w=1200&q=80',
        avatarImageUrl:
            'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=300&q=80',
        theme: PlanTheme.presets[1], // Midnight Neon
        updatedAt: now.subtract(const Duration(hours: 5)),
        blocks: const [
          PlanBlock(
            id: 'nyc_map',
            type: BlockType.mapOverview,
            size: BlockSize.featured,
            dayTag: 'Day 1',
            title: 'Downtown Manhattan Walking Map',
            subtitle: 'SoHo → Meatpacking → Greenwich Village',
          ),
          PlanBlock(
            id: 'nyc_stop1',
            type: BlockType.placeEvent,
            size: BlockSize.standard,
            dayTag: 'Day 1',
            startTime: '11:00 AM',
            endTime: '12:45 PM',
            category: 'Food & Drink',
            title: 'Balthazar SoHo Brunch',
            subtitle: 'Iconic French brasserie pastries & steak frites',
            description: 'Reservation under Alex for 4 guests.',
            costEstimate: '\$55 / person',
            externalUrl: 'https://balthazarny.com/',
            externalUrlLabel: 'View Menu',
            location: LocationData(
              placeName: 'Balthazar Brasserie',
              address: '80 Spring St, New York, NY 10012',
              latitude: 40.7226,
              longitude: -73.9982,
            ),
            imageUrls: [
              'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=600&q=80',
            ],
          ),
          PlanBlock(
            id: 'nyc_stop2',
            type: BlockType.placeEvent,
            size: BlockSize.standard,
            dayTag: 'Day 1',
            startTime: '02:30 PM',
            endTime: '05:00 PM',
            category: 'Activity',
            title: 'The Whitney Museum + High Line Walk',
            subtitle: 'Contemporary American art & Hudson River terraces',
            costEstimate: '\$30 Admission',
            externalUrl: 'https://whitney.org/',
            externalUrlLabel: 'Exhibitions',
            location: LocationData(
              placeName: 'Whitney Museum of American Art',
              address: '99 Gansevoort St, New York, NY 10014',
              latitude: 40.7396,
              longitude: -74.0089,
            ),
            imageUrls: [
              'https://images.unsplash.com/photo-1518998053901-5348d3961a04?auto=format&fit=crop&w=600&q=80',
            ],
          ),
          PlanBlock(
            id: 'nyc_stop3',
            type: BlockType.placeEvent,
            size: BlockSize.featured,
            dayTag: 'Day 1',
            startTime: '06:30 PM',
            endTime: '08:30 PM',
            category: 'Nightlife',
            title: 'Aperitivo at Caffe Dante',
            subtitle: 'World-famous Negroni Sessions on MacDougal Street',
            location: LocationData(
              placeName: 'Dante NYC',
              address: '79-81 MacDougal St, New York, NY 10012',
              latitude: 40.7288,
              longitude: -74.0016,
            ),
          ),
        ],
      ),
      PlanModel(
        id: 'plan_amalfi_coast',
        slug: 'amalfi-summer-escape',
        title: 'Amalfi Coast Sun & Sea',
        subtitle: 'Cliffside lemon groves, Positano beach clubs & Ravello sunset concerts.',
        dateRangeLabel: 'July 18 – July 21',
        authorName: '@studio.soleil',
        coverImageUrl:
            'https://images.unsplash.com/photo-1533105079780-92b9be482077?auto=format&fit=crop&w=1200&q=80',
        avatarImageUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80',
        theme: PlanTheme.presets[2], // Lune Studio White
        updatedAt: now.subtract(const Duration(days: 1)),
        blocks: const [
          PlanBlock(
            id: 'ama_map',
            type: BlockType.mapOverview,
            size: BlockSize.featured,
            dayTag: 'Day 1',
            title: 'Amalfi Coastal Stops',
            subtitle: 'Positano & Ravello GPS pins',
          ),
          PlanBlock(
            id: 'ama_stop1',
            type: BlockType.placeEvent,
            size: BlockSize.featured,
            dayTag: 'Day 1',
            startTime: '10:30 AM',
            endTime: '03:00 PM',
            category: 'Activity',
            title: 'Positano Spiaggia Grande & Boat Charter',
            subtitle: 'Private Riva wooden boat along the Li Galli islands',
            location: LocationData(
              placeName: 'Positano Spiaggia Grande',
              address: 'Via del Brigantino, 84017 Positano SA, Italy',
              latitude: 40.6281,
              longitude: 14.4850,
            ),
            imageUrls: [
              'https://images.unsplash.com/photo-1533105079780-92b9be482077?auto=format&fit=crop&w=900&q=80',
            ],
          ),
          PlanBlock(
            id: 'ama_stop2',
            type: BlockType.placeEvent,
            size: BlockSize.standard,
            dayTag: 'Day 1',
            startTime: '05:30 PM',
            endTime: '07:30 PM',
            category: 'Activity',
            title: 'Villa Cimbrone Terrace of Infinity',
            subtitle: 'Panoramic cliffside gardens high above the Tyrrhenian Sea',
            location: LocationData(
              placeName: 'Villa Cimbrone Gardens',
              address: 'Via Santa Chiara 26, 84010 Ravello SA, Italy',
              latitude: 40.6433,
              longitude: 14.6114,
            ),
          ),
        ],
      ),
    ];
  }
}
