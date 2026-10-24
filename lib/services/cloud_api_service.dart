import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plan_models.dart';

/// Represents a signed-in Creator account (via Email/Password)
class CreatorUser {
  final String uid;
  final String email;
  final String displayName;
  final String authProvider; // 'email'
  final String? photoUrl;
  final String? idToken;
  final bool isFirebaseUser;

  const CreatorUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.authProvider = 'email',
    this.photoUrl,
    this.idToken,
    this.isFirebaseUser = false,
  });

  String get providerLabel => 'Email';

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (displayName.trim().isNotEmpty) {
      return displayName.trim()[0].toUpperCase();
    }
    if (email.trim().isNotEmpty) {
      return email.trim()[0].toUpperCase();
    }
    return 'C';
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'authProvider': authProvider,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (idToken != null) 'idToken': idToken,
        'isFirebaseUser': isFirebaseUser,
      };

  factory CreatorUser.fromJson(Map<String, dynamic> json) => CreatorUser(
        uid: json['uid'] as String? ?? 'creator_local',
        email: json['email'] as String? ?? '',
        displayName: json['displayName'] as String? ?? 'Creator',
        authProvider: json['authProvider'] as String? ?? 'email',
        photoUrl: json['photoUrl'] as String?,
        idToken: json['idToken'] as String?,
        isFirebaseUser: json['isFirebaseUser'] as bool? ?? false,
      );
}

/// Result of an authentication request (`register`, `login`, or `oauth`)
class AuthResult {
  final CreatorUser? user;
  final String? error;

  const AuthResult({this.user, this.error});

  bool get isSuccess => user != null && error == null;
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
    defaultValue: 'http://localhost:8088/api',
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

  Future<void> _persistCreator(CreatorUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_creatorStorageKey, jsonEncode(user.toJson()));
  }

  /// Registers a new Creator account with Email & Password (`POST /api/auth/register/`)
  Future<AuthResult> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = displayName.trim().isEmpty
        ? cleanEmail.split('@').first
        : displayName.trim();

    if (!cleanEmail.contains('@')) {
      return const AuthResult(error: 'Please enter a valid email address.');
    }
    if (password.length < 6) {
      return const AuthResult(
        error: 'Password must be at least 6 characters.',
      );
    }

    try {
      final uri = Uri.parse('$baseUrl/auth/register/');
      final res = await http
          .post(
            uri,
            headers: _buildHeaders(null),
            body: jsonEncode({
              'email': cleanEmail,
              'password': password,
              'displayName': cleanName,
            }),
          )
          .timeout(const Duration(milliseconds: 2800));

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 201 || res.statusCode == 200) {
        final userMap = body['user'] as Map<String, dynamic>;
        final token = body['token'] as String?;
        final user = CreatorUser.fromJson({
          ...userMap,
          'idToken': token,
          'isFirebaseUser': true,
        });
        await _persistCreator(user);
        return AuthResult(user: user);
      } else {
        return AuthResult(
          error: body['error'] as String? ?? 'Could not create account.',
        );
      }
    } catch (_) {
      // Offline / local fallback
      final user = await signInCreator(
        email: cleanEmail,
        displayName: cleanName,
        authProvider: 'email',
      );
      return AuthResult(user: user);
    }
  }

  /// Authenticates an existing Creator account with Email & Password (`POST /api/auth/login/`)
  Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (!cleanEmail.contains('@') || password.isEmpty) {
      return const AuthResult(
        error: 'Please enter your email and password.',
      );
    }

    try {
      final uri = Uri.parse('$baseUrl/auth/login/');
      final res = await http
          .post(
            uri,
            headers: _buildHeaders(null),
            body: jsonEncode({
              'email': cleanEmail,
              'password': password,
            }),
          )
          .timeout(const Duration(milliseconds: 2800));

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        final userMap = body['user'] as Map<String, dynamic>;
        final token = body['token'] as String?;
        final user = CreatorUser.fromJson({
          ...userMap,
          'idToken': token,
          'isFirebaseUser': true,
        });
        await _persistCreator(user);
        return AuthResult(user: user);
      } else {
        return AuthResult(
          error: body['error'] as String? ?? 'Invalid email or password.',
        );
      }
    } catch (_) {
      // Offline / local fallback
      final user = await signInCreator(
        email: cleanEmail,
        displayName: cleanEmail.split('@').first,
        authProvider: 'email',
      );
      return AuthResult(user: user);
    }
  }

  Future<CreatorUser> signInCreator({
    required String email,
    required String displayName,
    String authProvider = 'email',
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
      authProvider: authProvider,
      idToken: firebaseIdToken,
      isFirebaseUser: firebaseUid != null,
    );
    await _persistCreator(user);
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
