part of '../studio_screen.dart';

/// Public Shared Visitor View Scaffold (shown when opening a shared link `/p/:slug`
/// or when clicking "Live Page")
class _PublicVisitorPreviewScaffold extends StatelessWidget {
  final PlanModel plan;
  final PlanStudioProvider provider;

  const _PublicVisitorPreviewScaffold({
    required this.plan,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: plan.theme.backgroundColor,
      body: Stack(
        children: [
          if (provider.isVisitorPinLocked)
            _PinProtectedUnlockView(plan: plan, provider: provider)
          else
            PlanPageCanvas(
              plan: plan,
              provider: provider,
              isEditable: false,
            ),
          // Floating Creator/Visitor Bar at Top Right
          Positioned(
            top: 16,
            right: 18,
            child: SafeArea(
              child: Wrap(
                spacing: 8,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.92),
                      foregroundColor: const Color(0xFF1D1D28),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    onPressed: () => provider.openUserItinerariesHome(),
                    icon: const Icon(Icons.home_outlined, size: 17),
                    label: const Text(
                      'Home',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.92),
                      foregroundColor: const Color(0xFF1D1D28),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    onPressed: () => provider.setVisitorView(false),
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: const Text(
                      'Edit in Studio',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D1D28),
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    onPressed: () => SharePlanDialog.show(
                      context,
                      plan: plan,
                      onPreviewPublicPage: () {},
                    ),
                    icon: const Icon(Icons.ios_share_rounded, size: 15),
                    label: const Text(
                      'Share Link',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mobile-first PIN Unlock Gate for `pinProtected` shared plans
class _PinProtectedUnlockView extends StatefulWidget {
  final PlanModel plan;
  final PlanStudioProvider provider;

  const _PinProtectedUnlockView({
    required this.plan,
    required this.provider,
  });

  @override
  State<_PinProtectedUnlockView> createState() =>
      _PinProtectedUnlockViewState();
}

class _PinProtectedUnlockViewState extends State<_PinProtectedUnlockView> {
  final _pinCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitPin() async {
    setState(() => _submitting = true);
    await widget.provider.unlockActivePlanWithPin(_pinCtrl.text.trim());
    if (mounted) {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF141413), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF141413),
                  offset: Offset(5, 5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D1D28),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.plan.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1D1D28),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'This private itinerary (`plaans.co/${widget.plan.slug}`) is protected with a group trip PIN.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF646474),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _pinCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  onSubmitted: (_) => _submitPin(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6,
                  ),
                  decoration: InputDecoration(
                    hintText: '••••',
                    counterText: '',
                    errorText: widget.provider.pinUnlockError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D1D28),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _submitting ? null : _submitPin,
                    icon: const Icon(Icons.lock_open_rounded, size: 18),
                    label: Text(
                      _submitting ? 'Verifying...' : 'Unlock Itinerary',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
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
