import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/plan_models.dart';
import '../providers/plan_studio_provider.dart';
import '../services/maps_service.dart';
import '../widgets/auth_modal_sheet.dart';
import '../widgets/block_editor_sheet.dart';
import '../widgets/plan_image.dart';
import '../widgets/plan_page_canvas.dart';
import '../widgets/share_plan_dialog.dart';
import 'liinks_landing_screen.dart';


part 'studio/studio_navigation_bars.dart';
part 'studio/studio_preview_stage.dart';
part 'studio/studio_content_and_styles_tabs.dart';
part 'studio/studio_gps_and_plans_tabs.dart';
part 'studio/studio_visitor_scaffold.dart';
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

