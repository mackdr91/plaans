import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plan_models.dart';

/// Represents a signed-in Creator account (via Firebase Auth or Dual-Mode Local Auth)
class CreatorUser {
  final String uid;
  final String email;
  final String displayName;
  final String? idToken;
  final bool isFirebaseUser;

  const CreatorUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.idToken,
    this.isFirebaseUser = false,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        if (idToken != null) 'idToken': idToken,
        'isFirebaseUser': isFirebaseUser,
      };

  factory CreatorUser.fromJson(Map<String, dynamic> json) => CreatorUser(
        uid: json['uid'] as String? ?? 'creator_local',
        email: json['email'] as String? ?? '',
        displayName: json['displayName'] as String? ?? 'Creator',
        idToken: json['idToken'] as String?,
        isFirebaseUser: json['isFirebaseUser'] as bool? ?? false,
      );
}

/// Result of resolving a plan by slug (`plaans.co/<slug>`)
class SlugLookupResult {
  final PlanModel? plan;
  final bool requiresPin;
  final String? lockedTitle;
  final String? lockedSubtitle;
  final String? lockedAuthor;
  final String? error;

  const SlugLookupResult({
    this.plan,
    this.requiresPin = false,
    this.lockedTitle,
    this.lockedSubtitle,
    this.lockedAuthor,
    this.error,
  });
}

/// Dual-Mode Cloud API Client for the Django + MongoDB backend (`backend/`)
/// and Firebase Auth/Storage integration.
class CloudApiService {
  static const String baseUrl = String.fromEnvironment(
    'PLAANS_API_URL',
    defaultValue: 'http://localhost:8000/api',
  );

  static const String _creatorStorageKey = 'plaans_creator_user_v1';

