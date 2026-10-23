import 'dart:convert';
import 'package:flutter/material.dart';

/// Block types supported in the Plaans studio (inspired by Liinks.co & Squarespace)
enum BlockType {
  dayHeader,
  placeEvent,
  mapOverview,
  linkCard,
  photoGallery,
  textNote,
}

/// Visual layout span / card sizing for blocks
enum BlockSize {
  compact,
  standard,
  featured,
  halfWidth,
}

/// Card border and surface aesthetic styles
enum CardBorderStyle {
  brutalistShadow, // Bold 2px border + crisp offset shadow (Liinks classic)
  softGlass, // Subtle border + translucent blur/elevated soft shadow
  crispOutline, // Clean 1.5px border, zero shadow (Editorial)
  minimalFlat, // Borderless, subtle surface contrast
}

/// Overall canvas layout modes
enum PlanLayoutMode {
  timeline,
  bentoGrid,
  magazine,
}

/// Represents a physical place or venue with coordinates and GPS deep-link builders
class LocationData {
  final String placeName;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? googlePlaceId;

  const LocationData({
    required this.placeName,
    this.address = '',
    this.latitude,
    this.longitude,
    this.googlePlaceId,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  bool get isNotEmpty =>
      placeName.trim().isNotEmpty || address.trim().isNotEmpty || hasCoordinates;

  String get displayLabel {
    if (placeName.isNotEmpty && address.isNotEmpty) {
      return '$placeName · $address';
    }
    return placeName.isNotEmpty ? placeName : address;
  }

  String get _searchQuery {
    final combined = [placeName.trim(), address.trim()]
        .where((s) => s.isNotEmpty)
        .join(', ');
    if (combined.isNotEmpty) return combined;
    if (hasCoordinates) return '${latitude!},${longitude!}';
    return '';
  }

  /// Universal Google Maps search / pin link
  String get googleMapsSearchUrl {
    final q = Uri.encodeComponent(_searchQuery);
    if (googlePlaceId != null && googlePlaceId!.isNotEmpty) {
      return 'https://www.google.com/maps/search/?api=1&query=$q&query_place_id=${Uri.encodeComponent(googlePlaceId!)}';
    }
    if (hasCoordinates && _searchQuery.isEmpty) {
      return 'https://www.google.com/maps/search/?api=1&query=${latitude!},${longitude!}';
    }
    return 'https://www.google.com/maps/search/?api=1&query=$q';
  }

  /// Universal Google Maps turn-by-turn GPS directions link
  String get googleMapsDirectionsUrl {
    if (hasCoordinates && _searchQuery.isEmpty) {
      return 'https://www.google.com/maps/dir/?api=1&destination=${latitude!},${longitude!}&travelmode=driving';
    }
    final dest = Uri.encodeComponent(
      _searchQuery.isNotEmpty ? _searchQuery : '${latitude ?? 0},${longitude ?? 0}',
    );
    return 'https://www.google.com/maps/dir/?api=1&destination=$dest';
  }

  /// Universal Apple Maps pin / search link
  String get appleMapsSearchUrl {
    final q = Uri.encodeComponent(placeName.isNotEmpty ? placeName : _searchQuery);
    if (hasCoordinates) {
      return 'https://maps.apple.com/?q=$q&ll=${latitude!},${longitude!}';
    }
    return 'https://maps.apple.com/?q=${Uri.encodeComponent(_searchQuery)}';
  }

  /// Universal Apple Maps turn-by-turn GPS directions link
  String get appleMapsDirectionsUrl {
    if (hasCoordinates) {
      final q = Uri.encodeComponent(placeName.isNotEmpty ? placeName : _searchQuery);
      return 'https://maps.apple.com/?daddr=${latitude!},${longitude!}&q=$q&dirflg=d';
    }
    final dest = Uri.encodeComponent(_searchQuery);
    return 'https://maps.apple.com/?daddr=$dest&dirflg=d';
  }

  LocationData copyWith({
    String? placeName,
    String? address,
    double? latitude,
    double? longitude,
    String? googlePlaceId,
  }) {
    return LocationData(
      placeName: placeName ?? this.placeName,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      googlePlaceId: googlePlaceId ?? this.googlePlaceId,
    );
  }

  Map<String, dynamic> toJson() => {
        'placeName': placeName,
        'address': address,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (googlePlaceId != null) 'googlePlaceId': googlePlaceId,
      };

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      placeName: json['placeName'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      googlePlaceId: json['googlePlaceId'] as String?,
    );
  }
}

/// Visual theme configuration for a Plan (colors, fonts, card aesthetics, layout)
class PlanTheme {
  final String presetId;
  final String presetName;
  final int backgroundColorValue;
  final int secondaryBackgroundValue;
  final int cardColorValue;
  final int primaryAccentValue;
  final int textColorValue;
  final CardBorderStyle borderStyle;
  final double borderRadius;
  final String fontFamily;
  final PlanLayoutMode layoutMode;

