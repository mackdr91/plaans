import 'dart:convert';
import 'package:file_picker/file_picker.dart';

/// Handles uploading images from the user's device and provides curated aesthetic stock photos
class ImageService {
  /// Opens the native file picker to let the user upload an image (PNG, JPG, WEBP, GIF)
  /// Returns a base64 data URI string ready for immediate display & persistence.
  static Future<String?> pickImageAsDataUrl() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.image,
      );
      if (file == null) return null;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;

      final ext = (file.extension ?? 'jpeg').toLowerCase();
      String mime = 'image/jpeg';
      if (ext == 'png') mime = 'image/png';
      if (ext == 'webp') mime = 'image/webp';
      if (ext == 'gif') mime = 'image/gif';

      final base64Str = base64Encode(bytes);
      return 'data:$mime;base64,$base64Str';
    } catch (_) {
      return null;
    }
  }

  /// Curated high-aesthetic travel & event cover images
  static const List<Map<String, String>> curatedGallery = [
    {
      'label': 'Tokyo Neon Alley',
      'url':
          'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&w=1000&q=80',
    },
    {
      'label': 'Amalfi Coast Cliffside',
      'url':
          'https://images.unsplash.com/photo-1533105079780-92b9be482077?auto=format&fit=crop&w=1000&q=80',
    },
    {
      'label': 'Artisanal Matcha & Pastry',
      'url':
          'https://images.unsplash.com/photo-1515823064-d6e0c04616a7?auto=format&fit=crop&w=1000&q=80',
    },
    {
      'label': 'NYC SoHo Rooftop Cocktail',
      'url':
          'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?auto=format&fit=crop&w=1000&q=80',
    },
    {
      'label': 'Modern Art Gallery',
      'url':
          'https://images.unsplash.com/photo-1518998053901-5348d3961a04?auto=format&fit=crop&w=1000&q=80',
    },
    {
      'label': 'Kyoto Bamboo & Shrine',
      'url':
          'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?auto=format&fit=crop&w=1000&q=80',
    },
    {
      'label': 'Fine Dining Omakase',
      'url':
          'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?auto=format&fit=crop&w=1000&q=80',
    },
    {
      'label': 'Boutique Design Hotel',
      'url':
          'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1000&q=80',
    },
  ];
}
