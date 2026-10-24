import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/plan_models.dart';
import '../providers/plan_studio_provider.dart';
import '../services/maps_service.dart';
import 'auth_modal_sheet.dart';

/// Share Plan Modal — allows customizing the vanity slug (`plaans.co/<slug>`) with live
/// availability check, setting access control (`Public`, `Unlisted`, `PIN Protected`),
/// syncing to the Django + MongoDB cloud backend, scanning a QR code, or copying share links.
class SharePlanDialog extends StatefulWidget {
  final PlanModel plan;
  final VoidCallback onPreviewPublicPage;

  const SharePlanDialog({
    super.key,
    required this.plan,
    required this.onPreviewPublicPage,
  });

  static Future<void> show(
    BuildContext context, {
    required PlanModel plan,
    required VoidCallback onPreviewPublicPage,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 640;
    if (isMobile) {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFFF7F3E8),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(color: Color(0xFF141413), width: 2),
        ),
        builder: (_) => SafeArea(
          child: SharePlanDialog(
            plan: plan,
            onPreviewPublicPage: onPreviewPublicPage,
          ),
        ),
      );
    }

    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFFF7F3E8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFF141413), width: 2),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: SharePlanDialog(
            plan: plan,
            onPreviewPublicPage: onPreviewPublicPage,
          ),
        ),
      ),
    );
  }

  @override
  State<SharePlanDialog> createState() => _SharePlanDialogState();
}

class _SharePlanDialogState extends State<SharePlanDialog> {
  bool _copiedShort = false;
  bool _copiedPortable = false;
  bool _slugAvailable = true;
  bool _checkingSlug = false;
  bool _publishedJustNow = false;

  late TextEditingController _slugCtrl;
  late TextEditingController _pinCtrl;
  late PlanVisibility _selectedVisibility;

  @override
  void initState() {
    super.initState();
    _slugCtrl = TextEditingController(text: widget.plan.slug);
    _pinCtrl = TextEditingController(text: widget.plan.pinCode ?? '');
    _selectedVisibility = widget.plan.visibility;
  }

