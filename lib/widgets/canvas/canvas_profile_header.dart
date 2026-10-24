part of '../plan_page_canvas.dart';

/// Exact Liinks.co Profile Header:
/// - Top circular glass action buttons (`+` on left, `share` on right)
/// - Centered circular avatar (`88x88`) with optional photo upload
/// - Centered display title, handle/dates, and centered bio text
/// - Centered row of minimal quick-action icons (Google Maps Route, Apple Maps Route, Share, Edit)
class _LiinksCenteredProfileHeader extends StatelessWidget {
  final PlanModel plan;
  final PlanStudioProvider provider;
  final bool isEditable;
  final List<PlanBlock> locatedBlocks;

  const _LiinksCenteredProfileHeader({
    required this.plan,
    required this.provider,
    required this.isEditable,
    required this.locatedBlocks,
  });

  @override
  Widget build(BuildContext context) {
    final theme = plan.theme;
    final avatarSource = plan.avatarImageUrl?.isNotEmpty == true
        ? plan.avatarImageUrl!
        : (plan.coverImageUrl?.isNotEmpty == true ? plan.coverImageUrl! : null);

    final locations =
        locatedBlocks.map((b) => b.location).whereType<LocationData>().toList();
    final googleMultiUrl =
        MapsService.buildGoogleMapsMultiStopRouteUrl(locations);
    final appleMultiUrl = MapsService.buildAppleMapsRouteUrl(locations);

    return Column(
      children: [
        // Top Corner Circular Glass Action Row (just like Liinks.co phone cards)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _CircleHeaderButton(
              icon: isEditable
                  ? Icons.edit_outlined
                  : Icons.person_add_alt_1_rounded,
              tooltip: isEditable ? 'Edit Plan Profile' : 'Clone this Plan',
              theme: theme,
              onTap: () {
                if (isEditable) {
                  _showEditHeaderDialog(context, plan, provider);
                } else {
                  provider.duplicatePlan(plan);
                }
              },
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isEditable)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _CircleHeaderButton(
                      icon: Icons.add_a_photo_outlined,
                      tooltip: 'Upload Profile / Cover Photo',
                      theme: theme,
                      onTap: () async {
                        final uploaded =
                            await ImageService.pickImageAsDataUrl();
                        if (uploaded != null) {
                          provider.updatePlanHeader(
                            avatarImageUrl: uploaded,
                            coverImageUrl: uploaded,
                          );
                        }
                      },
                    ),
                  ),
                _CircleHeaderButton(
                  icon: Icons.share_outlined,
                  tooltip: 'Share Plan & QR Code',
                  theme: theme,
                  onTap: () => SharePlanDialog.show(
                    context,
                    plan: plan,
                    onPreviewPublicPage: () => provider.setVisitorView(true),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Centered Circular Avatar (like Joy the Baker & Wildstem Flower Studio)
        GestureDetector(
          onTap: isEditable
              ? () async {
                  final uploaded = await ImageService.pickImageAsDataUrl();
                  if (uploaded != null) {
                    provider.updatePlanHeader(
                      avatarImageUrl: uploaded,
                      coverImageUrl: uploaded,
                    );
                  }
                }
              : null,
          child: Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.primaryAccent,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.85),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: avatarSource != null
                ? UniversalPlanImage(
                    imageUrl: avatarSource,
                    width: 92,
                    height: 92,
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: Text(
                      plan.title.isNotEmpty ? plan.title[0].toUpperCase() : 'P',
                      style: planTextStyle(
                        theme,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 14),

        // Centered Title
        Text(
          plan.title,
          textAlign: TextAlign.center,
          style: planTextStyle(
            theme,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            isDisplayHeading: true,
            height: 1.2,
          ),
        ),

        // Centered Author Handle & Date Range Subtitle
        if (plan.authorName.isNotEmpty || plan.dateRangeLabel.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            [
              if (plan.authorName.isNotEmpty) plan.authorName,
              if (plan.dateRangeLabel.isNotEmpty) plan.dateRangeLabel,
            ].join('  ·  '),
            textAlign: TextAlign.center,
            style: planTextStyle(
              theme,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: theme.textColor.withValues(alpha: 0.72),
            ),
          ),
        ],

        // Centered Bio / Itinerary Description
        if (plan.subtitle.isNotEmpty) ...[
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              plan.subtitle,
              textAlign: TextAlign.center,
              style: planTextStyle(
                theme,
                fontSize: 13.5,
                height: 1.45,
                color: theme.textColor.withValues(alpha: 0.84),
              ),
            ),
          ),
        ],

        // At-a-Glance Trip Summary & Visited Progress Strip
        const SizedBox(height: 12),
        _TripAtAGlanceSummaryPill(
          plan: plan,
          provider: provider,
          theme: theme,
        ),

        const SizedBox(height: 12),

        // Centered Social / Quick-Action Icon Row (matching Liinks' icon bar under bio)
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 8,
          children: [
            if (googleMultiUrl != null)
              _BioQuickIcon(
                icon: Icons.map_outlined,
                tooltip: 'Open Full Route in Google Maps (${locations.length} stops)',
                color: theme.textColor,
                onTap: () => launchUrl(
                  Uri.parse(googleMultiUrl),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            if (appleMultiUrl != null)
              _BioQuickIcon(
                icon: Icons.explore_outlined,
                tooltip: 'Open Route in Apple Maps GPS',
                color: theme.textColor,
                onTap: () => launchUrl(
                  Uri.parse(appleMultiUrl),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            _BioQuickIcon(
              icon: Icons.qr_code_2_rounded,
              tooltip: 'Show Share QR Code',
              color: theme.textColor,
              onTap: () => SharePlanDialog.show(
                context,
                plan: plan,
                onPreviewPublicPage: () => provider.setVisitorView(true),
              ),
            ),
            if (isEditable)
              _BioQuickIcon(
                icon: Icons.tune_rounded,
                tooltip: 'Edit Profile Title & Bio',
                color: theme.textColor,
                onTap: () => _showEditHeaderDialog(context, plan, provider),
              ),
          ],
        ),
      ],
    );
  }

  void _showEditHeaderDialog(
    BuildContext context,
    PlanModel plan,
    PlanStudioProvider provider,
  ) {
    final titleCtrl = TextEditingController(text: plan.title);
    final subCtrl = TextEditingController(text: plan.subtitle);
    final dateCtrl = TextEditingController(text: plan.dateRangeLabel);
    final authorCtrl = TextEditingController(text: plan.authorName);
    final slugCtrl = TextEditingController(text: plan.slug);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Edit Profile Header & Slug',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Plan / Profile Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bio / Itinerary Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: dateCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Dates / Duration',
                          hintText: 'Nov 14 – Nov 16',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: authorCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Creator Handle',
                          hintText: '@yourname',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: slugCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Custom URL Slug (plaans.co/...)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D1D28),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              provider.updatePlanHeader(
                title: titleCtrl.text.trim(),
                subtitle: subCtrl.text.trim(),
                dateRangeLabel: dateCtrl.text.trim(),
                authorName: authorCtrl.text.trim(),
                slug: slugCtrl.text.trim(),
              );
              Navigator.of(ctx).pop();
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}

class _CircleHeaderButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final PlanTheme theme;
  final VoidCallback onTap;

  const _CircleHeaderButton({
    required this.icon,
    required this.tooltip,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.textColor.withValues(alpha: 0.09),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: theme.textColor.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}

class _BioQuickIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _BioQuickIcon({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 21, color: color.withValues(alpha: 0.88)),
        ),
      ),
    );
  }
}


/// At-a-Glance Trip Summary & Visited Progress Bar (`3 Days · 6 Stops · Est. $73 · 2/6 Visited`)
class _TripAtAGlanceSummaryPill extends StatelessWidget {
  final PlanModel plan;
  final PlanStudioProvider provider;
  final PlanTheme theme;

  const _TripAtAGlanceSummaryPill({
    required this.plan,
    required this.provider,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final daysCount = plan.dayTags.length;
    final stopsCount = provider.totalPlaceStopsCount;
    final doneCount = provider.completedStopsCount;
    final budgetLabel = provider.estimatedTotalBudgetLabel;

    final metrics = <String>[
      if (daysCount > 0) '$daysCount ${daysCount == 1 ? 'Day' : 'Days'}',
      '$stopsCount ${stopsCount == 1 ? 'Stop' : 'Stops'}',
      ?budgetLabel,
      if (doneCount > 0) '$doneCount/$stopsCount Visited ✓',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: theme.textColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.textColor.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        metrics.join('   ·   '),
        textAlign: TextAlign.center,
        style: planTextStyle(
          theme,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: theme.textColor.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}
