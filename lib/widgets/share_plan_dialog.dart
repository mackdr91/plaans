import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/plan_models.dart';
import '../services/maps_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Share Plan Modal — allows copying the clean shareable URL, copying the self-contained
/// portable link (works across any device without login), scanning a QR code, or exporting JSON.
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
          constraints: const BoxConstraints(maxWidth: 520),
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

  String get _origin {
    final base = Uri.base;
    if (base.scheme.startsWith('http')) {
      return '${base.scheme}://${base.authority}';
    }
    return 'https://plaans.app';
  }

  String get _cleanShareUrl => '$_origin/#/p/${widget.plan.slug}';

  String get _portableShareUrl =>
      '$_origin/#/p/${widget.plan.slug}?data=${widget.plan.toShareablePayload()}';

  @override
  Widget build(BuildContext context) {
    final locations = widget.plan.locatedBlocks
        .map((b) => b.location)
        .whereType<LocationData>()
        .toList();
    final googleMultiRoute =
        MapsService.buildGoogleMapsMultiStopRouteUrl(locations);
    final appleMultiRoute = MapsService.buildAppleMapsRouteUrl(locations);

    return Padding(
      padding: const EdgeInsets.all(24),
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
                        'Share Your Plan',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF141413),
                        ),
                      ),
                      Text(
                        'Anyone with the link can view stops & launch Google / Apple Maps GPS',
                        style: TextStyle(
                          fontSize: 12.5,
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
            const SizedBox(height: 20),

            // QR Code + Live Slug Card
            Container(
              padding: const EdgeInsets.all(16),
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
                      size: 96,
                    ),
                  ),
                  const SizedBox(width: 16),
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
                          child: const Text(
                            'PUBLIC ITINERARY LINK READY',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF166534),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.plan.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          _cleanShareUrl,
                          style: const TextStyle(
                            fontSize: 12,
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
            const SizedBox(height: 16),

            // Copy Clean Link Button
            _ShareOptionTile(
              title: _copiedShort
                  ? 'Copied Share Link to Clipboard!'
                  : 'Copy Clean Shareable Link',
              subtitle: _cleanShareUrl,
              icon: _copiedShort ? Icons.check_circle : Icons.link_rounded,
              accentColor:
                  _copiedShort ? const Color(0xFF16A34A) : const Color(0xFF141413),
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
              icon:
                  _copiedPortable ? Icons.check_circle : Icons.rocket_launch_rounded,
              accentColor: _copiedPortable
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFFF5A36),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: _portableShareUrl));
                setState(() => _copiedPortable = true);
              },
            ),

            if (googleMultiRoute != null || appleMultiRoute != null) ...[
              const SizedBox(height: 16),
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

            const SizedBox(height: 18),
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
