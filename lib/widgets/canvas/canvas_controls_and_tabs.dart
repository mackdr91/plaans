part of '../plan_page_canvas.dart';

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


