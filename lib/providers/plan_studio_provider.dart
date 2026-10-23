import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/plan_models.dart';
import '../services/cloud_api_service.dart';
import '../services/plan_repository.dart';

/// Preview viewport modes inside the Studio
enum StudioDevicePreview {
  mobileFrame, // Liinks.co style mobile card frame (430px wide)
  desktopCanvas, // Squarespace style full responsive web layout
}

/// Provider state manager for the Plaans app (directory + active studio editor + shared view)
class PlanStudioProvider extends ChangeNotifier {
  final PlanRepository _repository;
  final CloudApiService _cloudApi;
  final Uuid _uuid = const Uuid();

  List<PlanModel> _plans = [];
  PlanModel? _activePlan;
  String? _selectedDayFilter; // null means "All Days"
  String? _highlightedBlockId;
  StudioDevicePreview _devicePreview = StudioDevicePreview.mobileFrame;
  bool _isLoading = true;
  bool _isVisitorView = false;
  bool _showLandingHome = true;

  // Phase 2 Cloud & Creator Auth State
  CreatorUser? _creatorUser;
  bool _isBackendOnline = false;
  bool _isSyncingCloud = false;
  bool _isVisitorPinLocked = false;
  String? _pinUnlockError;

  PlanStudioProvider({
    PlanRepository? repository,
    CloudApiService? cloudApi,
  })  : _repository = repository ?? PlanRepository(),
        _cloudApi = cloudApi ?? CloudApiService() {
    _init();
  }

  List<PlanModel> get plans => List.unmodifiable(_plans);
  PlanModel? get activePlan => _activePlan;
  String? get selectedDayFilter => _selectedDayFilter;
  String? get highlightedBlockId => _highlightedBlockId;
  StudioDevicePreview get devicePreview => _devicePreview;
  bool get isLoading => _isLoading;
  bool get isVisitorView => _isVisitorView;
  bool get showLandingHome => _showLandingHome;
  CreatorUser? get creatorUser => _creatorUser;
  bool get isBackendOnline => _isBackendOnline;
  bool get isSyncingCloud => _isSyncingCloud;
  bool get isVisitorPinLocked => _isVisitorPinLocked;
  String? get pinUnlockError => _pinUnlockError;

  void setShowLandingHome(bool value) {
    _showLandingHome = value;
    notifyListeners();
  }

  /// Returns the blocks visible under the current day filter
  List<PlanBlock> get visibleBlocks {
    final plan = _activePlan;
    if (plan == null) return const [];
    if (_selectedDayFilter == null || _selectedDayFilter!.isEmpty) {
      return plan.blocks;
    }
    return plan.blocks.where((b) {
      if (b.type == BlockType.mapOverview) return true;
      return b.dayTag.trim().toLowerCase() ==
          _selectedDayFilter!.trim().toLowerCase();
    }).toList();
  }

  /// Returns all located blocks for the active day filter (or whole plan)
  List<PlanBlock> get visibleLocatedBlocks {
    return visibleBlocks.where((b) => b.hasLocation).toList();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    _plans = await _repository.loadAllPlans();
    if (_plans.isNotEmpty && _activePlan == null) {
      _activePlan = _plans.first;
    }
    _creatorUser = await _cloudApi.loadSavedCreator();
    _isLoading = false;
    notifyListeners();

    // Non-blocking check for local/remote Django + MongoDB API health
    _cloudApi.checkBackendHealth().then((online) {
      _isBackendOnline = online;
      notifyListeners();
    });
  }

  /// Selects a plan to edit in the Studio
  void selectPlan(String planId, {bool visitorMode = false}) {
    final found = _plans.where((p) => p.id == planId).firstOrNull;
    if (found != null) {
      _activePlan = found;
      _selectedDayFilter = null;
      _isVisitorView = visitorMode;
      _isVisitorPinLocked =
          visitorMode && found.visibility == PlanVisibility.pinProtected;
      _pinUnlockError = null;
      _showLandingHome = false;
      notifyListeners();
    }
  }

