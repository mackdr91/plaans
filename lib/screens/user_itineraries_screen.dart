import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/plan_models.dart';
import '../providers/plan_studio_provider.dart';
import '../widgets/auth_modal_sheet.dart';
import '../widgets/plan_image.dart';
import '../widgets/share_plan_dialog.dart';

/// Filter modes on the User Itineraries Home Page
enum _ItineraryFilter {
  all,
  publicOnly,
  pinProtected,
  cloudSynced,
}

/// Dedicated Home Screen displaying all of the user's itineraries (`UserItinerariesScreen`).
/// Routed to whenever the user clicks the Home button (`@plaans` or the Home icon)
/// from the Studio, Visitor View, or Landing navbar.
class UserItinerariesScreen extends StatefulWidget {
  final PlanStudioProvider provider;

  const UserItinerariesScreen({
    super.key,
    required this.provider,
  });

  @override
  State<UserItinerariesScreen> createState() => _UserItinerariesScreenState();
}

class _UserItinerariesScreenState extends State<UserItinerariesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  _ItineraryFilter _selectedFilter = _ItineraryFilter.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PlanModel> get _filteredPlans {
    final query = _searchCtrl.text.trim().toLowerCase();
    return widget.provider.plans.where((plan) {
      if (_selectedFilter == _ItineraryFilter.publicOnly &&
          plan.visibility != PlanVisibility.public) {
        return false;
      }
      if (_selectedFilter == _ItineraryFilter.pinProtected &&
          plan.visibility != PlanVisibility.pinProtected) {
        return false;
      }
      if (_selectedFilter == _ItineraryFilter.cloudSynced &&
          !plan.isCloudSynced) {
        return false;
      }
      if (query.isEmpty) return true;
      return plan.title.toLowerCase().contains(query) ||
          plan.subtitle.toLowerCase().contains(query) ||
          plan.slug.toLowerCase().contains(query) ||
          plan.dateRangeLabel.toLowerCase().contains(query);
    }).toList();
  }

  void _showCreateItineraryDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final subCtrl = TextEditingController();
    PlanTheme selectedPreset = PlanTheme.presets.first;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0xFF1D1D28), width: 2),
          ),
          title: Text(
            'Create a New Itinerary',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1D1D28),
            ),
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Itinerary Title (e.g., Tokyo Autumn Trip)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: subCtrl,
                    decoration: InputDecoration(
                      labelText: 'Subtitle / Group Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Choose Starting Theme:',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: const Color(0xFF1D1D28),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: PlanTheme.presets.map((preset) {
                      final isChosen =
                          selectedPreset.presetId == preset.presetId;
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D1D28),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              onPressed: () {
                final title = titleCtrl.text.trim().isEmpty
                    ? 'My Weekend Plan'
                    : titleCtrl.text.trim();
                widget.provider.createNewPlan(
                  title: title,
                  subtitle: subCtrl.text.trim().isEmpty
                      ? 'Curated stops, tickets & GPS locations.'
                      : subCtrl.text.trim(),
                  theme: selectedPreset,
                );
                Navigator.of(ctx).pop();
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Open in Studio',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 680;
    final isDesktop = screenWidth >= 1040;
    final user = widget.provider.creatorUser;
    final allPlans = widget.provider.plans;
    final visiblePlans = _filteredPlans;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6FA),
      floatingActionButton: isMobile
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF1D1D28),
              foregroundColor: Colors.white,
              onPressed: () => _showCreateItineraryDialog(context),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                'New Itinerary',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Navigation Header Bar
            Container(
              height: isMobile ? 60 : 68,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE4E4EC), width: 1),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Row(
                    children: [
                      // `@plaans` Brand Mark
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D1D28),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(
                              Icons.alternate_email_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'plaans',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: isMobile ? 19 : 21,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1D1D28),
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEEEF5),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              '${allPlans.length} ${allPlans.length == 1 ? "Itinerary" : "Itineraries"}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1D1D28),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      if (!isMobile)
                        TextButton.icon(
                          onPressed: () =>
                              widget.provider.setShowLandingHome(true),
                          icon: const Icon(
                            Icons.auto_awesome_outlined,
                            size: 16,
                            color: Color(0xFF646474),
                          ),
                          label: Text(
                            'Explore Showcase',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF646474),
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),

                      // Creator Account / Sign In Pill
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1D1D28),
                          side: const BorderSide(color: Color(0xFFD4D4E0)),
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 11 : 14,
                            vertical: isMobile ? 8 : 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        onPressed: () => AuthModalSheet.show(context),
                        icon: Icon(
                          user != null
                              ? Icons.verified_user_rounded
                              : Icons.person_outline_rounded,
                          size: 15,
                          color: user != null
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF1D1D28),
                        ),
                        label: Text(
                          user != null ? user.displayName : 'Sign In',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      if (!isMobile) ...[
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D1D28),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          onPressed: () => _showCreateItineraryDialog(context),
                          icon: const Icon(Icons.add_rounded, size: 17),
                          label: Text(
                            'New Itinerary',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // 2. Scrollable Dashboard Body
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 28,
                  vertical: isMobile ? 20 : 30,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Dashboard Title & Subtitle
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user != null
                                        ? "${user.displayName}'s Itineraries"
                                        : 'Your Itineraries',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: isMobile ? 26 : 34,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1D1D28),
                                      letterSpacing: -0.9,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Select any itinerary to edit in the Studio, preview the live shared page, or copy its GPS link.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: isMobile ? 13.5 : 15,
                                      color: const Color(0xFF646474),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Search & Filter Bar
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isMobile ? double.infinity : 380,
                              ),
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText:
                                      'Search itineraries by title, slug, or date...',
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    size: 19,
                                  ),
                                  suffixIcon: _searchCtrl.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.clear_rounded,
                                            size: 17,
                                          ),
                                          onPressed: () {
                                            _searchCtrl.clear();
                                            setState(() {});
                                          },
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: Colors.white,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(100),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE2E2EC),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(100),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE2E2EC),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _FilterChipButton(
                                  label: 'All (${allPlans.length})',
                                  selected:
                                      _selectedFilter == _ItineraryFilter.all,
                                  onTap: () => setState(
                                    () =>
                                        _selectedFilter = _ItineraryFilter.all,
                                  ),
                                ),
                                _FilterChipButton(
                                  label: 'Public',
                                  selected: _selectedFilter ==
                                      _ItineraryFilter.publicOnly,
                                  onTap: () => setState(
                                    () => _selectedFilter =
                                        _ItineraryFilter.publicOnly,
                                  ),
                                ),
                                _FilterChipButton(
                                  label: 'PIN Protected',
                                  selected: _selectedFilter ==
                                      _ItineraryFilter.pinProtected,
                                  onTap: () => setState(
                                    () => _selectedFilter =
                                        _ItineraryFilter.pinProtected,
                                  ),
                                ),
                                _FilterChipButton(
                                  label: 'Cloud Synced',
                                  selected: _selectedFilter ==
                                      _ItineraryFilter.cloudSynced,
                                  onTap: () => setState(
                                    () => _selectedFilter =
                                        _ItineraryFilter.cloudSynced,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Empty State if no itineraries match filter
                        if (visiblePlans.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: const Color(0xFFE4E4EC)),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.map_outlined,
                                  size: 42,
                                  color: Color(0xFF94A3B8),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No matching itineraries found',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1D1D28),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Try clearing your search filter or create a brand new itinerary.',
                                  style: TextStyle(color: Color(0xFF646474)),
                                ),
                              ],
                            ),
                          )
                        else
                          // Responsive Grid of Itinerary Cards
                          LayoutBuilder(
                            builder: (ctx, constraints) {
                              final cols = isDesktop
                                  ? 3
                                  : (constraints.maxWidth >= 660 ? 2 : 1);
                              const spacing = 20.0;
                              final cardWidth =
                                  (constraints.maxWidth - (cols - 1) * spacing) /
                                      cols;

                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: visiblePlans.map((item) {
                                  final isActive =
                                      widget.provider.activePlan?.id == item.id;
                                  return SizedBox(
                                    width: cardWidth,
                                    child: _UserItineraryCard(
                                      plan: item,
                                      isActive: isActive,
                                      canDelete: allPlans.length > 1,
                                      onEditInStudio: () =>
                                          widget.provider.selectPlan(item.id),
                                      onOpenLiveView: () => widget.provider
                                          .selectPlan(item.id,
                                              visitorMode: true),
                                      onShare: () => SharePlanDialog.show(
                                        context,
                                        plan: item,
                                        onPreviewPublicPage: () => widget
                                            .provider
                                            .selectPlan(item.id,
                                                visitorMode: true),
                                      ),
                                      onDuplicate: () =>
                                          widget.provider.duplicatePlan(item),
                                      onDelete: () =>
                                          widget.provider.deletePlan(item.id),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
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
    );
  }
}

class _UserItineraryCard extends StatelessWidget {
  final PlanModel plan;
  final bool isActive;
  final bool canDelete;
  final VoidCallback onEditInStudio;
  final VoidCallback onOpenLiveView;
  final VoidCallback onShare;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _UserItineraryCard({
    required this.plan,
    required this.isActive,
    required this.canDelete,
    required this.onEditInStudio,
    required this.onOpenLiveView,
    required this.onShare,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final gpsCount = plan.locatedBlocks.length;
    final daysCount = plan.dayTags.isEmpty ? 1 : plan.dayTags.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? const Color(0xFF1D1D28) : const Color(0xFFE2E2EC),
          width: isActive ? 2.2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D1D28).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Cover Image Banner + Status Badges
          GestureDetector(
            onTap: onEditInStudio,
            child: SizedBox(
              height: 148,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (plan.coverImageUrl != null &&
                      plan.coverImageUrl!.isNotEmpty)
                    UniversalPlanImage(
                      imageUrl: plan.coverImageUrl!,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(color: plan.theme.backgroundColor),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.28),
                          Colors.black.withValues(alpha: 0.62),
                        ],
                      ),
                    ),
                  ),
                  // Top Badges Row
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.68),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                plan.visibility == PlanVisibility.pinProtected
                                    ? Icons.lock_rounded
                                    : (plan.visibility ==
                                            PlanVisibility.unlisted
                                        ? Icons.link_rounded
                                        : Icons.public_rounded),
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                plan.visibility == PlanVisibility.pinProtected
                                    ? 'PIN LOCKED'
                                    : (plan.visibility ==
                                            PlanVisibility.unlisted
                                        ? 'UNLISTED'
                                        : 'PUBLIC'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (plan.isCloudSynced)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.cloud_done_rounded,
                                  size: 12,
                                  color: Color(0xFF166534),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'SYNCED',
                                  style: TextStyle(
                                    color: Color(0xFF166534),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Bottom Date Range & Author on Cover
                  Positioned(
                    bottom: 10,
                    left: 14,
                    right: 14,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            plan.dateRangeLabel,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1D1D28),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          plan.theme.presetName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Card Body: Title, Subtitle, Vanity Slug & Stats
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plan.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1D1D28),
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'More Actions',
                      onSelected: (action) {
                        if (action == 'duplicate') {
                          onDuplicate();
                        } else if (action == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Icons.copy_all_rounded, size: 17),
                              SizedBox(width: 8),
                              Text('Duplicate Itinerary'),
                            ],
                          ),
                        ),
                        if (canDelete)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  size: 17,
                                  color: Color(0xFFB91C1C),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Delete Itinerary',
                                  style: TextStyle(color: Color(0xFFB91C1C)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  plan.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF646474),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),

                // Copyable `plaans.co/<slug>` pill + Stats
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(100),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F8),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.link_rounded,
                              size: 13,
                              color: Color(0xFF1D1D28),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'plaans.co/${plan.slug}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1D1D28),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$daysCount ${daysCount == 1 ? "Day" : "Days"} · $gpsCount GPS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF646474),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 3. Action Buttons Row: Edit in Studio | Live View | Share
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D1D28),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onEditInStudio,
                        icon: const Icon(Icons.edit_square, size: 15),
                        label: const Text(
                          'Edit in Studio',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1D1D28),
                        side: const BorderSide(color: Color(0xFFD4D4E0)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: onOpenLiveView,
                      child: const Text(
                        'Live View',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Share Link & QR Code',
                      onPressed: onShare,
                      icon: const Icon(
                        Icons.ios_share_rounded,
                        size: 18,
                        color: Color(0xFF1D1D28),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1D1D28) : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? const Color(0xFF1D1D28) : const Color(0xFFE2E2EC),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : const Color(0xFF1D1D28),
          ),
        ),
      ),
    );
  }
}
