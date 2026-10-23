import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/plan_models.dart';
import '../providers/plan_studio_provider.dart';
import '../services/image_service.dart';
import '../services/maps_service.dart';
import 'block_editor_sheet.dart';
import 'block_widgets.dart';
import 'plan_image.dart';
import 'share_plan_dialog.dart';

/// Renders the complete Plan microsite following Liinks.co's signature centered profile layout:
/// - Top action icons (add/clone on left, share on right)
/// - Centered circular avatar (with optional cover backdrop & upload button)
/// - Centered title (editorial serif or crisp sans), handle, bio description
/// - Centered quick-action icon row (Google Maps full route, Apple Maps route, calendar, share)
/// - Centered Liinks pill navigation tabs (`All`, `Day 1`, `Day 2`...)
/// - Reorderable / Bento Grid of Blocks
class PlanPageCanvas extends StatelessWidget {
  final PlanModel plan;
  final PlanStudioProvider provider;
  final bool isEditable;
  final bool isCompactMobileFrame;

  const PlanPageCanvas({
    super.key,
    required this.plan,
    required this.provider,
    required this.isEditable,
    this.isCompactMobileFrame = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = plan.theme;
    final dayTags = plan.dayTags;
    final visibleBlocks = provider.visibleBlocks;
    final locatedBlocks = provider.visibleLocatedBlocks;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.backgroundColor,
            Color.lerp(theme.backgroundColor, theme.secondaryBackground, 0.45)!,
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isCompactMobileFrame ? 430 : 720,
          ),
          child: CustomScrollView(
            slivers: [
              // 1. Liinks.co-Style Centered Profile & Bio Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isCompactMobileFrame ? 16 : 24,
                    isCompactMobileFrame ? 14 : 24,
                    isCompactMobileFrame ? 16 : 24,
                    8,
                  ),
                  child: _LiinksCenteredProfileHeader(
                    plan: plan,
                    provider: provider,
                    isEditable: isEditable,
                    locatedBlocks: locatedBlocks,
                  ),
                ),
              ),

              // 2. Liinks.co-Style Centered Pill Tabs (like `Home | Shop | Weddings`)
              if (dayTags.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompactMobileFrame ? 16 : 24,
                      vertical: 8,
                    ),
                    child: _LiinksPillTabBar(
                      plan: plan,
                      dayTags: dayTags,
                      selectedDay: provider.selectedDayFilter,
                      onSelectDay: provider.setDayFilter,
                    ),
                  ),
                ),

              // 3. Reorderable or Grid Block Layout
              if (isEditable)
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompactMobileFrame ? 14 : 24,
                    vertical: 10,
                  ),
                  sliver: SliverReorderableList(
                    itemCount: visibleBlocks.length,
                    onReorderItem: (oldIdx, newIdx) =>
                        provider.reorderBlocks(oldIdx, newIdx),
                    itemBuilder: (context, idx) {
                      final block = visibleBlocks[idx];
                      return Padding(
                        key: ValueKey(block.id),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PlanBlockRenderer(
                          block: block,
                          theme: theme,
                          allLocatedBlocks: locatedBlocks,
                          isEditing: true,
                          isHighlighted:
                              provider.highlightedBlockId == block.id,
                          dragIndex: idx,
                          onEdit: () => BlockEditorModal.show(
                            context,
                            block: block,
                            onSave: provider.updateBlock,
                          ),
                          onDuplicate: () => provider.duplicateBlock(block.id),
                          onDelete: () => provider.deleteBlock(block.id),
                        ),
                      );
                    },
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompactMobileFrame ? 14 : 24,
                    vertical: 10,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _VisitorBlockLayout(
                      blocks: visibleBlocks,
                      theme: theme,
                      allLocatedBlocks: locatedBlocks,
                      isCompact: isCompactMobileFrame,
                    ),
                  ),
                ),

              // 4. Add Block Quick Bar (when in Studio edit mode)
              if (isEditable)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompactMobileFrame ? 14 : 24,
                      vertical: 8,
                    ),
                    child: _CanvasAddBlockBar(provider: provider, theme: theme),
                  ),
                ),

              // 5. Liinks.co-inspired Subtle Footer Pill
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 32,
                    horizontal: 24,
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: theme.textColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.link_rounded,
                            size: 14,
                            color: theme.textColor.withValues(alpha: 0.75),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'plaans.co/${plan.slug}',
                            style: planTextStyle(
                              theme,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: theme.textColor.withValues(alpha: 0.78),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Visitor view supports side-by-side `halfWidth` cards when screen space allows
class _VisitorBlockLayout extends StatelessWidget {
  final List<PlanBlock> blocks;
  final PlanTheme theme;
  final List<PlanBlock> allLocatedBlocks;
  final bool isCompact;

  const _VisitorBlockLayout({
    required this.blocks,
    required this.theme,
    required this.allLocatedBlocks,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fullWidth = constraints.maxWidth;
        final canPairHalfCards = !isCompact && fullWidth > 520;

        final children = <Widget>[];
        int i = 0;
        while (i < blocks.length) {
          final current = blocks[i];
          final isHalf = current.size == BlockSize.halfWidth ||
              (theme.layoutMode == PlanLayoutMode.bentoGrid &&
                  current.type == BlockType.linkCard);

          if (canPairHalfCards &&
              isHalf &&
              i + 1 < blocks.length &&
              (blocks[i + 1].size == BlockSize.halfWidth ||
                  blocks[i + 1].type == BlockType.linkCard)) {
            final next = blocks[i + 1];
            children.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: PlanBlockRenderer(
                        block: current,
                        theme: theme,
                        allLocatedBlocks: allLocatedBlocks,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PlanBlockRenderer(
                        block: next,
                        theme: theme,
                        allLocatedBlocks: allLocatedBlocks,
                      ),
                    ),
                  ],
                ),
              ),
            );
            i += 2;
          } else {
            children.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PlanBlockRenderer(
                  block: current,
                  theme: theme,
                  allLocatedBlocks: allLocatedBlocks,
                ),
              ),
            );
            i += 1;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      },
    );
  }
}

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

        const SizedBox(height: 14),

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

