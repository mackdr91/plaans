import 'package:flutter/material.dart';
import '../models/plan_models.dart';
import '../services/image_service.dart';
import '../services/maps_service.dart';
import 'plan_image.dart';

/// Mobile-First Inspector Sheet / Modal for editing any `PlanBlock`:
/// - On mobile (`< 680px`): Opens as a smooth draggable full-height bottom sheet with single-column thumb-friendly fields.
/// - On tablet/desktop (`>= 680px`): Opens as a centered rounded modal dialog.
class BlockEditorModal extends StatefulWidget {
  final PlanBlock block;
  final ValueChanged<PlanBlock> onSave;
  final ScrollController? scrollController;

  const BlockEditorModal({
    super.key,
    required this.block,
    required this.onSave,
    this.scrollController,
  });

  static Future<void> show(
    BuildContext context, {
    required PlanBlock block,
    required ValueChanged<PlanBlock> onSave,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 680;
    if (isMobile) {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.6,
          maxChildSize: 0.96,
          expand: false,
          builder: (_, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            clipBehavior: Clip.antiAlias,
            child: BlockEditorModal(
              block: block,
              onSave: onSave,
              scrollController: scrollCtrl,
            ),
          ),
        ),
      );
    }

    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFFFAFAFC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFE4E4EC), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 780),
          child: BlockEditorModal(block: block, onSave: onSave),
        ),
      ),
    );
  }

  @override
  State<BlockEditorModal> createState() => _BlockEditorModalState();
}

class _BlockEditorModalState extends State<BlockEditorModal> {
  late TextEditingController _titleCtrl;
  late TextEditingController _subtitleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _dayTagCtrl;
  late TextEditingController _startTimeCtrl;
  late TextEditingController _endTimeCtrl;
  late TextEditingController _costCtrl;
  late TextEditingController _extUrlCtrl;
  late TextEditingController _extLabelCtrl;

  // Location fields
  late TextEditingController _placeNameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _latCtrl;
  late TextEditingController _lngCtrl;
  late TextEditingController _searchPlaceCtrl;

  late BlockSize _selectedSize;
  late String _selectedCategory;
  late List<String> _imageUrls;

  List<LocationData> _placeSuggestions = [];
  bool _isSearchingPlaces = false;

  static const List<String> _categories = [
    'Food & Drink',
    'Activity',
    'Nightlife',
    'Stay',
    'Transit',
    'Shopping',
  ];

  @override
  void initState() {
    super.initState();
    final b = widget.block;
    _titleCtrl = TextEditingController(text: b.title);
    _subtitleCtrl = TextEditingController(text: b.subtitle);
    _descCtrl = TextEditingController(text: b.description);
    _dayTagCtrl = TextEditingController(text: b.dayTag);
    _startTimeCtrl = TextEditingController(text: b.startTime);
    _endTimeCtrl = TextEditingController(text: b.endTime);
    _costCtrl = TextEditingController(text: b.costEstimate ?? '');
    _extUrlCtrl = TextEditingController(text: b.externalUrl ?? '');
    _extLabelCtrl = TextEditingController(text: b.externalUrlLabel ?? '');

    _placeNameCtrl = TextEditingController(text: b.location?.placeName ?? '');
    _addressCtrl = TextEditingController(text: b.location?.address ?? '');
    _latCtrl = TextEditingController(
      text: b.location?.latitude != null ? b.location!.latitude.toString() : '',
    );
    _lngCtrl = TextEditingController(
      text:
          b.location?.longitude != null ? b.location!.longitude.toString() : '',
    );
    _searchPlaceCtrl = TextEditingController();

    _selectedSize = b.size;
    _selectedCategory = _categories.contains(b.category)
        ? b.category
        : _categories.first;
    _imageUrls = List<String>.from(b.imageUrls);
    _placeSuggestions = MapsService.curatedLandmarks.take(4).toList();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _descCtrl.dispose();
    _dayTagCtrl.dispose();
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();
    _costCtrl.dispose();
    _extUrlCtrl.dispose();
    _extLabelCtrl.dispose();
    _placeNameCtrl.dispose();
    _addressCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _searchPlaceCtrl.dispose();
    super.dispose();
  }

  Future<void> _performPlaceSearch(String query) async {
    setState(() => _isSearchingPlaces = true);
    final results = await MapsService.searchPlaces(query);
    if (!mounted) return;
    setState(() {
      _placeSuggestions = results;
      _isSearchingPlaces = false;
    });
  }

  void _applyLocationSuggestion(LocationData loc) {
    setState(() {
      _placeNameCtrl.text = loc.placeName;
      _addressCtrl.text = loc.address;
      _latCtrl.text = loc.latitude?.toStringAsFixed(5) ?? '';
      _lngCtrl.text = loc.longitude?.toStringAsFixed(5) ?? '';
    });
  }

