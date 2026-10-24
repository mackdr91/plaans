import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/plan_models.dart';
import '../providers/plan_studio_provider.dart';
import '../widgets/auth_modal_sheet.dart';
import '../widgets/plan_image.dart';

/// Faithful Liinks.co-inspired Landing & Showcase Screen:

part 'landing/landing_phone_showcase_cards.dart';
/// - Floating frosted-glass pill navbar (`@plaans`, `Itineraries`, `GPS Maps`, `Templates`, dark pill `Open Studio`)
/// - Pastel aurora glow background (`LiinksAuroraBackground`)
/// - Split Hero Section:
///   - Left: Social proof rating badge (`★★★★★ 10,000+ trips & plans`), `"One link for every plan"` headline,
///     subtitle, and the signature `plaans.co/your-trip` claim bar with dark `Get Started` pill CTA.
///   - Right: 3 Fanned Tilted Phone Cards showing live interactive previews of curated itineraries.
/// - Bottom Marquee Strip (`QR CODES  ·  GOOGLE & APPLE MAPS GPS  ·  DRAG & DROP  ·  IMAGE UPLOADS  ·  DAY TABS`)
/// - `"Made with Plaans"` horizontal showcase of live itinerary phone cards.
class LiinksLandingScreen extends StatefulWidget {
  final PlanStudioProvider provider;

  const LiinksLandingScreen({super.key, required this.provider});

  @override
  State<LiinksLandingScreen> createState() => _LiinksLandingScreenState();
}

class _LiinksLandingScreenState extends State<LiinksLandingScreen> {
  final TextEditingController _claimSlugCtrl =
      TextEditingController(text: 'kyoto-autumn-trip');

