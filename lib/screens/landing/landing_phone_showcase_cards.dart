part of '../liinks_landing_screen.dart';

class _MiniAvatarCircle extends StatelessWidget {
  final double left;
  final Color color;
  final String label;

  const _MiniAvatarCircle({
    required this.left,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _NavHeaderLink extends StatelessWidget {
  final String label;
  final bool hasDropdown;
  final VoidCallback onTap;

  const _NavHeaderLink({
    required this.label,
    this.hasDropdown = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1D1D28),
              ),
            ),
            if (hasDropdown) ...[
              const SizedBox(width: 3),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: Color(0xFF1D1D28),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeatureStripItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureStripItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF646474)),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: const Color(0xFF646474),
          ),
        ),
      ],
    );
  }
}

/// Renders the 3 Fanned Tilted Phone Cards on Desktop/Tablet, or a swipeable/centered card on Mobile
class _FannedHeroPhonesShowcase extends StatelessWidget {
  final List<PlanModel> plans;
  final bool isMobile;
  final ValueChanged<PlanModel> onSelectPlan;

  const _FannedHeroPhonesShowcase({
    required this.plans,
    this.isMobile = false,
    required this.onSelectPlan,
  });

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) return const SizedBox.shrink();
    final centerPlan = plans[0];
    final leftPlan = plans.length > 2 ? plans[2] : plans[0];
    final rightPlan = plans.length > 1 ? plans[1] : plans[0];

    if (isMobile) {
      return SizedBox(
        height: 475,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: plans.length,
          separatorBuilder: (_, _) => const SizedBox(width: 16),
          itemBuilder: (context, idx) {
            final p = plans[idx];
            return _MiniPhonePreviewCard(
              plan: p,
              width: 265,
              height: 465,
              isHighlightedCenter: idx == 0,
              onTap: () => onSelectPlan(p),
            );
          },
        ),
      );
    }

    return SizedBox(
      height: 550,
      width: 620,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Left Tilted Phone (Sandstone / Amalfi style)
          Positioned(
            left: 16,
            top: 38,
            child: Transform.rotate(
              angle: -0.11,
              child: _MiniPhonePreviewCard(
                plan: leftPlan,
                width: 245,
                height: 465,
                onTap: () => onSelectPlan(leftPlan),
              ),
            ),
          ),

          // Right Tilted Phone (Bakehouse Crimson / Teal style)
          Positioned(
            right: 16,
            top: 26,
            child: Transform.rotate(
              angle: 0.11,
              child: _MiniPhonePreviewCard(
                plan: rightPlan,
                width: 245,
                height: 465,
                onTap: () => onSelectPlan(rightPlan),
              ),
            ),
          ),

          // Center Foreground Featured Phone
          Positioned(
            top: 10,
            child: _MiniPhonePreviewCard(
              plan: centerPlan,
              width: 268,
              height: 505,
              isHighlightedCenter: true,
              onTap: () => onSelectPlan(centerPlan),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact Liinks-style Phone Card used in the Hero fan and "Made with Plaans" showcase
class _MiniPhonePreviewCard extends StatelessWidget {
  final PlanModel plan;
  final double width;
  final double height;
  final bool isHighlightedCenter;
  final VoidCallback onTap;

  const _MiniPhonePreviewCard({
    required this.plan,
    required this.width,
    required this.height,
    this.isHighlightedCenter = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = plan.theme;
    final cardTextCol = planCardTextColor(theme);
    final avatarUrl = plan.avatarImageUrl ?? plan.coverImageUrl;
    final placeStops =
        plan.blocks.where((b) => b.type == BlockType.placeEvent).take(2).toList();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.65),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1D1D28)
                  .withValues(alpha: isHighlightedCenter ? 0.24 : 0.15),
              blurRadius: isHighlightedCenter ? 38 : 26,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Top Corner Icons (`+` and `share`)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: theme.textColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 12,
                    color: theme.textColor,
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: theme.textColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.share_outlined,
                    size: 12,
                    color: theme.textColor,
                  ),
                ),
              ],
            ),

            // Centered Circular Avatar
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryAccent,
                border: Border.all(color: Colors.white, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: avatarUrl != null
                  ? UniversalPlanImage(
                      imageUrl: avatarUrl,
                      fit: BoxFit.cover,
                    )
                  : Icon(Icons.explore, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 10),

            // Title & Bio
            Text(
              plan.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: planTextStyle(
                theme,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                isDisplayHeading: true,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              plan.authorName.isNotEmpty
                  ? plan.authorName
                  : plan.dateRangeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: planTextStyle(
                theme,
                fontSize: 10.5,
                color: theme.textColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              plan.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: planTextStyle(
                theme,
                fontSize: 10.5,
                height: 1.35,
                color: theme.textColor.withValues(alpha: 0.82),
              ),
            ),
            const SizedBox(height: 10),

            // Social / GPS Icon Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 15, color: theme.textColor),
                const SizedBox(width: 10),
                Icon(Icons.explore_outlined, size: 15, color: theme.textColor),
                const SizedBox(width: 10),
                Icon(Icons.qr_code_rounded, size: 15, color: theme.textColor),
                const SizedBox(width: 10),
                Icon(Icons.calendar_today_outlined, size: 14, color: theme.textColor),
              ],
            ),
            const SizedBox(height: 12),

            // Split-Thumbnail Preview Cards (Exact Joy the Baker / Lune Studio look)
            Expanded(
              child: Column(
                children: placeStops.map((stop) {
                  final img =
                      stop.imageUrls.isNotEmpty ? stop.imageUrls.first : null;
                  return Container(
                    height: 76,
                    margin: const EdgeInsets.only(bottom: 9),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Row(
                      children: [
                        if (img != null)
                          SizedBox(
                            width: 72,
                            height: 76,
                            child: UniversalPlanImage(
                              imageUrl: img,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Container(
                            width: 56,
                            height: 76,
                            color: theme.primaryAccent.withValues(alpha: 0.15),
                            child: Icon(
                              Icons.place_rounded,
                              color: theme.primaryAccent,
                              size: 20,
                            ),
                          ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  stop.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: cardTextCol,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  stop.subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9.8,
                                    height: 1.25,
                                    color: cardTextCol.withValues(alpha: 0.68),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // Bottom "Open in Studio" Pill Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Google & Apple Maps GPS',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: cardTextCol.withValues(alpha: 0.8),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 15,
                    color: cardTextCol,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