  /// Opens a plan from a shared slug or URL payload (queries Django + MongoDB API first, then local storage)
  Future<bool> openSharedPlan(String slugOrId, {String? encodedData}) async {
    _isLoading = true;
    _pinUnlockError = null;
    notifyListeners();

    // 1. Try resolving from Django + MongoDB API if no inline base64 payload was passed
    if (encodedData == null || encodedData.isEmpty) {
      final cloudResult = await _cloudApi.fetchPlanBySlug(
        slugOrId,
        currentUser: _creatorUser,
      );
      if (cloudResult != null) {
        if (cloudResult.requiresPin) {
          final fallbackLocal = await _repository.findBySlugOrId(slugOrId);
          _activePlan = fallbackLocal ??
              PlanModel(
                id: 'locked_$slugOrId',
                slug: slugOrId,
                title: cloudResult.lockedTitle ?? 'Private Itinerary',
                subtitle:
                    cloudResult.lockedSubtitle ?? 'Enter trip PIN to unlock',
                authorName: cloudResult.lockedAuthor ?? '@creator',
                theme: PlanTheme.presets.first,
                blocks: const [],
                updatedAt: DateTime.now(),
                visibility: PlanVisibility.pinProtected,
                hasPin: true,
              );
          _isVisitorView = true;
          _isVisitorPinLocked = true;
          _showLandingHome = false;
          _isLoading = false;
          notifyListeners();
          return true;
        } else if (cloudResult.plan != null) {
          _activePlan = cloudResult.plan;
          _selectedDayFilter = null;
          _isVisitorView = true;
          _isVisitorPinLocked = false;
          _showLandingHome = false;
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
    }

    // 2. Fallback to local repository / portable URL payload
    final plan = await _repository.findBySlugOrId(
      slugOrId,
      encodedData: encodedData,
    );
    _isLoading = false;
    if (plan != null) {
      _activePlan = plan;
      _selectedDayFilter = null;
      _isVisitorView = true;
      final isOwner =
          _creatorUser != null && plan.ownerUid == _creatorUser!.uid;
      _isVisitorPinLocked =
          plan.visibility == PlanVisibility.pinProtected && !isOwner;
      _showLandingHome = false;
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }

  void setVisitorView(bool value) {
    _isVisitorView = value;
    final plan = _activePlan;
    if (value && plan != null) {
      _isVisitorPinLocked = plan.visibility == PlanVisibility.pinProtected &&
          ((plan.pinCode?.isNotEmpty ?? false) || plan.hasPin);
    } else {
      _isVisitorPinLocked = false;
    }
    _pinUnlockError = null;
    notifyListeners();
  }

  /// Unlocks a PIN-protected plan when a visitor enters the 4–6 digit trip PIN
  Future<bool> unlockActivePlanWithPin(String pinCode) async {
    final current = _activePlan;
    if (current == null) return false;

    final result = await _cloudApi.unlockPinProtectedPlan(
      current.slug,
      pinCode: pinCode,
      localFallbackPlan: current,
    );

    if (result.plan != null) {
      _activePlan = result.plan;
      _isVisitorPinLocked = false;
      _pinUnlockError = null;
      notifyListeners();
      return true;
    }

    _pinUnlockError = result.error ?? 'Incorrect PIN code.';
    notifyListeners();
    return false;
  }

  /// Signs in the creator (via Firebase Auth or Dual-Mode Local Creator Account)
  /// and automatically syncs the active plan to the cloud.
  Future<CreatorUser> signInCreator({
    required String email,
    required String displayName,
    String? firebaseUid,
    String? firebaseIdToken,
  }) async {
    final user = await _cloudApi.signInCreator(
      email: email,
      displayName: displayName,
      firebaseUid: firebaseUid,
      firebaseIdToken: firebaseIdToken,
    );
    _creatorUser = user;
    notifyListeners();
    await publishActivePlanToCloud();
    return user;
  }

  Future<void> signOutCreator() async {
    await _cloudApi.signOutCreator();
    _creatorUser = null;
    notifyListeners();
  }

  /// Live vanity slug availability check (`plaans.co/<slug>`)
  Future<bool> checkSlugAvailability(String candidateSlug) async {
    final normalized = _slugify(candidateSlug);
    return _cloudApi.checkSlugAvailability(
      normalized,
      excludePlanId: _activePlan?.id,
      localPlans: _plans,
    );
  }

  /// Updates slug, visibility (`public`, `unlisted`, `pinProtected`), and PIN code on the active plan
  Future<void> updatePlanSharingConfig({
    String? slug,
    PlanVisibility? visibility,
    String? pinCode,
  }) async {
    final current = _activePlan;
    if (current == null) return;

    final newVisibility = visibility ?? current.visibility;
    final newPin = pinCode ?? current.pinCode;
    final updated = current.copyWith(
      slug: slug != null ? _slugify(slug) : current.slug,
      visibility: newVisibility,
      pinCode: newPin,
      hasPin: newVisibility == PlanVisibility.pinProtected &&
          (newPin != null && newPin.trim().isNotEmpty),
      updatedAt: DateTime.now(),
    );
    await _commitActivePlan(updated);
  }

  /// Publishes/syncs the active plan to the Django + MongoDB cloud backend
  Future<PlanModel?> publishActivePlanToCloud() async {
    final current = _activePlan;
    if (current == null) return null;

    var user = _creatorUser;
    user ??= await _cloudApi.signInCreator(
      email: 'creator@plaans.co',
      displayName: current.authorName.isNotEmpty
          ? current.authorName
          : 'Plaans Creator',
    );
    _creatorUser = user;

    _isSyncingCloud = true;
    notifyListeners();

    final synced = await _cloudApi.syncPlanToCloud(current, user: user);
    _isBackendOnline = await _cloudApi.checkBackendHealth();
    _isSyncingCloud = false;
    await _commitActivePlan(synced);
    return synced;
  }

  void setDevicePreview(StudioDevicePreview mode) {
    _devicePreview = mode;
    notifyListeners();
  }

  void setDayFilter(String? dayTag) {
    _selectedDayFilter = dayTag;
    notifyListeners();
  }

  void highlightBlock(String? blockId) {
    _highlightedBlockId = blockId;
    notifyListeners();
  }

  /// Creates a brand new Plan from a template or blank canvas
  Future<PlanModel> createNewPlan({
    required String title,
    String subtitle = 'Tap any block to customize locations, times, and links.',
    PlanTheme? theme,
    String? templateType,
  }) async {
    final id = 'plan_${_uuid.v4().substring(0, 8)}';
    final slug = _slugify(title);
    final chosenTheme = theme ?? PlanTheme.presets.first;

    List<PlanBlock> initialBlocks = [
      PlanBlock(
        id: 'blk_${_uuid.v4().substring(0, 6)}',
        type: BlockType.mapOverview,
        size: BlockSize.featured,
        dayTag: 'Day 1',
        title: '$title Route Map',
        subtitle: 'All event & place stops pinned with GPS links',
      ),
      PlanBlock(
        id: 'blk_${_uuid.v4().substring(0, 6)}',
        type: BlockType.dayHeader,
        size: BlockSize.standard,
        dayTag: 'Day 1',
        title: 'Day 1 — Kickoff & Highlights',
        subtitle: 'Morning & Afternoon Schedule',
      ),
      PlanBlock(
        id: 'blk_${_uuid.v4().substring(0, 6)}',
        type: BlockType.placeEvent,
        size: BlockSize.featured,
        dayTag: 'Day 1',
        startTime: '10:00 AM',
        endTime: '12:00 PM',
        category: 'Food & Drink',
        title: 'First Stop / Coffee & Meetup',
        subtitle: 'Edit this card to set your venue, address & GPS pin',
        description:
            'Add reservation links, photos, or notes so your group knows where to go.',
        location: const LocationData(
          placeName: 'Central Park Boathouse',
          address: 'East 72nd St & Park Drive North, New York, NY',
          latitude: 40.7753,
          longitude: -73.9688,
        ),
      ),
    ];

    final newPlan = PlanModel(
      id: id,
      slug: slug,
      title: title,
      subtitle: subtitle,
      dateRangeLabel: 'Upcoming Plan',
      authorName: '@creator',
      coverImageUrl:
          'https://images.unsplash.com/photo-1518998053901-5348d3961a04?auto=format&fit=crop&w=1200&q=80',
      theme: chosenTheme,
      blocks: initialBlocks,
      updatedAt: DateTime.now(),
    );

    _plans.insert(0, newPlan);
    _activePlan = newPlan;
    _selectedDayFilter = null;
    _isVisitorView = false;
    _showLandingHome = false;
    notifyListeners();
    await _repository.saveAllPlans(_plans);
    return newPlan;
  }

  /// Duplicates an existing plan (e.g. "Clone this Itinerary")
  Future<PlanModel?> duplicatePlan(PlanModel source) async {
    final cloned = source.copyWith(
      id: 'plan_${_uuid.v4().substring(0, 8)}',
      slug: '${source.slug}-copy',
      title: '${source.title} (Copy)',
      updatedAt: DateTime.now(),
    );
    _plans.insert(0, cloned);
    _activePlan = cloned;
    _isVisitorView = false;
    notifyListeners();
    await _repository.saveAllPlans(_plans);
    return cloned;
  }

  /// Deletes a plan
  Future<void> deletePlan(String planId) async {
    _plans.removeWhere((p) => p.id == planId);
    if (_activePlan?.id == planId) {
      _activePlan = _plans.firstOrNull;
    }
    notifyListeners();
    await _repository.deletePlan(planId);
  }

  /// Updates top-level Plan metadata (title, subtitle, slug, cover image, dates)
  Future<void> updatePlanHeader({
    String? title,
    String? subtitle,
    String? slug,
    String? dateRangeLabel,
    String? authorName,
    String? coverImageUrl,
    bool clearCoverImage = false,
    String? avatarImageUrl,
    bool clearAvatarImage = false,
  }) async {
    final current = _activePlan;
    if (current == null) return;

    final updated = current.copyWith(
      title: title,
      subtitle: subtitle,
      slug: slug != null ? _slugify(slug) : null,
      dateRangeLabel: dateRangeLabel,
      authorName: authorName,
      coverImageUrl: coverImageUrl,
      clearCoverImage: clearCoverImage,
      avatarImageUrl: avatarImageUrl,
      clearAvatarImage: clearAvatarImage,
      updatedAt: DateTime.now(),
    );
    await _commitActivePlan(updated);
  }

  /// Updates the active plan's visual theme
  Future<void> updateTheme(PlanTheme newTheme) async {
    final current = _activePlan;
    if (current == null) return;
    await _commitActivePlan(
      current.copyWith(theme: newTheme, updatedAt: DateTime.now()),
    );
  }

  /// Adds a new modular block to the active plan
  Future<PlanBlock?> addBlock(
    BlockType type, {
    int? insertIndex,
    String? dayTag,
  }) async {
    final current = _activePlan;
    if (current == null) return null;

    final activeDay = dayTag ?? _selectedDayFilter ?? 'Day 1';
    final id = 'blk_${_uuid.v4().substring(0, 6)}';

    PlanBlock newBlock;
    switch (type) {
      case BlockType.dayHeader:
        final nextDayNum = current.dayTags.length + 1;
        newBlock = PlanBlock(
          id: id,
          type: BlockType.dayHeader,
          size: BlockSize.standard,
          dayTag: 'Day $nextDayNum',
          title: 'Day $nextDayNum — New Day Schedule',
          subtitle: 'Add morning, afternoon & evening stops',
        );
        break;
      case BlockType.placeEvent:
        newBlock = PlanBlock(
          id: id,
          type: BlockType.placeEvent,
          size: BlockSize.standard,
          dayTag: activeDay,
          startTime: '12:30 PM',
          endTime: '02:00 PM',
          category: 'Food & Drink',
          title: 'New Place or Event Stop',
          subtitle: 'Tap to add venue address, GPS coordinates, photos & links',
          location: const LocationData(
            placeName: 'Shibuya Crossing',
            address: 'Shibuya City, Tokyo, Japan',
            latitude: 35.6595,
            longitude: 139.7004,
          ),
        );
        break;
      case BlockType.mapOverview:
        newBlock = PlanBlock(
          id: id,
          type: BlockType.mapOverview,
          size: BlockSize.featured,
          dayTag: activeDay,
          title: 'Interactive GPS Map & Route',
          subtitle: 'Plots all locations in your itinerary with 1-click GPS',
        );
        break;
      case BlockType.linkCard:
        newBlock = PlanBlock(
          id: id,
          type: BlockType.linkCard,
          size: BlockSize.halfWidth,
          dayTag: activeDay,
          title: 'Reservations / Tickets Link',
          subtitle: 'Tap to open external booking or resource',
          externalUrl: 'https://www.liinks.co',
          externalUrlLabel: 'Open Link',
        );
        break;
      case BlockType.photoGallery:
        newBlock = PlanBlock(
          id: id,
          type: BlockType.photoGallery,
          size: BlockSize.featured,
          dayTag: activeDay,
          title: 'Visual Moodboard / Uploaded Photos',
          subtitle: 'Showcase outfits, venue inspiration, or memories',
          imageUrls: const [
            'https://images.unsplash.com/photo-1533105079780-92b9be482077?auto=format&fit=crop&w=900&q=80',
            'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?auto=format&fit=crop&w=900&q=80',
          ],
        );
        break;
      case BlockType.textNote:
        newBlock = PlanBlock(
          id: id,
          type: BlockType.textNote,
          size: BlockSize.standard,
          dayTag: activeDay,
          title: 'Group Notes & Packing Checklist',
          subtitle: 'Important details for everyone',
          description:
              '• Dress code: Smart casual\n• Meet 15 mins early at the main entrance\n• Shared photo album link coming soon',
        );
        break;
    }

    final updatedBlocks = List<PlanBlock>.from(current.blocks);
    if (insertIndex != null &&
        insertIndex >= 0 &&
        insertIndex <= updatedBlocks.length) {
      updatedBlocks.insert(insertIndex, newBlock);
    } else {
      updatedBlocks.add(newBlock);
    }

    await _commitActivePlan(
      current.copyWith(blocks: updatedBlocks, updatedAt: DateTime.now()),
    );
    return newBlock;
  }

  /// Updates a specific block in the active plan
  Future<void> updateBlock(PlanBlock updatedBlock) async {
    final current = _activePlan;
    if (current == null) return;

    final updatedBlocks = current.blocks
        .map((b) => b.id == updatedBlock.id ? updatedBlock : b)
        .toList();

    await _commitActivePlan(
      current.copyWith(blocks: updatedBlocks, updatedAt: DateTime.now()),
    );
  }

  /// Deletes a block from the active plan
  Future<void> deleteBlock(String blockId) async {
    final current = _activePlan;
    if (current == null) return;

    final updatedBlocks =
        current.blocks.where((b) => b.id != blockId).toList();
    await _commitActivePlan(
      current.copyWith(blocks: updatedBlocks, updatedAt: DateTime.now()),
    );
  }

  /// Duplicates a block in place
  Future<void> duplicateBlock(String blockId) async {
    final current = _activePlan;
    if (current == null) return;

    final idx = current.blocks.indexWhere((b) => b.id == blockId);
    if (idx < 0) return;

    final orig = current.blocks[idx];
    final copy = orig.copyWith(
      id: 'blk_${_uuid.v4().substring(0, 6)}',
      title: '${orig.title} (Copy)',
    );

    final updatedBlocks = List<PlanBlock>.from(current.blocks)
      ..insert(idx + 1, copy);

    await _commitActivePlan(
      current.copyWith(blocks: updatedBlocks, updatedAt: DateTime.now()),
    );
  }

  /// Reorders blocks via Drag-and-Drop (compatible with `onReorderItem` where `newIndex` is already adjusted)
  Future<void> reorderBlocks(int oldIndex, int newIndex) async {
    final current = _activePlan;
    if (current == null) return;

    final visible = visibleBlocks;
    if (oldIndex < 0 || oldIndex >= visible.length) return;
    if (newIndex < 0) newIndex = 0;
    if (newIndex >= visible.length) newIndex = visible.length - 1;
    if (oldIndex == newIndex) return;

    final movedBlock = visible[oldIndex];
    final targetBlock = visible[newIndex];

    final allBlocks = List<PlanBlock>.from(current.blocks);
    final actualOldIdx = allBlocks.indexWhere((b) => b.id == movedBlock.id);
    final actualTargetIdx = allBlocks.indexWhere((b) => b.id == targetBlock.id);
    if (actualOldIdx < 0 || actualTargetIdx < 0) return;

    final item = allBlocks.removeAt(actualOldIdx);
    allBlocks.insert(actualTargetIdx, item);

    await _commitActivePlan(
      current.copyWith(blocks: allBlocks, updatedAt: DateTime.now()),
    );
  }

  Future<void> _commitActivePlan(PlanModel updated) async {
    _activePlan = updated;
    final idx = _plans.indexWhere((p) => p.id == updated.id);
    if (idx >= 0) {
      _plans[idx] = updated;
    } else {
      _plans.insert(0, updated);
    }
    notifyListeners();
    await _repository.savePlan(updated);
  }

  String _slugify(String input) {
    final clean = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return clean.isEmpty ? 'my-plan' : clean;
  }
}