  @override
  void dispose() {
    _claimSlugCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleClaimAndStart() async {
    final raw = _claimSlugCtrl.text.trim();
    final title = raw.isEmpty
        ? 'My Weekend Plan'
        : raw
            .split(RegExp(r'[-_\s]+'))
            .where((w) => w.isNotEmpty)
            .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');
    await widget.provider.createNewPlan(title: title);
  }

  @override
  Widget build(BuildContext context) {
    final plans = widget.provider.plans;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 980;
    final isMobile = screenWidth < 640;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: LiinksAuroraBackground(
        child: Stack(
          children: [
            // Main Scrollable Landing Content
            SingleChildScrollView(
              padding: EdgeInsets.only(top: isMobile ? 88 : 104, bottom: 64),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Hero Section (Mobile-First Column on Mobile/Tablet, Split Row on Desktop)
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 48 : (isMobile ? 18 : 28),
                          vertical: isDesktop ? 32 : 14,
                        ),
                        child: isDesktop
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 11,
                                    child: _buildHeroLeftColumn(
                                      context,
                                      isMobile: false,
                                    ),
                                  ),
                                  const SizedBox(width: 32),
                                  Expanded(
                                    flex: 13,
                                    child: _FannedHeroPhonesShowcase(
                                      plans: plans,
                                      isMobile: false,
                                      onSelectPlan: (plan) =>
                                          widget.provider.selectPlan(plan.id),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _buildHeroLeftColumn(
                                    context,
                                    isMobile: isMobile,
                                  ),
                                  const SizedBox(height: 32),
                                  _FannedHeroPhonesShowcase(
                                    plans: plans,
                                    isMobile: isMobile,
                                    onSelectPlan: (plan) =>
                                        widget.provider.selectPlan(plan.id),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // 2. Liinks-style Feature Ticker Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.55),
                      border: Border.symmetric(
                        horizontal: BorderSide(
                          color: const Color(0xFF1D1D28).withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceEvenly,
                      spacing: 28,
                      runSpacing: 12,
                      children: const [
                        _FeatureStripItem(
                          icon: Icons.qr_code_2_rounded,
                          label: 'QR CODES',
                        ),
                        _FeatureStripItem(
                          icon: Icons.pin_drop_outlined,
                          label: 'GOOGLE & APPLE MAPS GPS',
                        ),
                        _FeatureStripItem(
                          icon: Icons.drag_indicator_rounded,
                          label: 'DRAG & DROP STUDIO',
                        ),
                        _FeatureStripItem(
                          icon: Icons.photo_library_outlined,
                          label: 'IMAGE UPLOADS',
                        ),
                        _FeatureStripItem(
                          icon: Icons.folder_copy_outlined,
                          label: 'DAY TABS & FOLDERS',
                        ),
                        _FeatureStripItem(
                          icon: Icons.bolt_rounded,
                          label: 'SET UP IN MINUTES',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 68),

                  // 3. "Made with Plaans" Customer / Template Showcase Section
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1240),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            Text(
                              'Made with Plaans',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: isDesktop ? 48 : 34,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1D1D28),
                                letterSpacing: -1.1,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Real itineraries with live GPS pins. Tap any page to customize it live in the Studio.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16.5,
                                color: const Color(0xFF1D1D28)
                                    .withValues(alpha: 0.68),
                              ),
                            ),
                            const SizedBox(height: 36),
                            Wrap(
                              spacing: 24,
                              runSpacing: 24,
                              alignment: WrapAlignment.center,
                              children: plans.map((plan) {
                                return _MiniPhonePreviewCard(
                                  plan: plan,
                                  width: 285,
                                  height: 530,
                                  onTap: () =>
                                      widget.provider.selectPlan(plan.id),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Floating Frosted Pill Navigation Bar at Top (Mobile-First Responsive Header)
            Positioned(
              top: isMobile ? 12 : 18,
              left: isMobile ? 12 : 24,
              right: isMobile ? 12 : 24,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: Container(
                    height: isMobile ? 56 : 64,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 14 : 22,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF1D1D28).withValues(alpha: 0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // `@plaans` Logo (matching `@liinks`)
                        InkWell(
                          onTap: () {},
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: isMobile ? 24 : 28,
                                height: isMobile ? 24 : 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF1D1D28),
                                    width: 2.2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.alternate_email_rounded,
                                  size: isMobile ? 13.5 : 16,
                                  color: const Color(0xFF1D1D28),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'plaans',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: isMobile ? 19 : 22,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1D1D28),
                                  letterSpacing: -0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isDesktop) ...[
                          const SizedBox(width: 36),
                          _NavHeaderLink(
                            label: 'Itineraries',
                            hasDropdown: true,
                            onTap: () =>
                                widget.provider.setShowLandingHome(false),
                          ),
                          const SizedBox(width: 24),
                          _NavHeaderLink(
                            label: 'GPS & Maps',
                            onTap: () =>
                                widget.provider.setShowLandingHome(false),
                          ),
                          const SizedBox(width: 24),
                          _NavHeaderLink(
                            label: 'Templates',
                            hasDropdown: true,
                            onTap: () =>
                                widget.provider.setShowLandingHome(false),
                          ),
                        ],
                        const Spacer(),
                        if (!isMobile)
                          TextButton(
                            onPressed: () =>
                                widget.provider.setShowLandingHome(false),
                            child: Text(
                              'Studio Editor',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1D1D28),
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1D1D28),
                            side: const BorderSide(
                              color: Color(0xFFD4D4E0),
                              width: 1.4,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 11 : 15,
                              vertical: isMobile ? 8 : 11,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          onPressed: () => AuthModalSheet.show(context),
                          icon: Icon(
                            widget.provider.creatorUser != null
                                ? Icons.verified_user_rounded
                                : Icons.person_outline_rounded,
                            size: isMobile ? 14 : 16,
                            color: widget.provider.creatorUser != null
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF1D1D28),
                          ),
                          label: Text(
                            widget.provider.creatorUser != null
                                ? widget.provider.creatorUser!.displayName
                                : 'Sign in',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: isMobile ? 12 : 13.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1D1D28),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D1D28),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 16 : 22,
                              vertical: isMobile ? 11 : 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          onPressed: () =>
                              widget.provider.setShowLandingHome(false),
                          child: Text(
                            isMobile ? 'Open Studio' : 'Get started',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: isMobile ? 13 : 14.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
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

  Widget _buildHeroLeftColumn(BuildContext context, {required bool isMobile}) {
    return Column(
      crossAxisAlignment:
          isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        // Social Proof Pill (`★★★★★ 10,000+ creators & travelers`)
        Container(
          padding: EdgeInsets.fromLTRB(8, 5, isMobile ? 12 : 16, 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D1D28).withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              SizedBox(
                width: 62,
                height: 24,
                child: Stack(
                  children: const [
                    _MiniAvatarCircle(
                      left: 0,
                      color: Color(0xFFE04F33),
                      label: 'M',
                    ),
                    _MiniAvatarCircle(
                      left: 17,
                      color: Color(0xFF0A2A36),
                      label: 'A',
                    ),
                    _MiniAvatarCircle(
                      left: 34,
                      color: Color(0xFF5D4E60),
                      label: 'S',
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (_) => const Icon(
                    Icons.star_rounded,
                    size: 14.5,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 11.5 : 13,
                    color: const Color(0xFF1D1D28),
                  ),
                  children: const [
                    TextSpan(
                      text: '10,000+ ',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(
                      text: 'trips & plans',
                      style: TextStyle(color: Color(0xFF646474)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: isMobile ? 18 : 26),

        // Display Headline ("One link for every plan")
        Text(
          'One link for\nevery plan',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 44 : 68,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1D1D28),
            height: 1.04,
            letterSpacing: isMobile ? -1.4 : -2.0,
          ),
        ),

        const SizedBox(height: 16),

        // Subtitle
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 470),
          child: Text(
            'Design beautiful shareable itineraries with Google Maps & Apple Maps GPS links, drag-and-drop cards, and custom themes.',
            textAlign: isMobile ? TextAlign.center : TextAlign.left,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 15.5 : 18.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1D1D28).withValues(alpha: 0.78),
            ),
          ),
        ),

        SizedBox(height: isMobile ? 22 : 32),

        // Signature Liinks.co Claim Slug Pill Input Bar (`plaans.co/your-slug` + `Get Started`)
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 490),
          child: Container(
            padding: EdgeInsets.fromLTRB(isMobile ? 16 : 22, 6, 6, 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1D1D28).withValues(alpha: 0.08),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  'plaans.co/',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1D1D28),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _claimSlugCtrl,
                    decoration: const InputDecoration(
                      hintText: 'tokyo-weekend',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF646474),
                    ),
                    onSubmitted: (_) => _handleClaimAndStart(),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D1D28),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 24,
                      vertical: isMobile ? 13 : 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  onPressed: _handleClaimAndStart,
                  child: Text(
                    'Get Started',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 13.5 : 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