  const PlanTheme({
    required this.presetId,
    required this.presetName,
    required this.backgroundColorValue,
    required this.secondaryBackgroundValue,
    required this.cardColorValue,
    required this.primaryAccentValue,
    required this.textColorValue,
    this.borderStyle = CardBorderStyle.softGlass,
    this.borderRadius = 16.0,
    this.fontFamily = 'Plus Jakarta Sans',
    this.layoutMode = PlanLayoutMode.timeline,
  });

  Color get backgroundColor => Color(backgroundColorValue);
  Color get secondaryBackground => Color(secondaryBackgroundValue);
  Color get cardColor => Color(cardColorValue);
  Color get primaryAccent => Color(primaryAccentValue);
  Color get textColor => Color(textColorValue);

  bool get isDark =>
      ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark;

  PlanTheme copyWith({
    String? presetId,
    String? presetName,
    int? backgroundColorValue,
    int? secondaryBackgroundValue,
    int? cardColorValue,
    int? primaryAccentValue,
    int? textColorValue,
    CardBorderStyle? borderStyle,
    double? borderRadius,
    String? fontFamily,
    PlanLayoutMode? layoutMode,
  }) {
    return PlanTheme(
      presetId: presetId ?? this.presetId,
      presetName: presetName ?? this.presetName,
      backgroundColorValue: backgroundColorValue ?? this.backgroundColorValue,
      secondaryBackgroundValue:
          secondaryBackgroundValue ?? this.secondaryBackgroundValue,
      cardColorValue: cardColorValue ?? this.cardColorValue,
      primaryAccentValue: primaryAccentValue ?? this.primaryAccentValue,
      textColorValue: textColorValue ?? this.textColorValue,
      borderStyle: borderStyle ?? this.borderStyle,
      borderRadius: borderRadius ?? this.borderRadius,
      fontFamily: fontFamily ?? this.fontFamily,
      layoutMode: layoutMode ?? this.layoutMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'presetId': presetId,
        'presetName': presetName,
        'backgroundColorValue': backgroundColorValue,
        'secondaryBackgroundValue': secondaryBackgroundValue,
        'cardColorValue': cardColorValue,
        'primaryAccentValue': primaryAccentValue,
        'textColorValue': textColorValue,
        'borderStyle': borderStyle.name,
        'borderRadius': borderRadius,
        'fontFamily': fontFamily,
        'layoutMode': layoutMode.name,
      };

  factory PlanTheme.fromJson(Map<String, dynamic> json) {
    return PlanTheme(
      presetId: json['presetId'] as String? ?? 'wildstem_cream',
      presetName: json['presetName'] as String? ?? 'Wildstem Cream',
      backgroundColorValue:
          json['backgroundColorValue'] as int? ?? 0xFFF6EFEA,
      secondaryBackgroundValue:
          json['secondaryBackgroundValue'] as int? ?? 0xFFEBE1D8,
      cardColorValue: json['cardColorValue'] as int? ?? 0xFFFFFFFF,
      primaryAccentValue: json['primaryAccentValue'] as int? ?? 0xFFC85A53,
      textColorValue: json['textColorValue'] as int? ?? 0xFF1D1D28,
      borderStyle: CardBorderStyle.values.firstWhere(
        (e) => e.name == json['borderStyle'],
        orElse: () => CardBorderStyle.softGlass,
      ),
      borderRadius: (json['borderRadius'] as num?)?.toDouble() ?? 16.0,
      fontFamily: json['fontFamily'] as String? ?? 'Playfair Display',
      layoutMode: PlanLayoutMode.values.firstWhere(
        (e) => e.name == json['layoutMode'],
        orElse: () => PlanLayoutMode.timeline,
      ),
    );
  }

  static const List<PlanTheme> presets = [
    PlanTheme(
      presetId: 'wildstem_cream',
      presetName: 'Wildstem Cream',
      backgroundColorValue: 0xFFF6EFEA,
      secondaryBackgroundValue: 0xFFEBE1D8,
      cardColorValue: 0xFFFFFFFF,
      primaryAccentValue: 0xFFC85A53,
      textColorValue: 0xFF2B211E,
      borderStyle: CardBorderStyle.softGlass,
      borderRadius: 16.0,
      fontFamily: 'Playfair Display',
      layoutMode: PlanLayoutMode.timeline,
    ),
    PlanTheme(
      presetId: 'bakehouse_crimson',
      presetName: 'Bakehouse Crimson',
      backgroundColorValue: 0xFF8B1E29,
      secondaryBackgroundValue: 0xFF701620,
      cardColorValue: 0xFFFFFFFF,
      primaryAccentValue: 0xFFE04F33,
      textColorValue: 0xFFFDF8F6,
      borderStyle: CardBorderStyle.softGlass,
      borderRadius: 14.0,
      fontFamily: 'Plus Jakarta Sans',
      layoutMode: PlanLayoutMode.timeline,
    ),
    PlanTheme(
      presetId: 'lune_minimal',
      presetName: 'Lune Studio White',
      backgroundColorValue: 0xFFFFFFFF,
      secondaryBackgroundValue: 0xFFF4F4F6,
      cardColorValue: 0xFFF4F4F6,
      primaryAccentValue: 0xFFB84A27,
      textColorValue: 0xFF1D1D28,
      borderStyle: CardBorderStyle.minimalFlat,
      borderRadius: 14.0,
      fontFamily: 'Plus Jakarta Sans',
      layoutMode: PlanLayoutMode.timeline,
    ),
    PlanTheme(
      presetId: 'athletic_teal',
      presetName: 'Athletic Teal',
      backgroundColorValue: 0xFF0A2A36,
      secondaryBackgroundValue: 0xFF123B4A,
      cardColorValue: 0xFF35C9D6,
      primaryAccentValue: 0xFFF59E0B,
      textColorValue: 0xFFFFFFFF,
      borderStyle: CardBorderStyle.softGlass,
      borderRadius: 14.0,
      fontFamily: 'Space Grotesk',
      layoutMode: PlanLayoutMode.bentoGrid,
    ),
    PlanTheme(
      presetId: 'parita_plum',
      presetName: 'Parita Plum',
      backgroundColorValue: 0xFF5D4E60,
      secondaryBackgroundValue: 0xFF4B3E4E,
      cardColorValue: 0xFFFFFFFF,
      primaryAccentValue: 0xFFE8B4B8,
      textColorValue: 0xFFFDFBF9,
      borderStyle: CardBorderStyle.softGlass,
      borderRadius: 18.0,
      fontFamily: 'DM Sans',
      layoutMode: PlanLayoutMode.timeline,
    ),
    PlanTheme(
      presetId: 'goodee_sandstone',
      presetName: 'Goodee Sandstone',
      backgroundColorValue: 0xFFE3D8C8,
      secondaryBackgroundValue: 0xFFD5C7B2,
      cardColorValue: 0xFFFFFFFF,
      primaryAccentValue: 0xFFEAB308,
      textColorValue: 0xFF1D1D28,
      borderStyle: CardBorderStyle.crispOutline,
      borderRadius: 16.0,
      fontFamily: 'Space Grotesk',
      layoutMode: PlanLayoutMode.magazine,
    ),
  ];
}

/// Individual modular block inside a Plan
class PlanBlock {
  final String id;
  final BlockType type;
  final BlockSize size;
  final String dayTag; // e.g., "Day 1", "Day 2", "Friday"
  final String title;
  final String subtitle;
  final String description;
  final String startTime; // e.g., "09:30 AM"
  final String endTime; // e.g., "11:00 AM"
  final String category; // e.g., "Food & Drink", "Activity", "Stay", "Nightlife", "Transit"
  final String? externalUrl;
  final String? externalUrlLabel;
  final String? costEstimate; // e.g., "$45 / person"
  final LocationData? location;
  final List<String> imageUrls; // Supports uploaded base64 data URLs or https URLs
  final int? customAccentColor;