  Future<void> _uploadFromDevice() async {
    final dataUrl = await ImageService.pickImageAsDataUrl();
    if (dataUrl != null && mounted) {
      setState(() {
        _imageUrls.insert(0, dataUrl);
      });
    }
  }

  void _handleSave() {
    LocationData? loc;
    final hasLocInput = _placeNameCtrl.text.trim().isNotEmpty ||
        _addressCtrl.text.trim().isNotEmpty ||
        _latCtrl.text.trim().isNotEmpty;
    if (hasLocInput) {
      loc = LocationData(
        placeName: _placeNameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        latitude: double.tryParse(_latCtrl.text.trim()),
        longitude: double.tryParse(_lngCtrl.text.trim()),
      );
    }

    final updated = widget.block.copyWith(
      title: _titleCtrl.text.trim().isEmpty
          ? 'Untitled Block'
          : _titleCtrl.text.trim(),
      subtitle: _subtitleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      dayTag: _dayTagCtrl.text.trim().isEmpty
          ? 'Day 1'
          : _dayTagCtrl.text.trim(),
      size: _selectedSize,
      category: _selectedCategory,
      startTime: _startTimeCtrl.text.trim(),
      endTime: _endTimeCtrl.text.trim(),
      costEstimate:
          _costCtrl.text.trim().isEmpty ? null : _costCtrl.text.trim(),
      externalUrl:
          _extUrlCtrl.text.trim().isEmpty ? null : _extUrlCtrl.text.trim(),
      externalUrlLabel:
          _extLabelCtrl.text.trim().isEmpty ? null : _extLabelCtrl.text.trim(),
      location: loc,
      clearLocation: !hasLocInput,
      imageUrls: _imageUrls,
    );

    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.block.type;
    final showLocationSection = type == BlockType.placeEvent;
    final showImagesSection =
        type == BlockType.placeEvent || type == BlockType.photoGallery;
    final showLinkSection =
        type == BlockType.placeEvent || type == BlockType.linkCard;
    final isMobile = MediaQuery.of(context).size.width < 560;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle for mobile bottom sheet
          if (widget.scrollController != null)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4D4DF),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),

          // Modal Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFEAEAF0))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D1D28),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Customize ${_blockTypeName(type)}',
                    style: const TextStyle(
                      color: Color(0xFF1D1D28),
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Color(0xFF717182)),
                ),
              ],
            ),
          ),

          // Scrollable Inspector Body
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              padding: EdgeInsets.all(isMobile ? 16 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day Tag & Card Layout Size (stacks on mobile, side-by-side on desktop)
                  if (isMobile) ...[
                    _LabeledTextField(
                      label: 'Day / Section Tag',
                      hint: 'e.g. Day 1, Friday, Night',
                      controller: _dayTagCtrl,
                    ),
                    const SizedBox(height: 12),
                    _buildCardSizeDropdown(),
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: _LabeledTextField(
                            label: 'Day / Section Tag',
                            hint: 'e.g. Day 1, Friday, Night',
                            controller: _dayTagCtrl,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: _buildCardSizeDropdown()),
                      ],
                    ),
                  const SizedBox(height: 14),

                  _LabeledTextField(
                    label: 'Title / Headline',
                    hint: 'e.g. Tsukiji Outer Market Breakfast',
                    controller: _titleCtrl,
                  ),
                  const SizedBox(height: 12),

                  _LabeledTextField(
                    label: 'Subtitle / Vibe Summary',
                    hint: 'e.g. Fresh sushi bowls & ceremonial matcha',
                    controller: _subtitleCtrl,
                  ),

                  if (type == BlockType.placeEvent ||
                      type == BlockType.textNote) ...[
                    const SizedBox(height: 12),
                    _LabeledTextField(
                      label: 'Details / Notes / Tips',
                      hint: 'Reservation info, what to bring, or insider tips...',
                      controller: _descCtrl,
                      maxLines: 3,
                    ),
                  ],

                  // Event Schedule & Category
                  if (type == BlockType.placeEvent) ...[
                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'TIME, CATEGORY & COST',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                        color: Color(0xFF717182),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _LabeledTextField(
                            label: 'Start Time',
                            hint: '09:30 AM',
                            controller: _startTimeCtrl,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _LabeledTextField(
                            label: 'End Time',
                            hint: '11:30 AM',
                            controller: _endTimeCtrl,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _LabeledTextField(
                      label: 'Cost / Ticket Note',
                      hint: '\$35 / person',
                      controller: _costCtrl,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final selected = _selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: selected,
                          selectedColor: const Color(0xFF1D1D28),
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          onSelected: (_) =>
                              setState(() => _selectedCategory = cat),
                        );
                      }).toList(),
                    ),
                  ],

                  // GPS Location & Google/Apple Maps Linker
                  if (showLocationSection) ...[
                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(
                          Icons.pin_drop_rounded,
                          size: 17,
                          color: Color(0xFFE04F33),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'GPS LOCATION (GOOGLE MAPS & APPLE MAPS)',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchPlaceCtrl,
                            decoration: _inputDecoration(
                              'Search place or address for GPS...',
                            ).copyWith(
                              prefixIcon: const Icon(Icons.search, size: 18),
                            ),
                            onSubmitted: _performPlaceSearch,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D1D28),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _isSearchingPlaces
                              ? null
                              : () =>
                                  _performPlaceSearch(_searchPlaceCtrl.text),
                          icon: _isSearchingPlaces
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.my_location_rounded, size: 15),
                          label: const Text('Find GPS'),
                        ),
                      ],
                    ),
                    if (_placeSuggestions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _placeSuggestions.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 6),
                          itemBuilder: (context, idx) {
                            final item = _placeSuggestions[idx];
                            return ActionChip(
                              avatar: const Icon(
                                Icons.place_outlined,
                                size: 14,
                                color: Color(0xFFE04F33),
                              ),
                              label: Text(
                                item.placeName,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () => _applyLocationSuggestion(item),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _LabeledTextField(
                      label: 'Venue / Place Name',
                      hint: 'e.g. Shibuya Sky',
                      controller: _placeNameCtrl,
                    ),
                    const SizedBox(height: 10),
                    _LabeledTextField(
                      label: 'Street Address / City',
                      hint: '2-24-12 Shibuya, Tokyo',
                      controller: _addressCtrl,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _LabeledTextField(
                            label: 'Latitude',
                            hint: '35.6585',
                            controller: _latCtrl,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _LabeledTextField(
                            label: 'Longitude',
                            hint: '139.7022',
                            controller: _lngCtrl,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // External Link Section
                  if (showLinkSection) ...[
                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'EXTERNAL LINK (RESERVATIONS, TICKETS, WEBSITE)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFF717182),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _LabeledTextField(
                      label: 'Destination URL',
                      hint: 'https://...',
                      controller: _extUrlCtrl,
                    ),
                    const SizedBox(height: 10),
                    _LabeledTextField(
                      label: 'Button Label',
                      hint: 'Book Table / Tickets',
                      controller: _extLabelCtrl,
                    ),
                  ],

                  // Image Upload & Curated Gallery Section
                  if (showImagesSection) ...[
                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        const Text(
                          'PHOTOS & IMAGE UPLOAD',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Color(0xFF717182),
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D1D28),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          onPressed: _uploadFromDevice,
                          icon:
                              const Icon(Icons.upload_file_rounded, size: 15),
                          label: const Text(
                            'Upload from Device',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_imageUrls.isNotEmpty)
                      SizedBox(
                        height: 92,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _imageUrls.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, idx) {
                            return Stack(
                              children: [
                                UniversalPlanImage(
                                  imageUrl: _imageUrls[idx],
                                  width: 124,
                                  height: 92,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() => _imageUrls.removeAt(idx));
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black87,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 10),
                    const Text(
                      'Or tap a preset photo to add:',
                      style: TextStyle(fontSize: 12, color: Color(0xFF717182)),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 60,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: ImageService.curatedGallery.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final item = ImageService.curatedGallery[idx];
                          return InkWell(
                            onTap: () {
                              setState(() => _imageUrls.add(item['url']!));
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item['url']!,
                                width: 84,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Modal Footer Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEAEAF0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D1D28),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  onPressed: _handleSave,
                  icon: const Icon(Icons.check_rounded, size: 17),
                  label: const Text(
                    'Save Block',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSizeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Block Card Layout',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1D1D28),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<BlockSize>(
          initialValue: _selectedSize,
          decoration: _inputDecoration(''),
          items: const [
            DropdownMenuItem(
              value: BlockSize.standard,
              child: Text('Split Left-Thumbnail Card'),
            ),
            DropdownMenuItem(
              value: BlockSize.featured,
              child: Text('Featured Full-Bleed Card'),
            ),
            DropdownMenuItem(
              value: BlockSize.halfWidth,
              child: Text('Half-Width Grid Tile'),
            ),
            DropdownMenuItem(
              value: BlockSize.compact,
              child: Text('Compact Pill Row'),
            ),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _selectedSize = v);
          },
        ),
      ],
    );
  }

  String _blockTypeName(BlockType type) {
    switch (type) {
      case BlockType.dayHeader:
        return 'Day / Section Header';
      case BlockType.placeEvent:
        return 'Event & GPS Place Stop';
      case BlockType.mapOverview:
        return 'Interactive GPS Map';
      case BlockType.linkCard:
        return 'Liinks Button Card';
      case BlockType.photoGallery:
        return 'Photo Gallery Block';
      case BlockType.textNote:
        return 'Folder & Note Block';
    }
  }
}

class _LabeledTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final int maxLines;

  const _LabeledTextField({
    required this.label,
    required this.hint,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1D1D28),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: _inputDecoration(hint),
          style: const TextStyle(fontSize: 13.5),
        ),
      ],
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE2E2EA)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE2E2EA)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF1D1D28), width: 1.5),
    ),
  );
}