  Future<CreatorUser?> loadSavedCreator() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_creatorStorageKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return CreatorUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<CreatorUser> signInCreator({
    required String email,
    required String displayName,
    String? firebaseUid,
    String? firebaseIdToken,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final slugified = normalizedEmail.replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final user = CreatorUser(
      uid: firebaseUid ?? 'local_$slugified',
      email: normalizedEmail,
      displayName: displayName.trim().isEmpty
          ? normalizedEmail.split('@').first
          : displayName.trim(),
      idToken: firebaseIdToken,
      isFirebaseUser: firebaseUid != null,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_creatorStorageKey, jsonEncode(user.toJson()));
    return user;
  }

  Future<void> signOutCreator() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_creatorStorageKey);
  }

  Map<String, String> _buildHeaders(CreatorUser? user) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (user != null) {
      if (user.idToken != null && user.idToken!.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${user.idToken}';
      } else {
        headers['Authorization'] = 'Bearer ${user.uid}';
      }
      headers['X-Plaans-Uid'] = user.uid;
      headers['X-Plaans-Email'] = user.email;
    }
    return headers;
  }

  /// Checks if the Django + MongoDB backend is reachable
  Future<bool> checkBackendHealth() async {
    try {
      final uri = Uri.parse('$baseUrl/health/');
      final res = await http
          .get(uri)
          .timeout(const Duration(milliseconds: 1500));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Checks if a vanity slug (`plaans.co/<slug>`) is available in MongoDB
  Future<bool> checkSlugAvailability(
    String slug, {
    String? excludePlanId,
    List<PlanModel> localPlans = const [],
  }) async {
    final cleanSlug = slug.trim().toLowerCase();
    if (cleanSlug.isEmpty) return false;

    try {
      final query = excludePlanId != null ? '?excludeId=$excludePlanId' : '';
      final uri = Uri.parse('$baseUrl/plans/check-slug/$cleanSlug/$query');
      final res = await http
          .get(uri)
          .timeout(const Duration(milliseconds: 1800));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data['available'] as bool? ?? true;
      }
    } catch (_) {
      // Fallback to checking local plans when offline
    }

    return !localPlans.any(
      (p) => p.slug.toLowerCase() == cleanSlug && p.id != excludePlanId,
    );
  }

  /// Syncs/publishes a `PlanModel` to the Django + MongoDB API.
  /// Gracefully returns a locally-marked synced plan if the local backend server is not running.
  Future<PlanModel> syncPlanToCloud(
    PlanModel plan, {
    required CreatorUser user,
  }) async {
    final payload = plan
        .copyWith(
          ownerUid: user.uid,
          isCloudSynced: true,
          updatedAt: DateTime.now(),
        )
        .toJson();

    try {
      final uri = Uri.parse('$baseUrl/plans/');
      final res = await http
          .post(
            uri,
            headers: _buildHeaders(user),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(milliseconds: 2500));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final savedMap = body['plan'] as Map<String, dynamic>?;
        if (savedMap != null) {
          return PlanModel.fromJson(savedMap).copyWith(
            pinCode: plan.pinCode,
            isCloudSynced: true,
          );
        }
      }
    } catch (_) {
      // Graceful dual-mode fallback when Django server is offline
    }

    return plan.copyWith(
      ownerUid: user.uid,
      isCloudSynced: true,
      hasPin: plan.visibility == PlanVisibility.pinProtected &&
          (plan.pinCode?.isNotEmpty ?? false),
      updatedAt: DateTime.now(),
    );
  }

  /// Fetches a shared plan by slug from the Django + MongoDB API
  Future<SlugLookupResult?> fetchPlanBySlug(
    String slug, {
    String? pinCode,
    CreatorUser? currentUser,
  }) async {
    try {
      final query = (pinCode != null && pinCode.isNotEmpty)
          ? '?pin=${Uri.encodeQueryComponent(pinCode)}'
          : '';
      final uri = Uri.parse('$baseUrl/plans/by-slug/${slug.trim()}/$query');
      final res = await http
          .get(uri, headers: _buildHeaders(currentUser))
          .timeout(const Duration(milliseconds: 2000));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final requiresPin = data['requiresPin'] as bool? ?? false;
        if (requiresPin) {
          return SlugLookupResult(
            requiresPin: true,
            lockedTitle: data['title'] as String?,
            lockedSubtitle: data['subtitle'] as String?,
            lockedAuthor: data['authorName'] as String?,
          );
        }
        final planJson = data['plan'] as Map<String, dynamic>?;
        if (planJson != null) {
          return SlugLookupResult(plan: PlanModel.fromJson(planJson));
        }
      }
    } catch (_) {
      // Offline / local fallback handled by caller
    }
    return null;
  }

  /// Unlocks a PIN-protected plan against the Django + MongoDB API
  Future<SlugLookupResult> unlockPinProtectedPlan(
    String slug, {
    required String pinCode,
    PlanModel? localFallbackPlan,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/plans/by-slug/${slug.trim()}/unlock/');
      final res = await http
          .post(
            uri,
            headers: _buildHeaders(null),
            body: jsonEncode({'pinCode': pinCode.trim()}),
          )
          .timeout(const Duration(milliseconds: 2000));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final planJson = data['plan'] as Map<String, dynamic>?;
        if (planJson != null) {
          return SlugLookupResult(plan: PlanModel.fromJson(planJson));
        }
      } else if (res.statusCode == 403) {
        return const SlugLookupResult(
          requiresPin: true,
          error: 'Incorrect PIN code. Please try again.',
        );
      }
    } catch (_) {
      // Fallback to verifying against local plan in dual-mode
    }

    if (localFallbackPlan != null) {
      if ((localFallbackPlan.pinCode ?? '').trim() == pinCode.trim()) {
        return SlugLookupResult(plan: localFallbackPlan);
      }
      return const SlugLookupResult(
        requiresPin: true,
        error: 'Incorrect PIN code. Please try again.',
      );
    }

    return const SlugLookupResult(
      requiresPin: true,
      error: 'Unable to verify PIN right now.',
    );
  }
}