  const PlanBlock({
    required this.id,
    required this.type,
    this.size = BlockSize.standard,
    this.dayTag = 'Day 1',
    required this.title,
    this.subtitle = '',
    this.description = '',
    this.startTime = '',
    this.endTime = '',
    this.category = 'Activity',
    this.externalUrl,
    this.externalUrlLabel,
    this.costEstimate,
    this.location,
    this.imageUrls = const [],
    this.customAccentColor,
  });

  bool get hasLocation => location != null && location!.isNotEmpty;

  PlanBlock copyWith({
    String? id,
    BlockType? type,
    BlockSize? size,
    String? dayTag,
    String? title,
    String? subtitle,
    String? description,
    String? startTime,
    String? endTime,
    String? category,
    String? externalUrl,
    String? externalUrlLabel,
    String? costEstimate,
    LocationData? location,
    bool clearLocation = false,
    List<String>? imageUrls,
    int? customAccentColor,
  }) {
    return PlanBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      size: size ?? this.size,
      dayTag: dayTag ?? this.dayTag,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      category: category ?? this.category,
      externalUrl: externalUrl ?? this.externalUrl,
      externalUrlLabel: externalUrlLabel ?? this.externalUrlLabel,
      costEstimate: costEstimate ?? this.costEstimate,
      location: clearLocation ? null : (location ?? this.location),
      imageUrls: imageUrls ?? this.imageUrls,
      customAccentColor: customAccentColor ?? this.customAccentColor,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'size': size.name,
        'dayTag': dayTag,
        'title': title,
        'subtitle': subtitle,
        'description': description,
        'startTime': startTime,
        'endTime': endTime,
        'category': category,
        if (externalUrl != null) 'externalUrl': externalUrl,
        if (externalUrlLabel != null) 'externalUrlLabel': externalUrlLabel,
        if (costEstimate != null) 'costEstimate': costEstimate,
        if (location != null) 'location': location!.toJson(),
        'imageUrls': imageUrls,
        if (customAccentColor != null) 'customAccentColor': customAccentColor,
      };

