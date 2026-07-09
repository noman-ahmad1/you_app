import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/ui/common/app_colors.dart';

/// A NON-dismissible verify block for VOLUNTEERS: a scrim + card that persists
/// (on the pending-approval screen and the dashboard) until the volunteer's
/// email is verified, so they cannot accept chat requests while unverified.
///
/// Self-contained: reads [AuthenticationService] directly, rebuilds on its
/// notifications, and re-checks (reload) on foreground resume — so it lifts the
/// instant they verify. Renders nothing (blocks nothing) when verified or for
/// Google users. MUST be placed as a child of a Stack (it uses Positioned.fill).
class VerifyEmailBlock extends StatefulWidget {
  final String source;
  const VerifyEmailBlock({super.key, this.source = 'volunteer_block'});

  @override
  State<VerifyEmailBlock> createState() => _VerifyEmailBlockState();
}

class _VerifyEmailBlockState extends State<VerifyEmailBlock>
    with WidgetsBindingObserver {
  final _auth = locator<AuthenticationService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _auth.addListener(_onChange);
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // They may have clicked the link and returned — re-check to lift the block.
    if (state == AppLifecycleState.resumed && _auth.needsEmailVerification) {
      _auth.refreshEmailVerified(); // notifies → _onChange rebuilds
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onChange);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _verify() async {
    locator<AnalyticsService>().logVerificationPrompted(context: widget.source);
    await locator<NavigationService>()
        .navigateToVerifyEmailView(source: widget.source);
    // Refresh on return so the block lifts immediately if they verified.
    try {
      await _auth.refreshEmailVerified();
    } catch (_) {}
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    await locator<NavigationService>().clearStackAndShow(Routes.welcomeView);
  }

  @override
  Widget build(BuildContext context) {
    if (!_auth.needsEmailVerification) return const SizedBox.shrink();

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          AppColors.secondaryVeryLight.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mark_email_read_outlined,
                        size: 40, color: AppColors.secondary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Verify your email',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.crimsonPro(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please verify your email to continue and start accepting '
                    'chat requests. It keeps the people you support safe.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.crimsonPro(
                      fontSize: 15,
                      height: 1.4,
                      color: AppColors.primaryVeryDark,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _verify,
                      child: Text(
                        'Verify email',
                        style: GoogleFonts.crimsonPro(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: _logout,
                    child: Text(
                      'Log out',
                      style: GoogleFonts.crimsonPro(
                        fontSize: 15,
                        color: AppColors.primaryVeryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
