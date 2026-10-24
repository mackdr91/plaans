part of '../studio_screen.dart';

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