  factory PlanBlock.fromJson(Map<String, dynamic> json) {
    return PlanBlock(
      id: json['id'] as String? ?? 'block_${DateTime.now().millisecondsSinceEpoch}',
      type: BlockType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BlockType.placeEvent,
      ),
      size: BlockSize.values.firstWhere(
        (e) => e.name == json['size'],
        orElse: () => BlockSize.standard,
      ),
      dayTag: json['dayTag'] as String? ?? 'Day 1',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      description: json['description'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      category: json['category'] as String? ?? 'Activity',
      externalUrl: json['externalUrl'] as String?,
      externalUrlLabel: json['externalUrlLabel'] as String?,
      costEstimate: json['costEstimate'] as String?,
      location: json['location'] != null
          ? LocationData.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      customAccentColor: json['customAccentColor'] as int?,
    );
  }
}

/// Visibility and access control for shared plans (`plaans.co/<slug>`)
enum PlanVisibility {
  public,
  unlisted,
  pinProtected,
}

/// Top-level Plan / Itinerary document
class PlanModel {
  final String id;
  final String slug;
  final String title;
  final String subtitle;
  final String dateRangeLabel;
  final String authorName;
  final String? coverImageUrl;
  final String? avatarImageUrl;
  final PlanTheme theme;
  final List<PlanBlock> blocks;
  final DateTime updatedAt;
  final PlanVisibility visibility;
  final String? pinCode;
  final bool hasPin;
  final String? ownerUid;
  final bool isCloudSynced;
  final int viewCount;

  const PlanModel({
    required this.id,
    required this.slug,
    required this.title,
    required this.subtitle,
    this.dateRangeLabel = '',
    this.authorName = '',
    this.coverImageUrl,
    this.avatarImageUrl,
    required this.theme,
    required this.blocks,
    required this.updatedAt,
    this.visibility = PlanVisibility.public,
    this.pinCode,
    this.hasPin = false,
    this.ownerUid,
    this.isCloudSynced = false,
    this.viewCount = 0,
  });

  /// Returns all blocks that contain a valid location for map plotting & multi-stop routing
  List<PlanBlock> get locatedBlocks =>
      blocks.where((b) => b.hasLocation).toList();

  /// Returns distinct day tags across the itinerary
  List<String> get dayTags {
    final seen = <String>{};
    final result = <String>[];
    for (final block in blocks) {
      if (block.type == BlockType.dayHeader && block.dayTag.trim().isNotEmpty) {
        if (seen.add(block.dayTag.trim())) {
          result.add(block.dayTag.trim());
        }
      } else if (block.dayTag.trim().isNotEmpty && seen.add(block.dayTag.trim())) {
        result.add(block.dayTag.trim());
      }
    }
    return result;
  }

