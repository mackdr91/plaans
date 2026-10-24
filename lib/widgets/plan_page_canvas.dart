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


part 'canvas/canvas_profile_header.dart';
part 'canvas/canvas_controls_and_tabs.dart';
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
                      vertical: 6,
                    ),
                    child: _LiinksPillTabBar(
                      plan: plan,
                      dayTags: dayTags,
                      selectedDay: provider.selectedDayFilter,
                      onSelectDay: provider.setDayFilter,
                    ),
                  ),
                ),

              // 2b. Instant Category Filter Chips (when multiple stop categories exist)
              if (provider.availableCategories.length > 1)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompactMobileFrame ? 16 : 24,
                      vertical: 4,
                    ),
                    child: _CategoryFilterStrip(
                      theme: theme,
                      categories: provider.availableCategories,
                      selectedCategory: provider.selectedCategoryFilter,
                      onSelectCategory: provider.setCategoryFilter,
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
                      final nextLoc = _findNextStopLocation(visibleBlocks, idx);
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
                          isCompleted: provider.isBlockCompleted(block.id),
                          onToggleCompleted: () =>
                              provider.toggleBlockCompleted(block.id),
                          nextStopLocation: nextLoc,
                          planTitle: plan.title,
                          dragIndex: idx,
                          onEdit: () => BlockEditorModal.show(
                            context,
                            block: block,
                            onSave: provider.updateBlock,
                          ),
                          onDuplicate: () => provider.duplicateBlock(block.id),
                          onDelete: () {
                            final removedTitle = block.title;
                            provider.deleteBlock(block.id);
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Text('Deleted "$removedTitle"'),
                                action: SnackBarAction(
                                  label: 'UNDO',
                                  onPressed: () => provider.undo(),
                                ),
                              ),
                            );
                          },
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
                      provider: provider,
                      planTitle: plan.title,
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

LocationData? _findNextStopLocation(List<PlanBlock> blocks, int currentIndex) {
  final current = blocks[currentIndex];
  if (current.type != BlockType.placeEvent || !current.hasLocation) {
    return null;
  }
  for (int j = currentIndex + 1; j < blocks.length; j++) {
    final candidate = blocks[j];
    if (candidate.type == BlockType.placeEvent && candidate.hasLocation) {
      return candidate.location;
    }
  }
  return null;
}

/// Instant Category Filter Chip Strip (`All Types`, `Food & Drink`, `Sightseeing`, etc.)
class _CategoryFilterStrip extends StatelessWidget {
  final PlanTheme theme;
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onSelectCategory;

  const _CategoryFilterStrip({
    required this.theme,
    required this.categories,
    required this.selectedCategory,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CategoryChipPill(
              label: 'All Stops',
              isSelected: selectedCategory == null,
              theme: theme,
              onTap: () => onSelectCategory(null),
            ),
            ...categories.map(
              (cat) => Padding(
                padding: const EdgeInsets.only(left: 6),
                child: _CategoryChipPill(
                  label: cat,
                  isSelected: selectedCategory == cat,
                  theme: theme,
                  onTap: () => onSelectCategory(
                    selectedCategory == cat ? null : cat,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChipPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final PlanTheme theme;
  final VoidCallback onTap;

  const _CategoryChipPill({
    required this.label,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryAccent
              : theme.textColor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: planTextStyle(
            theme,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : theme.textColor.withValues(alpha: 0.78),
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
  final PlanStudioProvider provider;
  final String planTitle;

  const _VisitorBlockLayout({
    required this.blocks,
    required this.theme,
    required this.allLocatedBlocks,
    required this.isCompact,
    required this.provider,
    required this.planTitle,
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
                        isCompleted: provider.isBlockCompleted(current.id),
                        onToggleCompleted: () =>
                            provider.toggleBlockCompleted(current.id),
                        nextStopLocation: _findNextStopLocation(blocks, i),
                        planTitle: planTitle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PlanBlockRenderer(
                        block: next,
                        theme: theme,
                        allLocatedBlocks: allLocatedBlocks,
                        isCompleted: provider.isBlockCompleted(next.id),
                        onToggleCompleted: () =>
                            provider.toggleBlockCompleted(next.id),
                        nextStopLocation: _findNextStopLocation(blocks, i + 1),
                        planTitle: planTitle,
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
                  isCompleted: provider.isBlockCompleted(current.id),
                  onToggleCompleted: () =>
                      provider.toggleBlockCompleted(current.id),
                  nextStopLocation: _findNextStopLocation(blocks, i),
                  planTitle: planTitle,
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

