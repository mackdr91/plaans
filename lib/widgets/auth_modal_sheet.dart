import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/plan_studio_provider.dart';
import '../services/cloud_api_service.dart';

/// Mobile-first Liinks-styled Authentication Modal Sheet supporting:
/// - **Email & Password** (Sign In & Create Account)
/// - **Creator Account Profile & Sign Out** when authenticated
class AuthModalSheet extends StatefulWidget {
  const AuthModalSheet({super.key});

  static Future<void> show(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 640;
    if (isMobile) {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFFFAFAFC),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(color: Color(0xFF1D1D28), width: 2),
        ),
        builder: (_) => const SafeArea(child: AuthModalSheet()),
      );
    }

    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFFFAFAFC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF1D1D28), width: 2),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: const AuthModalSheet(),
        ),
      ),
    );
  }

  @override
  State<AuthModalSheet> createState() => _AuthModalSheetState();
}

class _AuthModalSheetState extends State<AuthModalSheet> {
  bool _isRegisterMode = false;
  bool _obscurePassword = true;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitEmailForm(PlanStudioProvider provider) async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final name = _nameCtrl.text.trim();

    bool ok;
    if (_isRegisterMode) {
      ok = await provider.registerWithEmail(
        email: email,
        password: password,
        displayName: name,
      );
    } else {
      ok = await provider.signInWithEmail(
        email: email,
        password: password,
      );
    }

    if (ok && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Signed in as ${provider.creatorUser?.displayName ?? email}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlanStudioProvider>();
    final user = provider.creatorUser;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 22,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: user != null
            ? _SignedInProfileView(
                user: user,
                provider: provider,
              )
            : _buildSignInOrRegisterView(context, provider),
      ),
    );
  }

  Widget _buildSignInOrRegisterView(
    BuildContext context,
    PlanStudioProvider provider,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Row
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF1D1D28),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.alternate_email_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isRegisterMode
                        ? 'Create your Plaans account'
                        : 'Sign in to Plaans',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1D1D28),
                    ),
                  ),
                  Text(
                    'Email & password authentication for cloud sync',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF646474),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Segmented Sign In / Create Account Toggle
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFEEEEF4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ModeTabButton(
                  label: 'Sign In',
                  selected: !_isRegisterMode,
                  onTap: () {
                    provider.clearAuthError();
                    setState(() => _isRegisterMode = false);
                  },
                ),
              ),
              Expanded(
                child: _ModeTabButton(
                  label: 'Create Account',
                  selected: _isRegisterMode,
                  onTap: () {
                    provider.clearAuthError();
                    setState(() => _isRegisterMode = true);
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        if (provider.authError != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF87171)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 18,
                  color: Color(0xFFB91C1C),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    provider.authError!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF991B1B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (_isRegisterMode) ...[
          TextField(
            controller: _nameCtrl,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Creator / Display Name',
              hintText: 'e.g. Maya Lin',
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 19),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],

        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onChanged: (_) => provider.clearAuthError(),
          decoration: InputDecoration(
            labelText: 'Email Address',
            hintText: 'you@example.com',
            prefixIcon: const Icon(Icons.mail_outline_rounded, size: 19),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 10),

        TextField(
          controller: _passwordCtrl,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onChanged: (_) => provider.clearAuthError(),
          onSubmitted: (_) => _submitEmailForm(provider),
          decoration: InputDecoration(
            labelText: _isRegisterMode
                ? 'Password (min 6 characters)'
                : 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 19),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1D1D28),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: provider.isAuthLoading
              ? null
              : () => _submitEmailForm(provider),
          child: Text(
            provider.isAuthLoading
                ? 'Authenticating...'
                : (_isRegisterMode
                    ? 'Create Account & Sync Plans'
                    : 'Sign In with Email'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SignedInProfileView extends StatelessWidget {
  final CreatorUser user;
  final PlanStudioProvider provider;

  const _SignedInProfileView({
    required this.user,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF1D1D28),
              child: Text(
                user.initials,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1D1D28),
                    ),
                  ),
                  Text(
                    user.email,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: const Color(0xFF646474),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1D1D28), width: 1.5),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 18,
                    color: Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Authenticated with Email & Password',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1D1D28),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  const Icon(
                    Icons.cloud_done_outlined,
                    size: 18,
                    color: Color(0xFF475569),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${provider.plans.length} itineraries ready to sync with MongoDB',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1D1D28),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () async {
            await provider.publishActivePlanToCloud();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Active itinerary synced to MongoDB!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          icon: const Icon(Icons.cloud_upload_outlined, size: 18),
          label: const Text(
            'Sync Active Plan Now',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFB91C1C),
            side: const BorderSide(color: Color(0xFFFCA5A5)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () async {
            await provider.signOutCreator();
          },
          icon: const Icon(Icons.logout_rounded, size: 17),
          label: const Text(
            'Sign Out',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _ModeTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: selected
                ? const Color(0xFF1D1D28)
                : const Color(0xFF646474),
          ),
        ),
      ),
    );
  }
}