  PlanModel copyWith({
    String? id,
    String? slug,
    String? title,
    String? subtitle,
    String? dateRangeLabel,
    String? authorName,
    String? coverImageUrl,
    bool clearCoverImage = false,
    String? avatarImageUrl,
    bool clearAvatarImage = false,
    PlanTheme? theme,
    List<PlanBlock>? blocks,
    DateTime? updatedAt,
    PlanVisibility? visibility,
    String? pinCode,
    bool? hasPin,
    String? ownerUid,
    bool? isCloudSynced,
    int? viewCount,
  }) {
    return PlanModel(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      dateRangeLabel: dateRangeLabel ?? this.dateRangeLabel,
      authorName: authorName ?? this.authorName,
      coverImageUrl:
          clearCoverImage ? null : (coverImageUrl ?? this.coverImageUrl),
      avatarImageUrl:
          clearAvatarImage ? null : (avatarImageUrl ?? this.avatarImageUrl),
      theme: theme ?? this.theme,
      blocks: blocks ?? this.blocks,
      updatedAt: updatedAt ?? this.updatedAt,
      visibility: visibility ?? this.visibility,
      pinCode: pinCode ?? this.pinCode,
      hasPin: hasPin ?? this.hasPin,
      ownerUid: ownerUid ?? this.ownerUid,
      isCloudSynced: isCloudSynced ?? this.isCloudSynced,
      viewCount: viewCount ?? this.viewCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'title': title,
        'subtitle': subtitle,
        'dateRangeLabel': dateRangeLabel,
        'authorName': authorName,
        if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
        if (avatarImageUrl != null) 'avatarImageUrl': avatarImageUrl,
        'theme': theme.toJson(),
        'blocks': blocks.map((b) => b.toJson()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
        'visibility': visibility.name,
        if (pinCode != null && pinCode!.isNotEmpty) 'pinCode': pinCode,
        'hasPin': hasPin,
        if (ownerUid != null) 'ownerUid': ownerUid,
        'isCloudSynced': isCloudSynced,
        'viewCount': viewCount,
      };

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'] as String? ?? 'plan_default',
      slug: json['slug'] as String? ?? 'my-plan',
      title: json['title'] as String? ?? 'Untitled Plan',
      subtitle: json['subtitle'] as String? ?? '',
      dateRangeLabel: json['dateRangeLabel'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
      coverImageUrl: json['coverImageUrl'] as String?,
      avatarImageUrl: json['avatarImageUrl'] as String?,
      theme: json['theme'] != null
          ? PlanTheme.fromJson(json['theme'] as Map<String, dynamic>)
          : PlanTheme.presets.first,
      blocks: (json['blocks'] as List<dynamic>?)
              ?.map((e) => PlanBlock.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      visibility: PlanVisibility.values.firstWhere(
        (v) => v.name == json['visibility'],
        orElse: () => PlanVisibility.public,
      ),
      pinCode: json['pinCode'] as String?,
      hasPin: json['hasPin'] as bool? ?? false,
      ownerUid: json['ownerUid'] as String?,
      isCloudSynced: json['isCloudSynced'] as bool? ?? false,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// Encodes the plan into a URL-safe base64 payload for instant serverless link sharing.
  /// Large inline data-URI images are stripped if they exceed URL safety limits so links stay compact.
  String toShareablePayload() {
    final sanitizedBlocks = blocks.map((b) {
      final filteredImages = b.imageUrls
          .where((img) => !img.startsWith('data:') || img.length < 4000)
          .toList();
      return b.copyWith(imageUrls: filteredImages);
    }).toList();

    final compactPlan = copyWith(
      coverImageUrl: (coverImageUrl != null &&
              coverImageUrl!.startsWith('data:') &&
              coverImageUrl!.length > 4000)
          ? null
          : coverImageUrl,
      avatarImageUrl: (avatarImageUrl != null &&
              avatarImageUrl!.startsWith('data:') &&
              avatarImageUrl!.length > 4000)
          ? null
          : avatarImageUrl,
      blocks: sanitizedBlocks,
    );

    final jsonStr = jsonEncode(compactPlan.toJson());
    return base64UrlEncode(utf8.encode(jsonStr));
  }

  static PlanModel? fromShareablePayload(String encoded) {
    try {
      final decoded = utf8.decode(base64Url.decode(encoded));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      return PlanModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
