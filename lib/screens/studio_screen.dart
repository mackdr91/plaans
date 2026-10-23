import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/plan_models.dart';
import '../providers/plan_studio_provider.dart';
import '../services/maps_service.dart';
import '../widgets/block_editor_sheet.dart';
import '../widgets/plan_image.dart';
import '../widgets/plan_page_canvas.dart';
import '../widgets/share_plan_dialog.dart';
import 'liinks_landing_screen.dart';

/// Main Plaans Studio Workspace — redesigned to faithfully match the
/// "Edit it live, see it instantly" live editor on https://www.liinks.co/:
/// 1. Leftmost vertical dark icon rail (`56px` wide, `#181920`)
/// 2. Clean white Inspector Panel (`370px` wide) with segmented `Content | Styles` pill switcher
///    and row-based color/style pickers with circular swatches on the right
/// 3. Right live preview area with floating `[Phone | Desktop]` toggle and realistic
///    Phone Mockup containing the dark top `plaans.co/<slug>` address bar.
class StudioScreen extends StatefulWidget {
  const StudioScreen({super.key});

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  // Desktop Inspector: 0 = Content, 1 = Styles, 2 = GPS Hub, 3 = My Plans
  int _activeInspectorSection = 0;

  // Mobile-First Bottom Nav: 0 = Live Canvas, 1 = Content, 2 = Styles, 3 = GPS Stops, 4 = Plans
  int _mobileBottomTab = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlanStudioProvider>();
    final plan = provider.activePlan;