  @override
  void dispose() {
    _slugCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  String get _currentSlug {
    final raw = _slugCtrl.text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return raw.isEmpty ? widget.plan.slug : raw;
  }

  String get _origin {
    final base = Uri.base;
    if (base.scheme.startsWith('http')) {
      return '${base.scheme}://${base.authority}';
    }
    return 'https://plaans.co';
  }

  String get _cleanShareUrl => '$_origin/#/p/$_currentSlug';

  String get _portableShareUrl =>
      '$_origin/#/p/$_currentSlug?data=${widget.plan.toShareablePayload()}';

  Future<void> _onSlugChanged(String value, PlanStudioProvider? provider) async {
    setState(() {
      _checkingSlug = true;
      _copiedShort = false;
    });
    if (provider != null) {
      final avail = await provider.checkSlugAvailability(value);
      if (mounted) {
        setState(() {
          _slugAvailable = avail;
          _checkingSlug = false;
        });
      }
    } else {
      setState(() => _checkingSlug = false);
    }
  }

  Future<void> _saveAndPublish(PlanStudioProvider? provider) async {
    if (provider == null) return;
    await provider.updatePlanSharingConfig(
      slug: _currentSlug,
      visibility: _selectedVisibility,
      pinCode: _pinCtrl.text.trim(),
    );
    await provider.publishActivePlanToCloud();
    if (mounted) {
      setState(() => _publishedJustNow = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlanStudioProvider?>();
    final activePlan = provider?.activePlan ?? widget.plan;

    final locations = activePlan.locatedBlocks
        .map((b) => b.location)
        .whereType<LocationData>()
        .toList();
    final googleMultiRoute =
        MapsService.buildGoogleMapsMultiStopRouteUrl(locations);
    final appleMultiRoute = MapsService.buildAppleMapsRouteUrl(locations);

    return Padding(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 22,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5A36),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0xFF141413), width: 1.5),
                  ),
                  child: const Icon(
                    Icons.ios_share_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Share & Publish Your Plan',
                        style: TextStyle(
                          fontSize: 18.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF141413),
                        ),
                      ),
                      Text(
                        'Custom vanity slug, access privacy & 1-tap GPS routes',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Creator Authentication Banner (Email & Password)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF141413), width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(
                    provider?.creatorUser != null
                        ? Icons.verified_user_rounded
                        : Icons.account_circle_outlined,
                    size: 20,
                    color: provider?.creatorUser != null
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF1D1D28),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider?.creatorUser != null
                              ? provider!.creatorUser!.displayName
                              : 'Creator Cloud Account',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF141413),
                          ),
                        ),
                        Text(
                          provider?.creatorUser != null
                              ? provider!.creatorUser!.email
                              : 'Sign in with Email & Password to own this slug',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF57534E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => AuthModalSheet.show(context),
                    child: Text(
                      provider?.creatorUser != null ? 'Account' : 'Sign In',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1D1D28),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Vanity Slug & Visibility Card (Phase 2 Hybrid Cloud Controls)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF141413), width: 1.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'VANITY URL SLUG',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Color(0xFF57534E),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _checkingSlug
                              ? const Color(0xFFF3F4F6)
                              : (_slugAvailable
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFEE2E2)),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _checkingSlug
                              ? 'CHECKING...'
                              : (_slugAvailable ? 'AVAILABLE' : 'TAKEN'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _slugAvailable
                                ? const Color(0xFF166534)
                                : const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _slugCtrl,
                    onChanged: (v) => _onSlugChanged(v, provider),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      prefixText: 'plaans.co/',
                      prefixStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF717182),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'ACCESS VISIBILITY',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Color(0xFF57534E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _VisibilityChip(
                        label: 'Public',
                        icon: Icons.public_rounded,
                        selected: _selectedVisibility == PlanVisibility.public,
                        onTap: () => setState(
                          () => _selectedVisibility = PlanVisibility.public,
                        ),
                      ),
                      _VisibilityChip(
                        label: 'Unlisted Link',
                        icon: Icons.link_rounded,
                        selected:
                            _selectedVisibility == PlanVisibility.unlisted,
                        onTap: () => setState(
                          () => _selectedVisibility = PlanVisibility.unlisted,
                        ),
                      ),
                      _VisibilityChip(
                        label: 'PIN Protected',
                        icon: Icons.lock_outline_rounded,
                        selected:
                            _selectedVisibility == PlanVisibility.pinProtected,
                        onTap: () => setState(
                          () =>
                              _selectedVisibility = PlanVisibility.pinProtected,
                        ),
                      ),
                    ],
                  ),
                  if (_selectedVisibility == PlanVisibility.pinProtected) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _pinCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: 'Set 4–6 Digit Group Trip PIN',
                        hintText: 'e.g. 4242',
                        counterText: '',
                        prefixIcon: const Icon(Icons.pin_outlined, size: 18),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activePlan.isCloudSynced ||
                                _publishedJustNow
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF1D1D28),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: (provider?.isSyncingCloud ?? false) ||
                              !_slugAvailable
                          ? null
                          : () => _saveAndPublish(provider),
                      icon: Icon(
                        (provider?.isSyncingCloud ?? false)
                            ? Icons.sync_rounded
                            : (activePlan.isCloudSynced || _publishedJustNow
                                ? Icons.cloud_done_rounded
                                : Icons.cloud_upload_outlined),
                        size: 17,
                      ),
                      label: Text(
                        (provider?.isSyncingCloud ?? false)
                            ? 'Syncing to Cloud...'
                            : (_publishedJustNow
                                ? 'Saved & Published to Cloud!'
                                : (activePlan.isCloudSynced
                                    ? 'Update Cloud Link & Privacy'
                                    : 'Publish to Cloud (Firebase + MongoDB)')),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // QR Code + Live Slug Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF141413), width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF141413),
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: QrImageView(
                      data: _cleanShareUrl,
                      size: 88,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _selectedVisibility == PlanVisibility.pinProtected
                                ? 'PIN-PROTECTED ITINERARY'
                                : 'PUBLIC ITINERARY LINK READY',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF166534),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          activePlan.title,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          _cleanShareUrl,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF57534E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Copy Clean Link Button
            _ShareOptionTile(
              title: _copiedShort
                  ? 'Copied Share Link to Clipboard!'
                  : 'Copy Clean Shareable Link',
              subtitle: _cleanShareUrl,
              icon: _copiedShort ? Icons.check_circle : Icons.link_rounded,
              accentColor: _copiedShort
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF141413),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: _cleanShareUrl));
                setState(() => _copiedShort = true);
              },
            ),
            const SizedBox(height: 10),

            // Copy Self-Contained Portable URL
            _ShareOptionTile(
              title: _copiedPortable
                  ? 'Copied Portable Full-Plan URL!'
                  : 'Copy Self-Contained Portable Link',
              subtitle:
                  'Embeds the entire itinerary & theme inside the URL so friends can open it anywhere',
              icon: _copiedPortable
                  ? Icons.check_circle
                  : Icons.rocket_launch_rounded,
              accentColor: _copiedPortable
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFFF5A36),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: _portableShareUrl));
                setState(() => _copiedPortable = true);
              },
            ),

            if (googleMultiRoute != null || appleMultiRoute != null) ...[
              const SizedBox(height: 14),
              const Text(
                'SHARE DIRECT MULTI-STOP GPS ROUTE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                  color: Color(0xFF57534E),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (googleMultiRoute != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1A73E8),
                          side: const BorderSide(
                            color: Color(0xFF1A73E8),
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => launchUrl(
                          Uri.parse(googleMultiRoute),
                          mode: LaunchMode.externalApplication,
                        ),
                        icon: const Icon(Icons.map_rounded, size: 16),
                        label: const Text(
                          'Google Maps Route',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  if (googleMultiRoute != null && appleMultiRoute != null)
                    const SizedBox(width: 10),
                  if (appleMultiRoute != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1C1C1E),
                          side: const BorderSide(
                            color: Color(0xFF1C1C1E),
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => launchUrl(
                          Uri.parse(appleMultiRoute),
                          mode: LaunchMode.externalApplication,
                        ),
                        icon: const Icon(Icons.apple_rounded, size: 16),
                        label: const Text(
                          'Apple Maps Route',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF141413),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                widget.onPreviewPublicPage();
              },
              icon: const Icon(Icons.visibility_rounded, size: 18),
              label: const Text(
                'Open Live Shared Visitor View',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisibilityChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _VisibilityChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1D1D28) : const Color(0xFFF4F4F8),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF1D1D28) : const Color(0xFFDCDCE6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13.5,
              color: selected ? Colors.white : const Color(0xFF475569),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : const Color(0xFF1D1D28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _ShareOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF141413), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF57534E),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.copy_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
