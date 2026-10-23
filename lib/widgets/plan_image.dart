import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/plan_models.dart';

/// Resolves the dynamic GoogleFont TextStyle for a PlanTheme
TextStyle planTextStyle(
  PlanTheme theme, {
  double fontSize = 15,
  FontWeight fontWeight = FontWeight.w500,
  Color? color,
  double? height,
  double? letterSpacing,
  bool isDisplayHeading = false,
}) {
  final effectiveColor = color ?? theme.textColor;
  // On dark backgrounds where cards are white, use dark text when inside cards if passed explicitly
  switch (theme.fontFamily) {
    case 'Playfair Display':
      if (isDisplayHeading) {
        return GoogleFonts.playfairDisplay(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: effectiveColor,
          height: height,
          letterSpacing: letterSpacing,
        );
      }
      return GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: effectiveColor,
        height: height,
        letterSpacing: letterSpacing,
      );
    case 'Syne':
      return GoogleFonts.syne(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: effectiveColor,
        height: height,
        letterSpacing: letterSpacing,
      );
    case 'Plus Jakarta Sans':
      return GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: effectiveColor,
        height: height,
        letterSpacing: letterSpacing,
      );
    case 'DM Sans':
      return GoogleFonts.dmSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: effectiveColor,
        height: height,
        letterSpacing: letterSpacing,
      );
    case 'Space Grotesk':
    default:
      return GoogleFonts.spaceGrotesk(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: effectiveColor,
        height: height,
        letterSpacing: letterSpacing,
      );
  }
}

/// Returns a readable text color specifically for text sitting on top of `theme.cardColor`
Color planCardTextColor(PlanTheme theme) {
  final cardBrightness = ThemeData.estimateBrightnessForColor(theme.cardColor);
  return cardBrightness == Brightness.dark
      ? const Color(0xFFF8FAFC)
      : const Color(0xFF1D1D28);
}

/// Builds a themed container decoration matching Liinks.co's sleek soft-glow cards
BoxDecoration planCardDecoration(
  PlanTheme theme, {
  Color? overrideColor,
  bool isHighlighted = false,
  double? radiusOverride,
}) {
  final radius = BorderRadius.circular(radiusOverride ?? theme.borderRadius);
  final bg = overrideColor ?? theme.cardColor;

  switch (theme.borderStyle) {
    case CardBorderStyle.softGlass:
      return BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(
          color: isHighlighted
              ? theme.primaryAccent
              : const Color(0xFF1D1D28).withValues(alpha: 0.08),
          width: isHighlighted ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D1D28).withValues(alpha: 0.07),
            offset: const Offset(0, 8),
            blurRadius: 24,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: const Color(0xFF1D1D28).withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      );
    case CardBorderStyle.crispOutline:
      return BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(
          color: isHighlighted
              ? theme.primaryAccent
              : const Color(0xFF1D1D28).withValues(alpha: 0.16),
          width: isHighlighted ? 2.0 : 1.2,
        ),
      );
    case CardBorderStyle.minimalFlat:
      return BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: isHighlighted
            ? Border.all(color: theme.primaryAccent, width: 2.0)
            : null,
      );
    case CardBorderStyle.brutalistShadow:
      return BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(
          color: isHighlighted ? theme.primaryAccent : const Color(0xFF1D1D28),
          width: isHighlighted ? 2.2 : 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlighted
                ? theme.primaryAccent
                : const Color(0xFF1D1D28).withValues(alpha: 0.85),
            offset: const Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      );
  }
}

/// Signature Liinks.co pastel aurora radial glow background
class LiinksAuroraBackground extends StatelessWidget {
  final Widget child;
  final Color baseColor;

  const LiinksAuroraBackground({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFFAFAFC),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: baseColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Top-left lavender radial glow
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 520,
              height: 520,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE0E7FF).withValues(alpha: 0.65),
                    const Color(0xFFE0E7FF).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // Top-right sky-blue radial glow
          Positioned(
            top: 40,
            right: -100,
            child: Container(
              width: 560,
              height: 560,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFDFF2FE).withValues(alpha: 0.65),
                    const Color(0xFFDFF2FE).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // Bottom-center soft rose/pink glow
          Positioned(
            bottom: -140,
            left: 180,
            right: 180,
            child: Container(
              height: 460,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFCE7F3).withValues(alpha: 0.6),
                    const Color(0xFFFCE7F3).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Renders either an uploaded `data:image/...;base64,...` image or an `https://` network image cleanly
class UniversalPlanImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const UniversalPlanImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (imageUrl.startsWith('data:image')) {
      try {
        final commaIdx = imageUrl.indexOf(',');
        final base64Part =
            commaIdx >= 0 ? imageUrl.substring(commaIdx + 1) : imageUrl;
        final bytes = base64Decode(base64Part);
        child = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => _fallbackPlaceholder(),
        );
      } catch (_) {
        child = _fallbackPlaceholder();
      }
    } else {
      child = Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _fallbackPlaceholder(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }

  Widget _fallbackPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFECEAE4),
      alignment: Alignment.center,
      child: const Icon(
        Icons.photo_camera_back_outlined,
        color: Color(0xFF78716C),
        size: 24,
      ),
    );
  }
}