    if (provider.isLoading || plan == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAFAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1D1D28)),
        ),
      );
    }

    // 1. If on the Liinks-style Landing / Showcase Screen
    if (provider.showLandingHome && !provider.isVisitorView) {
      return LiinksLandingScreen(provider: provider);
    }

    // 2. If user toggled full "Visitor Shared View", show the clean public recipient screen
    if (provider.isVisitorView) {
      return _PublicVisitorPreviewScaffold(plan: plan, provider: provider);
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobileViewport = screenWidth < 760;
    final isWideScreen = screenWidth >= 960;

    // 3. Mobile-First Studio Experience (< 760px width):
    // Full-bleed mobile canvas + thumb-friendly bottom navigation bar for Content, Styles, GPS & Plans
    if (isMobileViewport) {
      return Scaffold(
        backgroundColor: _mobileBottomTab == 0
            ? plan.theme.backgroundColor
            : Colors.white,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Compact Mobile-First Studio Top Bar
              _MobileStudioTopBar(plan: plan, provider: provider),

              // Active Mobile Tab Body
              Expanded(
                child: IndexedStack(
                  index: _mobileBottomTab,
                  children: [
                    // Tab 0: Full-bleed interactive itinerary canvas (no redundant outer phone bezel)
                    PlanPageCanvas(
                      plan: plan,
                      provider: provider,
                      isEditable: true,
                      isCompactMobileFrame: true,
                    ),
                    // Tab 1: Content & Blocks Manager
                    _BlocksManagerTab(plan: plan, provider: provider),
                    // Tab 2: Liinks Styles & Theme Designer
                    _LiinksStylesDesignerTab(plan: plan, provider: provider),
                    // Tab 3: GPS Stops & Multi-Stop Route Directory
                    _GpsLocationsDirectoryTab(plan: plan, provider: provider),
                    // Tab 4: Saved Plans Switcher
                    _SavedPlansDirectoryTab(plan: plan, provider: provider),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _mobileBottomTab == 0
            ? FloatingActionButton.extended(
                backgroundColor: const Color(0xFF1D1D28),
                foregroundColor: Colors.white,
                elevation: 4,
                onPressed: () async {
                  final b = await provider.addBlock(BlockType.placeEvent);
                  if (b != null && context.mounted) {
                    BlockEditorModal.show(
                      context,
                      block: b,
                      onSave: provider.updateBlock,
                    );
                  }
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  'Add Block',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              )
            : null,
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF181920),
            border: Border(
              top: BorderSide(color: Color(0xFF2B2D3A), width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MobileBottomNavItem(
                    icon: Icons.smartphone_rounded,
                    label: 'Canvas',
                    isSelected: _mobileBottomTab == 0,
                    onTap: () => setState(() => _mobileBottomTab = 0),
                  ),
                  _MobileBottomNavItem(
                    icon: Icons.layers_outlined,
                    label: 'Blocks (${plan.blocks.length})',
                    isSelected: _mobileBottomTab == 1,
                    onTap: () => setState(() => _mobileBottomTab = 1),
                  ),
                  _MobileBottomNavItem(
                    icon: Icons.palette_outlined,
                    label: 'Styles',
                    isSelected: _mobileBottomTab == 2,
                    onTap: () => setState(() => _mobileBottomTab = 2),
                  ),
                  _MobileBottomNavItem(
                    icon: Icons.pin_drop_outlined,
                    label: 'GPS (${plan.locatedBlocks.length})',
                    isSelected: _mobileBottomTab == 3,
                    onTap: () => setState(() => _mobileBottomTab = 3),
                  ),
                  _MobileBottomNavItem(
                    icon: Icons.folder_copy_outlined,
                    label: 'Plans',
                    isSelected: _mobileBottomTab == 4,
                    onTap: () => setState(() => _mobileBottomTab = 4),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F9),
      drawer: isWideScreen
          ? null
          : Drawer(
              width: 370,
              backgroundColor: Colors.white,
              child: _LiinksInspectorPanel(
                activeSection: _activeInspectorSection,
                onSelectSection: (idx) =>
                    setState(() => _activeInspectorSection = idx),
                plan: plan,
                provider: provider,
              ),
            ),
      body: Column(
        children: [
          // Top macOS / Liinks Browser Window Bar (`plaans.co` centered)
          _LiinksWindowTopBar(
            plan: plan,
            provider: provider,
            isWideScreen: isWideScreen,
          ),

          // 3-Column Liinks Studio Body
          Expanded(
            child: Row(
              children: [
                // Column 1: Leftmost Dark Vertical Icon Rail (`#181920`)
                _LiinksDarkIconRail(
                  activeSection: _activeInspectorSection,
                  onSelectSection: (idx) =>
                      setState(() => _activeInspectorSection = idx),
                  plan: plan,
                  provider: provider,
                ),

                // Column 2: Clean White `Content | Styles` Inspector Panel
                if (isWideScreen)
                  SizedBox(
                    width: 375,
                    child: _LiinksInspectorPanel(
                      activeSection: _activeInspectorSection,
                      onSelectSection: (idx) =>
                          setState(() => _activeInspectorSection = idx),
                      plan: plan,
                      provider: provider,
                    ),
                  ),

                // Column 3: Right Live Preview Canvas (Phone Mockup w/ URL Bar or Desktop View)
                Expanded(
                  child: _LiinksLivePreviewStage(
                    plan: plan,
                    provider: provider,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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

/// Tab 1 (`Content`): Add Blocks + Drag-and-Drop Reorder List
class _BlocksManagerTab extends StatelessWidget {
  final PlanModel plan;
  final PlanStudioProvider provider;

  const _BlocksManagerTab({required this.plan, required this.provider});

  @override
  Widget build(BuildContext context) {
    final blocks = provider.visibleBlocks;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.9,
                children: [
                  _QuickBlockPaletteBtn(
                    label: '+ Place / GPS',
                    icon: Icons.add_location_alt_rounded,
                    accent: const Color(0xFFE04F33),
                    onTap: () async {
                      final b = await provider.addBlock(BlockType.placeEvent);
                      if (b != null && context.mounted) {
                        BlockEditorModal.show(
                          context,
                          block: b,
                          onSave: provider.updateBlock,
                        );
                      }
                    },
                  ),
                  _QuickBlockPaletteBtn(
                    label: '+ Link Button',
                    icon: Icons.link_rounded,
                    accent: const Color(0xFF2B4EFF),
                    onTap: () async {
                      final b = await provider.addBlock(BlockType.linkCard);
                      if (b != null && context.mounted) {
                        BlockEditorModal.show(
                          context,
                          block: b,
                          onSave: provider.updateBlock,
                        );
                      }
                    },
                  ),
                  _QuickBlockPaletteBtn(
                    label: '+ Photo Upload',
                    icon: Icons.add_photo_alternate_rounded,
                    accent: const Color(0xFF16A34A),
                    onTap: () async {
                      final b =
                          await provider.addBlock(BlockType.photoGallery);
                      if (b != null && context.mounted) {
                        BlockEditorModal.show(
                          context,
                          block: b,
                          onSave: provider.updateBlock,
                        );
                      }
                    },
                  ),
                  _QuickBlockPaletteBtn(
                    label: '+ Day Tab / Header',
                    icon: Icons.calendar_view_day_rounded,
                    accent: const Color(0xFF1D1D28),
                    onTap: () => provider.addBlock(BlockType.dayHeader),
                  ),
                  _QuickBlockPaletteBtn(
                    label: '+ Route Map',
                    icon: Icons.map_rounded,
                    accent: const Color(0xFF0284C7),
                    onTap: () => provider.addBlock(BlockType.mapOverview),
                  ),
                  _QuickBlockPaletteBtn(
                    label: '+ Folder / Note',
                    icon: Icons.folder_open_rounded,
                    accent: const Color(0xFF9333EA),
                    onTap: () => provider.addBlock(BlockType.textNote),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEF4)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Drag to reorder (${blocks.length} blocks)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF717182),
                ),
              ),
              const Icon(
                Icons.drag_handle_rounded,
                size: 16,
                color: Color(0xFF717182),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            itemCount: blocks.length,
            onReorderItem: provider.reorderBlocks,
            itemBuilder: (context, idx) {
              final block = blocks[idx];
              return Container(
                key: ValueKey('sidebar_${block.id}'),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9FC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE6E6F0),
                  ),
                ),
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  leading: Icon(
                    _iconForBlock(block.type),
                    size: 18,
                    color: const Color(0xFF1D1D28),
                  ),
                  title: Text(
                    block.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF1D1D28),
                    ),
                  ),
                  subtitle: Text(
                    block.hasLocation
                        ? '${block.dayTag} · 📍 ${block.location!.placeName}'
                        : '${block.dayTag} · ${block.type.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF717182),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        onPressed: () => BlockEditorModal.show(
                          context,
                          block: block,
                          onSave: provider.updateBlock,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => provider.deleteBlock(block.id),
                      ),
                    ],
                  ),
                  onTap: () => BlockEditorModal.show(
                    context,
                    block: block,
                    onSave: provider.updateBlock,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _iconForBlock(BlockType type) {
    switch (type) {
      case BlockType.dayHeader:
        return Icons.calendar_today_rounded;
      case BlockType.placeEvent:
        return Icons.place_rounded;
      case BlockType.mapOverview:
        return Icons.map_rounded;
      case BlockType.linkCard:
        return Icons.link_rounded;
      case BlockType.photoGallery:
        return Icons.collections_rounded;
      case BlockType.textNote:
        return Icons.folder_open_rounded;
    }
  }
}

class _QuickBlockPaletteBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _QuickBlockPaletteBtn({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF9F9FC),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE4E4EE)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D1D28),
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

/// Tab 2 (`Styles`): Matches Liinks.co's exact row-based Styles Inspector
/// (`<- Colors` header with Undo/Redo buttons, followed by rounded setting rows
/// with right-aligned circular color swatches)
class _LiinksStylesDesignerTab extends StatelessWidget {
  final PlanModel plan;
  final PlanStudioProvider provider;

  const _LiinksStylesDesignerTab({
    required this.plan,
    required this.provider,
  });

  static const List<String> _fonts = [
    'Playfair Display',
    'Plus Jakarta Sans',
    'Space Grotesk',
    'DM Sans',
    'Syne',
  ];

  static const List<int> _bgSwatches = [
    0xFFF6EFEA, // Wildstem Cream
    0xFF8B1E29, // Bakehouse Crimson
    0xFFFFFFFF, // Lune White
    0xFF0A2A36, // Athletic Teal
    0xFF5D4E60, // Parita Plum
    0xFFE3D8C8, // Goodee Sandstone
    0xFF14141B, // Midnight Ink
  ];

  static const List<int> _textSwatches = [
    0xFF1D1D28,
    0xFF2B211E,
    0xFFFDF8F6,
    0xFFFFFFFF,
    0xFF334155,
  ];

  static const List<int> _cardSwatches = [
    0xFFFFFFFF,
    0xFFF4F4F6,
    0xFF35C9D6,
    0xFFFDFBF7,
    0xFF1E2230,
  ];

  static const List<int> _accentSwatches = [
    0xFFC85A53,
    0xFFE04F33,
    0xFFB84A27,
    0xFFF59E0B,
    0xFF2B4EFF,
    0xFF2D6A4F,
    0xFF1D1D28,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = plan.theme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Top `<- Colors` Header Row + Reset/Undo Buttons (Exact match to Liinks screenshot)
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE4E4EC)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.arrow_back_rounded,
                      size: 16,
                      color: Color(0xFF1D1D28),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Colors & Themes',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1D1D28),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _SquareIconBox(
              icon: Icons.undo_rounded,
              tooltip: 'Reset to Wildstem Cream',
              onTap: () => provider.updateTheme(PlanTheme.presets.first),
            ),
            const SizedBox(width: 6),
            _SquareIconBox(
              icon: Icons.redo_rounded,
              tooltip: 'Cycle Next Theme Preset',
              onTap: () {
                final curIdx = PlanTheme.presets
                    .indexWhere((p) => p.presetId == theme.presetId);
                final nextPreset = PlanTheme
                    .presets[(curIdx + 1) % PlanTheme.presets.length];
                provider.updateTheme(nextPreset);
              },
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Liinks-Style Color Rows (Label on Left, Circular Swatch on Right — click to cycle or pick)
        _LiinksColorSwatchRow(
          label: 'Background',
          currentColor: theme.backgroundColor,
          swatches: _bgSwatches,
          onSelectColor: (val) {
            final isDarkBg =
                val == 0xFF8B1E29 || val == 0xFF0A2A36 || val == 0xFF5D4E60 || val == 0xFF14141B;
            provider.updateTheme(
              theme.copyWith(
                backgroundColorValue: val,
                secondaryBackgroundValue: val,
                textColorValue: isDarkBg ? 0xFFFDF8F6 : 0xFF1D1D28,
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _LiinksColorSwatchRow(
          label: 'Text Color',
          currentColor: theme.textColor,
          swatches: _textSwatches,
          onSelectColor: (val) =>
              provider.updateTheme(theme.copyWith(textColorValue: val)),
        ),
        const SizedBox(height: 10),
        _LiinksColorSwatchRow(
          label: 'Block Surface Color',
          currentColor: theme.cardColor,
          swatches: _cardSwatches,
          onSelectColor: (val) =>
              provider.updateTheme(theme.copyWith(cardColorValue: val)),
        ),
        const SizedBox(height: 10),
        _LiinksColorSwatchRow(
          label: 'Label & GPS Accent Color',
          currentColor: theme.primaryAccent,
          swatches: _accentSwatches,
          onSelectColor: (val) =>
              provider.updateTheme(theme.copyWith(primaryAccentValue: val)),
        ),

        const SizedBox(height: 20),
        const Text(
          'CURATED LIINKS THEME PRESETS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
            color: Color(0xFF717182),
          ),
        ),
        const SizedBox(height: 10),
        ...PlanTheme.presets.map((preset) {
          final isSelected = theme.presetId == preset.presetId;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF1D1D28)
                    : const Color(0xFFE4E4EC),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: ListTile(
              dense: true,
              onTap: () => provider.updateTheme(preset),
              title: Text(
                preset.presetName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: Color(0xFF1D1D28),
                ),
              ),
              subtitle: Text(
                preset.fontFamily,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF717182)),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: preset.backgroundColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black26),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: preset.primaryAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black12),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 16),
        const Text(
          'TYPOGRAPHY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
            color: Color(0xFF717182),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _fonts.map((font) {
            final selected = theme.fontFamily == font;
            return ChoiceChip(
              label: Text(font),
              selected: selected,
              selectedColor: const Color(0xFF1D1D28),
              labelStyle: TextStyle(
                color: selected ? Colors.white : const Color(0xFF1D1D28),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              onSelected: (_) =>
                  provider.updateTheme(theme.copyWith(fontFamily: font)),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),
        const Text(
          'CARD SURFACE STYLE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
            color: Color(0xFF717182),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CardBorderStyle.values.map((style) {
            final selected = theme.borderStyle == style;
            return ChoiceChip(
              label: Text(style.name),
              selected: selected,
              selectedColor: const Color(0xFF1D1D28),
              labelStyle: TextStyle(
                color: selected ? Colors.white : const Color(0xFF1D1D28),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              onSelected: (_) =>
                  provider.updateTheme(theme.copyWith(borderStyle: style)),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SquareIconBox extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _SquareIconBox({
    required this.icon,
    required this.tooltip,
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
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE4E4EC)),
          ),
          child: Icon(icon, size: 17, color: const Color(0xFF717182)),
        ),
      ),
    );
  }
}

/// Exact Liinks.co Style Row (`Background          (o)`) with expandable swatch strip on tap
class _LiinksColorSwatchRow extends StatefulWidget {
  final String label;
  final Color currentColor;
  final List<int> swatches;
  final ValueChanged<int> onSelectColor;

  const _LiinksColorSwatchRow({
    required this.label,
    required this.currentColor,
    required this.swatches,
    required this.onSelectColor,
  });

  @override
  State<_LiinksColorSwatchRow> createState() => _LiinksColorSwatchRowState();
}

class _LiinksColorSwatchRowState extends State<_LiinksColorSwatchRow> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4EC)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1D1D28),
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: widget.currentColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.swatches.map((val) {
                  final isCurrent = widget.currentColor.toARGB32() == val;
                  return GestureDetector(
                    onTap: () => widget.onSelectColor(val),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Color(val),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCurrent
                              ? const Color(0xFF1D1D28)
                              : Colors.black26,
                          width: isCurrent ? 2.5 : 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tab 3: All Pinned GPS Locations + 1-Tap Google Maps & Apple Maps Verification
class _GpsLocationsDirectoryTab extends StatelessWidget {
  final PlanModel plan;
  final PlanStudioProvider provider;

  const _GpsLocationsDirectoryTab({
    required this.plan,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final located = plan.locatedBlocks;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1D28),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.satellite_alt_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Google & Apple Maps GPS Hub',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${located.length} stops linked with turn-by-turn GPS navigation.',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1D1D28),
                ),
                onPressed: () async {
                  final b = await provider.addBlock(BlockType.placeEvent);
                  if (b != null && context.mounted) {
                    BlockEditorModal.show(
                      context,
                      block: b,
                      onSave: provider.updateBlock,
                    );
                  }
                },
                icon: const Icon(Icons.add_location_alt_rounded, size: 16),
                label: const Text(
                  'Add New GPS Stop',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...List.generate(located.length, (idx) {
          final block = located[idx];
          final loc = block.location!;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE4E4EC)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: const Color(0xFF1D1D28),
                      child: Text(
                        '${idx + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        block.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.edit_location_alt_outlined,
                        size: 16,
                      ),
                      onPressed: () => BlockEditorModal.show(
                        context,
                        block: block,
                        onSave: provider.updateBlock,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  loc.displayLabel,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF717182),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1D1D28),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                        onPressed: () => MapsService.openGoogleMaps(loc),
                        icon: const Icon(Icons.directions, size: 13.5),
                        label: const Text(
                          'Google Maps',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1D1D28),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                        onPressed: () => MapsService.openAppleMaps(loc),
                        icon: const Icon(Icons.apple, size: 13.5),
                        label: const Text(
                          'Apple Maps',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// Tab 4: Switch Between Plans or Create New Plan
class _SavedPlansDirectoryTab extends StatelessWidget {
  final PlanModel plan;
  final PlanStudioProvider provider;

  const _SavedPlansDirectoryTab({
    required this.plan,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1D1D28),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => _showCreateNewPlanDialog(context, provider),
          icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
          label: const Text(
            'Create New Plan',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'YOUR SAVED PLANS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
            color: Color(0xFF717182),
          ),
        ),
        const SizedBox(height: 10),
        ...provider.plans.map((item) {
          final isCurrent = item.id == plan.id;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrent
                    ? const Color(0xFF1D1D28)
                    : const Color(0xFFE4E4EC),
                width: isCurrent ? 2 : 1,
              ),
            ),
            child: ListTile(
              onTap: () => provider.selectPlan(item.id),
              title: Text(
                item.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
              subtitle: Text(
                'plaans.co/${item.slug} · ${item.locatedBlocks.length} GPS pins',
                style: const TextStyle(fontSize: 11.5),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'duplicate') {
                    provider.duplicatePlan(item);
                  } else if (action == 'delete' && provider.plans.length > 1) {
                    provider.deletePlan(item.id);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Text('Duplicate Plan'),
                  ),
                  if (provider.plans.length > 1)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Plan'),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showCreateNewPlanDialog(
    BuildContext context,
    PlanStudioProvider provider,
  ) {
    final titleCtrl = TextEditingController();
    final subCtrl = TextEditingController();
    PlanTheme selectedPreset = PlanTheme.presets.first;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Create a New Plan',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Plan Title (e.g., Miami Art Basel Weekend)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Bio / Subtitle',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Choose Starting Theme:',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: PlanTheme.presets.map((preset) {
                    final isChosen = selectedPreset.presetId == preset.presetId;
                    return ChoiceChip(
                      label: Text(preset.presetName),
                      selected: isChosen,
                      selectedColor: const Color(0xFF1D1D28),
                      labelStyle: TextStyle(
                        color: isChosen ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) =>
                          setDialogState(() => selectedPreset = preset),
                    );
                  }).toList(),
                ),
              ],
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
                final title = titleCtrl.text.trim().isEmpty
                    ? 'My Weekend Plan'
                    : titleCtrl.text.trim();
                provider.createNewPlan(
                  title: title,
                  subtitle: subCtrl.text.trim().isEmpty
                      ? 'Curated stops, tickets & GPS locations.'
                      : subCtrl.text.trim(),
                  theme: selectedPreset,
                );
                Navigator.of(ctx).pop();
              },
              child: const Text(
                'Launch Plan Studio',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Public Shared Visitor View Scaffold (shown when opening a shared link `/p/:slug`
/// or when clicking "Live Page")
class _PublicVisitorPreviewScaffold extends StatelessWidget {
  final PlanModel plan;
  final PlanStudioProvider provider;

  const _PublicVisitorPreviewScaffold({
    required this.plan,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: plan.theme.backgroundColor,
      body: Stack(
        children: [
          if (provider.isVisitorPinLocked)
            _PinProtectedUnlockView(plan: plan, provider: provider)
          else
            PlanPageCanvas(
              plan: plan,
              provider: provider,
              isEditable: false,
            ),
          // Floating Creator/Visitor Bar at Top Right
          Positioned(
            top: 16,
            right: 18,
            child: SafeArea(
              child: Wrap(
                spacing: 8,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.92),
                      foregroundColor: const Color(0xFF1D1D28),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    onPressed: () => provider.setVisitorView(false),
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: const Text(
                      'Edit in Studio',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D1D28),
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    onPressed: () => SharePlanDialog.show(
                      context,
                      plan: plan,
                      onPreviewPublicPage: () {},
                    ),
                    icon: const Icon(Icons.ios_share_rounded, size: 15),
                    label: const Text(
                      'Share Link',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mobile-first PIN Unlock Gate for `pinProtected` shared plans
class _PinProtectedUnlockView extends StatefulWidget {
  final PlanModel plan;
  final PlanStudioProvider provider;

  const _PinProtectedUnlockView({
    required this.plan,
    required this.provider,
  });

  @override
  State<_PinProtectedUnlockView> createState() =>
      _PinProtectedUnlockViewState();
}

class _PinProtectedUnlockViewState extends State<_PinProtectedUnlockView> {
  final _pinCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitPin() async {
    setState(() => _submitting = true);
    await widget.provider.unlockActivePlanWithPin(_pinCtrl.text.trim());
    if (mounted) {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF141413), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF141413),
                  offset: Offset(5, 5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D1D28),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.plan.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1D1D28),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'This private itinerary (`plaans.co/${widget.plan.slug}`) is protected with a group trip PIN.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF646474),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _pinCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  onSubmitted: (_) => _submitPin(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6,
                  ),
                  decoration: InputDecoration(
                    hintText: '••••',
                    counterText: '',
                    errorText: widget.provider.pinUnlockError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D1D28),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _submitting ? null : _submitPin,
                    icon: const Icon(Icons.lock_open_rounded, size: 18),
                    label: Text(
                      _submitting ? 'Verifying...' : 'Unlock Itinerary',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
