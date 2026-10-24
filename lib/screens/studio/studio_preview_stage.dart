part of '../studio_screen.dart';

/// Clean White Inspector Panel with Liinks.co's signature `Content | Styles` Segmented Pill Header
class _LiinksInspectorPanel extends StatelessWidget {
  final int activeSection;
  final ValueChanged<int> onSelectSection;
  final PlanModel plan;
  final PlanStudioProvider provider;

  const _LiinksInspectorPanel({
    required this.activeSection,
    required this.onSelectSection,
    required this.plan,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Color(0xFFEAEAF0), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Top Segmented Pill Switcher (`Content` | `Styles` + secondary `GPS` | `Plans` pills)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F7FA),
              border: Border(
                bottom: BorderSide(color: Color(0xFFEBEBF2)),
              ),
            ),
            child: Column(
              children: [
                // Primary `Content` | `Styles` Segmented Pill (Exact Liinks.co match)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEF4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SegmentedTabPill(
                          label: 'Content',
                          isSelected: activeSection == 0,
                          onTap: () => onSelectSection(0),
                        ),
                      ),
                      Expanded(
                        child: _SegmentedTabPill(
                          label: 'Styles',
                          isSelected: activeSection == 1,
                          onTap: () => onSelectSection(1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Secondary Quick Switchers for GPS Hub & Saved Plans
                Row(
                  children: [
                    Expanded(
                      child: _SubSectionChip(
                        icon: Icons.pin_drop_outlined,
                        label: 'GPS Stops (${plan.locatedBlocks.length})',
                        isSelected: activeSection == 2,
                        onTap: () => onSelectSection(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SubSectionChip(
                        icon: Icons.folder_copy_outlined,
                        label: 'Plans (${provider.plans.length})',
                        isSelected: activeSection == 3,
                        onTap: () => onSelectSection(3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Inspector Body
          Expanded(
            child: IndexedStack(
              index: activeSection,
              children: [
                _BlocksManagerTab(plan: plan, provider: provider),
                _LiinksStylesDesignerTab(plan: plan, provider: provider),
                _GpsLocationsDirectoryTab(plan: plan, provider: provider),
                _SavedPlansDirectoryTab(plan: plan, provider: provider),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedTabPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentedTabPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: const Color(0xFF1D1D28),
          ),
        ),
      ),
    );
  }
}

class _SubSectionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SubSectionChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1D1D28) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E2EA)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13.5,
              color: isSelected ? Colors.white : const Color(0xFF646474),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF1D1D28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Right Live Preview Stage with top `[Phone | Desktop]` switcher and
/// realistic Liinks Phone Mockup Frame (with dark top `plaans.co/<slug>` URL bar)
class _LiinksLivePreviewStage extends StatelessWidget {
  final PlanModel plan;
  final PlanStudioProvider provider;

  const _LiinksLivePreviewStage({
    required this.plan,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = provider.devicePreview == StudioDevicePreview.mobileFrame;

    return LiinksAuroraBackground(
      baseColor: const Color(0xFFF8F8FB),
      child: Column(
        children: [
          // Top Centered `[Phone | Desktop]` Pill Switcher (Exact match to Liinks Editor)
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE4E4EC)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StageDeviceIconBtn(
                    icon: Icons.smartphone_rounded,
                    selected: isMobile,
                    tooltip: 'Phone Preview',
                    onTap: () => provider
                        .setDevicePreview(StudioDevicePreview.mobileFrame),
                  ),
                  const SizedBox(width: 4),
                  _StageDeviceIconBtn(
                    icon: Icons.desktop_windows_outlined,
                    selected: !isMobile,
                    tooltip: 'Desktop Web Preview',
                    onTap: () => provider
                        .setDevicePreview(StudioDevicePreview.desktopCanvas),
                  ),
                ],
              ),
            ),
          ),

          // Main Preview Area
          Expanded(
            child: isMobile
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        bottom: 20,
                        left: 16,
                        right: 16,
                      ),
                      child: _LiinksPhoneMockupFrame(
                        plan: plan,
                        provider: provider,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: PlanPageCanvas(
                        plan: plan,
                        provider: provider,
                        isEditable: true,
                        isCompactMobileFrame: false,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StageDeviceIconBtn extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  const _StageDeviceIconBtn({
    required this.icon,
    required this.selected,
    required this.tooltip,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1D1D28) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(
            icon,
            size: 16,
            color: selected ? Colors.white : const Color(0xFF717182),
          ),
        ),
      ),
    );
  }
}

/// Exact Liinks.co Phone Mockup Frame featuring the dark top URL bar
/// (`share icon` — `plaans.co/<slug>` — `copy icon`) above the live canvas
class _LiinksPhoneMockupFrame extends StatelessWidget {
  final PlanModel plan;
  final PlanStudioProvider provider;

  const _LiinksPhoneMockupFrame({
    required this.plan,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 405,
      decoration: BoxDecoration(
        color: const Color(0xFF1D1D24),
        borderRadius: BorderRadius.circular(42),
        border: Border.all(
          color: const Color(0xFF2E2E38),
          width: 6,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D1D28).withValues(alpha: 0.22),
            blurRadius: 42,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Top Dark Address Bar inside Phone (`share` — `plaans.co/wildstem` — `copy`)
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: const Color(0xFF1D1D24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => SharePlanDialog.show(
                    context,
                    plan: plan,
                    onPreviewPublicPage: () => provider.setVisitorView(true),
                  ),
                  child: const Icon(
                    Icons.share_outlined,
                    size: 15,
                    color: Colors.white70,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    children: [
                      const TextSpan(text: 'plaans.co/'),
                      TextSpan(
                        text: plan.slug,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: 'https://plaans.co/#/p/${plan.slug}'),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied plaans.co/${plan.slug} link!'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.copy_rounded,
                    size: 14.5,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Plan Canvas inside Phone Screen
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: PlanPageCanvas(
                plan: plan,
                provider: provider,
                isEditable: true,
                isCompactMobileFrame: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

