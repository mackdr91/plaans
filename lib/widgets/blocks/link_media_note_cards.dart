part of '../block_widgets.dart';

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