/// Liinks.co-Style Centered Pill Tabs (`All` | `Day 1` | `Day 2` — matching `Home | Shop | Weddings` on Wildstem)
class _LiinksPillTabBar extends StatelessWidget {
  final PlanModel plan;
  final List<String> dayTags;
  final String? selectedDay;
  final ValueChanged<String?> onSelectDay;

  const _LiinksPillTabBar({
    required this.plan,
    required this.dayTags,
    required this.selectedDay,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = plan.theme;
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          _LiinksPillTab(
            label: 'All Days',
            isSelected: selectedDay == null,
            theme: theme,
            onTap: () => onSelectDay(null),
          ),
          ...dayTags.map(
            (day) => _LiinksPillTab(
              label: day,
              isSelected: selectedDay == day,
              theme: theme,
              onTap: () => onSelectDay(day),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiinksPillTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final PlanTheme theme;
  final VoidCallback onTap;

  const _LiinksPillTab({
    required this.label,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg =
        theme.isDark ? Colors.white : Colors.white.withValues(alpha: 0.95);
    final inactiveBg = theme.textColor.withValues(alpha: 0.08);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? theme.textColor.withValues(alpha: 0.18)
                : Colors.transparent,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: planTextStyle(
            theme,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? const Color(0xFF1D1D28)
                : theme.textColor.withValues(alpha: 0.78),
          ),
        ),
      ),
    );
  }
}

class _CanvasAddBlockBar extends StatelessWidget {
  final PlanStudioProvider provider;
  final PlanTheme theme;

  const _CanvasAddBlockBar({required this.provider, required this.theme});

  @override
  Widget build(BuildContext context) {
    final cardTextCol = planCardTextColor(theme);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(theme.borderRadius),
        border: Border.all(
          color: theme.textColor.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        children: [
          Text(
            '+ Add a Block to Your Page',
            style: planTextStyle(
              theme,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: cardTextCol.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _AddBlockButton(
                label: 'Place / Event (GPS)',
                icon: Icons.add_location_alt_rounded,
                theme: theme,
                isPrimary: true,
                onTap: () async {
                  final created = await provider.addBlock(BlockType.placeEvent);
                  if (created != null && context.mounted) {
                    BlockEditorModal.show(
                      context,
                      block: created,
                      onSave: provider.updateBlock,
                    );
                  }
                },
              ),
              _AddBlockButton(
                label: 'Link Button',
                icon: Icons.link_rounded,
                theme: theme,
                onTap: () async {
                  final created = await provider.addBlock(BlockType.linkCard);
                  if (created != null && context.mounted) {
                    BlockEditorModal.show(
                      context,
                      block: created,
                      onSave: provider.updateBlock,
                    );
                  }
                },
              ),
              _AddBlockButton(
                label: 'Photo Block',
                icon: Icons.add_photo_alternate_rounded,
                theme: theme,
                onTap: () async {
                  final created =
                      await provider.addBlock(BlockType.photoGallery);
                  if (created != null && context.mounted) {
                    BlockEditorModal.show(
                      context,
                      block: created,
                      onSave: provider.updateBlock,
                    );
                  }
                },
              ),
              _AddBlockButton(
                label: 'Day Divider',
                icon: Icons.calendar_today_rounded,
                theme: theme,
                onTap: () => provider.addBlock(BlockType.dayHeader),
              ),
              _AddBlockButton(
                label: 'Route Map',
                icon: Icons.map_rounded,
                theme: theme,
                onTap: () => provider.addBlock(BlockType.mapOverview),
              ),
              _AddBlockButton(
                label: 'Folder / Note',
                icon: Icons.folder_open_rounded,
                theme: theme,
                onTap: () => provider.addBlock(BlockType.textNote),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddBlockButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final PlanTheme theme;
  final bool isPrimary;
  final VoidCallback onTap;

  const _AddBlockButton({
    required this.label,
    required this.icon,
    required this.theme,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardTextCol = planCardTextColor(theme);
    return Material(
      color: isPrimary
          ? const Color(0xFF1D1D28)
          : cardTextCol.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7.5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14.5,
                color: isPrimary ? Colors.white : cardTextCol,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isPrimary ? Colors.white : cardTextCol,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
