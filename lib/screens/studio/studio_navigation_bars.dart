part of '../studio_screen.dart';

/// Compact Mobile-First Studio Top Bar (`< 760px`)
class _MobileStudioTopBar extends StatelessWidget {
  final PlanModel plan;
  final PlanStudioProvider provider;

  const _MobileStudioTopBar({
    required this.plan,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF181920),
        border: Border(
          bottom: BorderSide(color: Color(0xFF2B2D3A), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Home `@plaans` button
          InkWell(
            onTap: () => provider.setShowLandingHome(true),
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 13,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '@plaans',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Tappable `plaans.co/<slug>` pill to copy share URL
          Expanded(
            child: GestureDetector(
              onTap: () {
                Clipboard.setData(
                  ClipboardData(text: 'https://plaans.co/${plan.slug}'),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied plaans.co/${plan.slug}'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        'plaans.co/${plan.slug}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.copy_rounded,
                      size: 12,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Undo / Redo on Mobile Top Bar
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Undo',
            onPressed: provider.canUndo ? () => provider.undo() : null,
            icon: Icon(
              Icons.undo_rounded,
              size: 17,
              color: provider.canUndo ? Colors.white : Colors.white24,
            ),
          ),
          // Visitor preview icon button
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Preview Live Shared Page',
            onPressed: () => provider.setVisitorView(true),
            icon: const Icon(
              Icons.visibility_outlined,
              size: 18,
              color: Colors.white,
            ),
          ),
          // Share button pill
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF43E660),
              foregroundColor: const Color(0xFF0F172A),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            onPressed: () => SharePlanDialog.show(
              context,
              plan: plan,
              onPreviewPublicPage: () => provider.setVisitorView(true),
            ),
            icon: const Icon(Icons.ios_share_rounded, size: 13.5),
            label: const Text(
              'Share',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileBottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MobileBottomNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 19,
              color: isSelected ? Colors.white : Colors.white60,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sleek top window bar inspired by the `liinks.co` editor frame
class _LiinksWindowTopBar extends StatelessWidget {
  final PlanModel plan;
  final PlanStudioProvider provider;
  final bool isWideScreen;

  const _LiinksWindowTopBar({
    required this.plan,
    required this.provider,
    required this.isWideScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: Color(0xFFF2F2F6),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE4E4EC), width: 1),
        ),
      ),
      child: Row(
        children: [
          if (!isWideScreen)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded, size: 20),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          // Traffic light dots + `@plaans` home button
          InkWell(
            onTap: () => provider.setShowLandingHome(true),
            borderRadius: BorderRadius.circular(999),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 11,
                  height: 11,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5F57),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Container(
                  width: 11,
                  height: 11,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEBC2E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Container(
                  width: 11,
                  height: 11,
                  decoration: const BoxDecoration(
                    color: Color(0xFF28C840),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  '@plaans',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1D1D28),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Centered `plaans.co` title (matching `liinks.co` centered window bar)
          Text(
            'plaans.co/${plan.slug}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF717182),
            ),
          ),

          const Spacer(),

          // Undo / Redo Quick Controls
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Undo last edit',
            onPressed: provider.canUndo ? () => provider.undo() : null,
            icon: Icon(
              Icons.undo_rounded,
              size: 18,
              color: provider.canUndo
                  ? const Color(0xFF1D1D28)
                  : const Color(0xFFB4B4C4),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Redo edit',
            onPressed: provider.canRedo ? () => provider.redo() : null,
            icon: Icon(
              Icons.redo_rounded,
              size: 18,
              color: provider.canRedo
                  ? const Color(0xFF1D1D28)
                  : const Color(0xFFB4B4C4),
            ),
          ),
          const SizedBox(width: 4),

          // Right Quick Actions: Visitor View & Share Pill
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1D1D28),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () => provider.setVisitorView(true),
            icon: const Icon(Icons.visibility_outlined, size: 16),
            label: const Text(
              'Live Page',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D1D28),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            onPressed: () => SharePlanDialog.show(
              context,
              plan: plan,
              onPreviewPublicPage: () => provider.setVisitorView(true),
            ),
            icon: const Icon(Icons.ios_share_rounded, size: 14.5),
            label: const Text(
              'Share',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Leftmost Dark Icon Rail (`#181920`) matching the Liinks.co Studio left sidebar
class _LiinksDarkIconRail extends StatelessWidget {
  final int activeSection;
  final ValueChanged<int> onSelectSection;
  final PlanModel plan;
  final PlanStudioProvider provider;

  const _LiinksDarkIconRail({
    required this.activeSection,
    required this.onSelectSection,
    required this.plan,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      color: const Color(0xFF181920),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          _RailIconButton(
            icon: Icons.search_rounded,
            tooltip: 'Quick Add GPS Place',
            isSelected: false,
            onTap: () => onSelectSection(2),
          ),
          const SizedBox(height: 6),
          _RailIconButton(
            icon: Icons.home_outlined,
            tooltip: 'Landing Showcase Home',
            isSelected: false,
            onTap: () => provider.setShowLandingHome(true),
          ),
          const SizedBox(height: 6),
          _RailIconButton(
            icon: Icons.edit_square,
            tooltip: 'Content & Blocks Editor',
            isSelected: activeSection == 0,
            onTap: () => onSelectSection(0),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            child: Divider(color: Colors.white12, height: 1),
          ),
          _RailIconButton(
            icon: Icons.palette_outlined,
            tooltip: 'Styles & Colors',
            isSelected: activeSection == 1,
            onTap: () => onSelectSection(1),
          ),
          const SizedBox(height: 6),
          _RailIconButton(
            icon: Icons.pin_drop_outlined,
            tooltip: 'Google & Apple Maps GPS Hub',
            isSelected: activeSection == 2,
            onTap: () => onSelectSection(2),
          ),
          const SizedBox(height: 6),
          _RailIconButton(
            icon: Icons.grid_view_rounded,
            tooltip: 'Saved Plans & Templates',
            isSelected: activeSection == 3,
            onTap: () => onSelectSection(3),
          ),
          const SizedBox(height: 6),
          _RailIconButton(
            icon: Icons.link_rounded,
            tooltip: 'Add Link Block',
            isSelected: false,
            onTap: () => provider.addBlock(BlockType.linkCard),
          ),
          const Spacer(),
          _RailIconButton(
            icon: Icons.smartphone_rounded,
            tooltip: 'Toggle Phone / Desktop Preview',
            isSelected:
                provider.devicePreview == StudioDevicePreview.mobileFrame,
            onTap: () => provider.setDevicePreview(
              provider.devicePreview == StudioDevicePreview.mobileFrame
                  ? StudioDevicePreview.desktopCanvas
                  : StudioDevicePreview.mobileFrame,
            ),
          ),
          const SizedBox(height: 6),
          _RailIconButton(
            icon: Icons.qr_code_2_rounded,
            tooltip: 'Share QR Code & Link',
            isSelected: false,
            onTap: () => SharePlanDialog.show(
              context,
              plan: plan,
              onPreviewPublicPage: () => provider.setVisitorView(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onTap;

  const _RailIconButton({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: Colors.white.withValues(alpha: 0.25))
                : null,
          ),
          child: Icon(
            icon,
            size: 19,
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}

