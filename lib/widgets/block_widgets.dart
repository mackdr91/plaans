import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/plan_models.dart';
import '../services/maps_service.dart';
import 'interactive_plan_map.dart';
import 'plan_image.dart';


part 'blocks/place_event_block_card.dart';
part 'blocks/link_media_note_cards.dart';
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
