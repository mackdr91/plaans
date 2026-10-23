import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/plan_models.dart';
import '../services/maps_service.dart';
import 'interactive_plan_map.dart';
import 'plan_image.dart';

/// Renders any `PlanBlock` inside the itinerary canvas using Liinks.co's authentic
/// split-thumbnail card layout, compact pill links, and featured photo cards.
class PlanBlockRenderer extends StatelessWidget {
  final PlanBlock block;
  final PlanTheme theme;
  final List<PlanBlock> allLocatedBlocks;
  final bool isEditing;
  final bool isHighlighted;
  final bool isCompleted;
  final VoidCallback? onToggleCompleted;
  final LocationData? nextStopLocation;
  final String? planTitle;
  final int? dragIndex;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;

  const PlanBlockRenderer({
    super.key,
    required this.block,
    required this.theme,
    required this.allLocatedBlocks,
    this.isEditing = false,
    this.isHighlighted = false,
    this.isCompleted = false,
    this.onToggleCompleted,
    this.nextStopLocation,
    this.planTitle,
    this.dragIndex,
    this.onEdit,
    this.onDelete,
    this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (block.type) {
      case BlockType.dayHeader:
        content = _DayHeaderBlockWidget(block: block, theme: theme);
        break;
      case BlockType.placeEvent:
        content = _PlaceEventBlockWidget(
          block: block,
          theme: theme,
          isHighlighted: isHighlighted,
          isCompleted: isCompleted,
          onToggleCompleted: onToggleCompleted,
          nextStopLocation: nextStopLocation,
          planTitle: planTitle,
        );
        break;
      case BlockType.mapOverview:
        content = InteractivePlanMap(
          theme: theme,
          locatedBlocks: allLocatedBlocks,
          title: block.title,
          subtitle: block.subtitle,
        );
        break;
      case BlockType.linkCard:
        content = _LinkCardBlockWidget(
          block: block,
          theme: theme,
          isHighlighted: isHighlighted,
        );
        break;
      case BlockType.photoGallery:
        content = _PhotoGalleryBlockWidget(
          block: block,
          theme: theme,
          isHighlighted: isHighlighted,
        );
        break;
      case BlockType.textNote:
        content = _TextNoteBlockWidget(
          block: block,
          theme: theme,
          isHighlighted: isHighlighted,
        );
        break;
    }

    if (!isEditing) {
      return content;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onEdit,
          child: content,
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF1D1D28).withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dragIndex != null)
                  ReorderableDragStartListener(
                    index: dragIndex!,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      child: Tooltip(
                        message: 'Drag to reorder block',
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                _StudioMiniAction(
                  icon: Icons.edit_outlined,
                  tooltip: 'Customize Block',
                  onTap: onEdit,
                ),
                _StudioMiniAction(
                  icon: Icons.copy_rounded,
                  tooltip: 'Duplicate Block',
                  onTap: onDuplicate,
                ),
                _StudioMiniAction(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Delete Block',
                  color: const Color(0xFFFF7A7A),
                  onTap: onDelete,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StudioMiniAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onTap;

  const _StudioMiniAction({
    required this.icon,
    required this.tooltip,
    this.color = Colors.white,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          child: Icon(icon, size: 14.5, color: color),
        ),
      ),
    );
  }
}

/// Day / Section Divider Header Block (matches Liinks' clean centered section divider)
class _DayHeaderBlockWidget extends StatelessWidget {
  final PlanBlock block;
  final PlanTheme theme;

  const _DayHeaderBlockWidget({required this.block, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: theme.textColor.withValues(alpha: 0.14),
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    block.dayTag.toUpperCase(),
                    style: planTextStyle(
                      theme,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: theme.isDark ? Colors.white : theme.primaryAccent,
                      letterSpacing: 0.9,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: theme.textColor.withValues(alpha: 0.14),
                  thickness: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            block.title,
            textAlign: TextAlign.center,
            style: planTextStyle(
              theme,
              fontSize: 17.5,
              fontWeight: FontWeight.w800,
              isDisplayHeading: true,
            ),
          ),
          if (block.subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              block.subtitle,
              textAlign: TextAlign.center,
              style: planTextStyle(
                theme,
                fontSize: 12.5,
                color: theme.textColor.withValues(alpha: 0.68),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Core Place / Event Itinerary Card:
/// - In `standard` / `halfWidth` / `compact` sizes: Uses Liinks.co's signature **Split Left-Thumbnail Card**
///   (like the *Joy the Baker* and *Undivided* cards on `liinks.co`), with a flush image on the left
///   and the time, title, venue, and 1-click Google Maps & Apple Maps GPS buttons on the right.
/// - In `featured` size: Uses Liinks.co's **Full-Bleed Showcase Card** (like *Wildstem* and *Goodee*)
///   with a rich photo top and crisp itinerary & GPS footer.
class _PlaceEventBlockWidget extends StatelessWidget {
  final PlanBlock block;
  final PlanTheme theme;
  final bool isHighlighted;
  final bool isCompleted;
  final VoidCallback? onToggleCompleted;
  final LocationData? nextStopLocation;
  final String? planTitle;

  const _PlaceEventBlockWidget({
    required this.block,
    required this.theme,
    this.isHighlighted = false,
    this.isCompleted = false,
    this.onToggleCompleted,
    this.nextStopLocation,
    this.planTitle,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = block.imageUrls.isNotEmpty;
    final cardTextCol = planCardTextColor(theme);
    final loc = block.location;
    final legSummary = MapsService.formatTravelLegSummary(
      loc,
      nextStopLocation,
    );

    Widget cardBody;

    // 1. Liinks Split Left-Thumbnail Card (when not Featured or when in standard list)
    if (block.size != BlockSize.featured) {
      cardBody = Container(
        decoration: planCardDecoration(theme, isHighlighted: isHighlighted),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Flush Left Thumbnail (exact Liinks.co split-card pattern)
              if (hasImage)
                SizedBox(
                  width: 120,
                  child: UniversalPlanImage(
                    imageUrl: block.imageUrls.first,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 84,
                  color: theme.primaryAccent.withValues(alpha: 0.12),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.place_rounded,
                        color: isCompleted
                            ? const Color(0xFF16A34A)
                            : theme.primaryAccent,
                        size: 24,
                      ),
                      if (block.startTime.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            block.startTime,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: cardTextCol.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              // Right Content Column
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Time, Cost & Visited Check-Off Micro-Header
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (block.startTime.isNotEmpty)
                            Text(
                              block.endTime.isNotEmpty
                                  ? '${block.startTime} – ${block.endTime}'
                                  : block.startTime,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: theme.primaryAccent,
                                letterSpacing: 0.2,
                              ),
                            ),
                          if (block.costEstimate != null &&
                              block.costEstimate!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: cardTextCol.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                block.costEstimate!,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: cardTextCol.withValues(alpha: 0.78),
                                ),
                              ),
                            ),
                          if (onToggleCompleted != null)
                            InkWell(
                              onTap: onToggleCompleted,
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? const Color(0xFFDCFCE7)
                                      : cardTextCol.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isCompleted
                                          ? Icons.check_circle_rounded
                                          : Icons.radio_button_unchecked_rounded,
                                      size: 11.5,
                                      color: isCompleted
                                          ? const Color(0xFF15803D)
                                          : cardTextCol.withValues(alpha: 0.55),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      isCompleted ? 'Visited' : 'Check off',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: isCompleted
                                            ? const Color(0xFF15803D)
                                            : cardTextCol
                                                .withValues(alpha: 0.65),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        block.title,
                        style: planTextStyle(
                          theme,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isCompleted
                              ? cardTextCol.withValues(alpha: 0.6)
                              : cardTextCol,
                          height: 1.22,
                        ).copyWith(
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (block.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          block.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: planTextStyle(
                            theme,
                            fontSize: 12.5,
                            color: cardTextCol.withValues(alpha: 0.68),
                            height: 1.35,
                          ),
                        ),
                      ],
                      if (loc != null && loc.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 13.5,
                              color: cardTextCol.withValues(alpha: 0.55),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                loc.displayLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: cardTextCol.withValues(alpha: 0.62),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 9),
                      // Compact GPS, Calendar & Booking Action Row
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (loc != null && loc.isNotEmpty) ...[
                            _CompactGpsPill(
                              label: 'Google Maps',
                              icon: Icons.directions_rounded,
                              backgroundColor: const Color(0xFF1D1D28),
                              textColor: Colors.white,
                              onTap: () => MapsService.openGoogleMaps(
                                loc,
                                directions: true,
                              ),
                            ),
                            _CompactGpsPill(
                              label: 'Apple Maps',
                              icon: Icons.apple_rounded,
                              backgroundColor:
                                  cardTextCol.withValues(alpha: 0.08),
                              textColor: cardTextCol,
                              onTap: () => MapsService.openAppleMaps(
                                loc,
                                directions: true,
                              ),
                            ),
                          ],
                          if (block.startTime.isNotEmpty)
                            _CompactGpsPill(
                              label: '+ Cal',
                              icon: Icons.event_available_rounded,
                              backgroundColor:
                                  cardTextCol.withValues(alpha: 0.07),
                              textColor: cardTextCol,
                              onTap: () => MapsService.openGoogleCalendarEvent(
                                block,
                                planTitle: planTitle,
                              ),
                            ),
                          if (block.externalUrl != null &&
                              block.externalUrl!.trim().isNotEmpty)
                            _CompactGpsPill(
                              label: (block.externalUrlLabel != null &&
                                      block.externalUrlLabel!.isNotEmpty)
                                  ? block.externalUrlLabel!
                                  : 'Details',
                              icon: Icons.arrow_outward_rounded,
                              backgroundColor:
                                  theme.primaryAccent.withValues(alpha: 0.14),
                              textColor: theme.primaryAccent,
                              onTap: () => launchUrl(
                                Uri.parse(block.externalUrl!),
                                mode: LaunchMode.externalApplication,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // 2. Liinks Featured Hero Showcase Card (like Wildstem & Goodee large cards)
      cardBody = Container(
        decoration: planCardDecoration(theme, isHighlighted: isHighlighted),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasImage)
              SizedBox(
                height: 195,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    UniversalPlanImage(
                      imageUrl: block.imageUrls.first,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      bottom: 12,
                      right: 14,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (block.startTime.isNotEmpty)
                            _BadgePill(
                              text: block.endTime.isNotEmpty
                                  ? '${block.startTime} – ${block.endTime}'
                                  : block.startTime,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.92),
                              textColor: const Color(0xFF1D1D28),
                              icon: Icons.schedule_rounded,
                            ),
                          _BadgePill(
                            text: block.category,
                            backgroundColor: theme.primaryAccent,
                            textColor: Colors.white,
                            icon: Icons.local_activity_rounded,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          block.title,
                          style: planTextStyle(
                            theme,
                            fontSize: 17.5,
                            fontWeight: FontWeight.w800,
                            color: isCompleted
                                ? cardTextCol.withValues(alpha: 0.6)
                                : cardTextCol,
                          ).copyWith(
                            decoration:
                                isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      if (block.costEstimate != null &&
                          block.costEstimate!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: cardTextCol.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            block.costEstimate!,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: cardTextCol,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (onToggleCompleted != null)
                        InkWell(
                          onTap: onToggleCompleted,
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? const Color(0xFFDCFCE7)
                                  : cardTextCol.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isCompleted
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  size: 13,
                                  color: isCompleted
                                      ? const Color(0xFF15803D)
                                      : cardTextCol.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isCompleted ? 'Visited' : 'Check off',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isCompleted
                                        ? const Color(0xFF15803D)
                                        : cardTextCol,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (block.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      block.subtitle,
                      style: planTextStyle(
                        theme,
                        fontSize: 13,
                        color: cardTextCol.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                  if (block.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      block.description,
                      style: planTextStyle(
                        theme,
                        fontSize: 12.5,
                        height: 1.45,
                        color: cardTextCol.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                  if (loc != null && loc.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: cardTextCol.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 15,
                                color: theme.primaryAccent,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  loc.displayLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: cardTextCol,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _CompactGpsPill(
                                label: 'Google Maps GPS',
                                icon: Icons.directions_rounded,
                                backgroundColor: const Color(0xFF1D1D28),
                                textColor: Colors.white,
                                onTap: () => MapsService.openGoogleMaps(
                                  loc,
                                  directions: true,
                                ),
                              ),
                              _CompactGpsPill(
                                label: 'Apple Maps GPS',
                                icon: Icons.apple_rounded,
                                backgroundColor:
                                    cardTextCol.withValues(alpha: 0.1),
                                textColor: cardTextCol,
                                onTap: () => MapsService.openAppleMaps(
                                  loc,
                                  directions: true,
                                ),
                              ),
                              if (block.startTime.isNotEmpty)
                                _CompactGpsPill(
                                  label: '+ Add to Calendar',
                                  icon: Icons.event_available_rounded,
                                  backgroundColor:
                                      cardTextCol.withValues(alpha: 0.08),
                                  textColor: cardTextCol,
                                  onTap: () =>
                                      MapsService.openGoogleCalendarEvent(
                                    block,
                                    planTitle: planTitle,
                                  ),
                                ),
                              if (block.externalUrl != null &&
                                  block.externalUrl!.trim().isNotEmpty)
                                _CompactGpsPill(
                                  label: (block.externalUrlLabel != null &&
                                          block.externalUrlLabel!.isNotEmpty)
                                      ? block.externalUrlLabel!
                                      : 'View Place',
                                  icon: Icons.open_in_new_rounded,
                                  backgroundColor: theme.primaryAccent
                                      .withValues(alpha: 0.14),
                                  textColor: theme.primaryAccent,
                                  onTap: () => launchUrl(
                                    Uri.parse(block.externalUrl!),
                                    mode: LaunchMode.externalApplication,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (legSummary == null) {
      return cardBody;
    }

    // Wrap with subtle Travel Leg Connector Pill (`↓ 0.8 km · ~10 min walk to next stop`)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        cardBody,
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: theme.textColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    legSummary.contains('walk')
                        ? Icons.directions_walk_rounded
                        : Icons.directions_car_filled_outlined,
                    size: 12,
                    color: theme.textColor.withValues(alpha: 0.65),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Next stop: $legSummary',
                    style: planTextStyle(
                      theme,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: theme.textColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Liinks.co-inspired Pill Row Link Button (matches Lune Studio's left-thumbnail pill rows)
class _LinkCardBlockWidget extends StatelessWidget {
  final PlanBlock block;
  final PlanTheme theme;
  final bool isHighlighted;

  const _LinkCardBlockWidget({
    required this.block,
    required this.theme,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardTextCol = planCardTextColor(theme);
    final hasThumb = block.imageUrls.isNotEmpty;

    return Container(
      decoration: planCardDecoration(theme, isHighlighted: isHighlighted),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(theme.borderRadius),
          onTap: (block.externalUrl != null && block.externalUrl!.isNotEmpty)
              ? () => launchUrl(
                    Uri.parse(block.externalUrl!),
                    mode: LaunchMode.externalApplication,
                  )
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                if (hasThumb)
                  UniversalPlanImage(
                    imageUrl: block.imageUrls.first,
                    width: 44,
                    height: 44,
                    borderRadius: BorderRadius.circular(10),
                  )
                else
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.primaryAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.link_rounded,
                      color: theme.primaryAccent,
                      size: 20,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        block.title,
                        textAlign: TextAlign.center,
                        style: planTextStyle(
                          theme,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: cardTextCol,
                        ),
                      ),
                      if (block.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          block.subtitle,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: planTextStyle(
                            theme,
                            fontSize: 11.5,
                            color: cardTextCol.withValues(alpha: 0.62),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cardTextCol.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_outward_rounded,
                    size: 15,
                    color: cardTextCol.withValues(alpha: 0.7),
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

/// Visual Photo Gallery / Uploaded Images Block
class _PhotoGalleryBlockWidget extends StatelessWidget {
  final PlanBlock block;
  final PlanTheme theme;
  final bool isHighlighted;

  const _PhotoGalleryBlockWidget({
    required this.block,
    required this.theme,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final images = block.imageUrls;
    final cardTextCol = planCardTextColor(theme);
    return Container(
      decoration: planCardDecoration(theme, isHighlighted: isHighlighted),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (block.title.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                block.title,
                style: planTextStyle(
                  theme,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: cardTextCol,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (images.isEmpty)
            Container(
              height: 130,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cardTextCol.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Tap to upload photos from your device',
                style: planTextStyle(
                  theme,
                  fontSize: 12.5,
                  color: cardTextCol.withValues(alpha: 0.65),
                ),
              ),
            )
          else if (images.length == 1)
            SizedBox(
              height: 210,
              width: double.infinity,
              child: UniversalPlanImage(
                imageUrl: images.first,
                borderRadius: BorderRadius.circular(12),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: images.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.25,
              ),
              itemBuilder: (context, idx) {
                return UniversalPlanImage(
                  imageUrl: images[idx],
                  borderRadius: BorderRadius.circular(12),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Expandable / Clean Callout Note Block (inspired by Liinks' accordion/folder & note blocks)
class _TextNoteBlockWidget extends StatelessWidget {
  final PlanBlock block;
  final PlanTheme theme;
  final bool isHighlighted;

  const _TextNoteBlockWidget({
    required this.block,
    required this.theme,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardTextCol = planCardTextColor(theme);
    return Container(
      decoration: planCardDecoration(theme, isHighlighted: isHighlighted),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.primaryAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_awesome_outlined,
                  size: 15,
                  color: theme.primaryAccent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  block.title,
                  style: planTextStyle(
                    theme,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: cardTextCol,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: cardTextCol.withValues(alpha: 0.5),
              ),
            ],
          ),
          if (block.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              block.description,
              style: planTextStyle(
                theme,
                fontSize: 12.5,
                height: 1.48,
                color: cardTextCol.withValues(alpha: 0.76),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  const _BadgePill({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactGpsPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  const _CompactGpsPill({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12.5, color: textColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
