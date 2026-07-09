import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/app/app.router.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/ui/common/app_colors.dart';

/// An always-shown-until-verified inline prompt for the VOLUNTEER profile
/// screen (verification is mandatory for volunteers, so — unlike the user
/// nudge — this is NOT dismissible). Self-contained: reads
/// [AuthenticationService] directly, rebuilds on its notifications, and
/// re-checks on foreground resume. Renders nothing once verified / for Google.
class VerifyEmailPrompt extends StatefulWidget {
  final String source;
  const VerifyEmailPrompt({super.key, this.source = 'volunteer_profile'});

  @override
  State<VerifyEmailPrompt> createState() => _VerifyEmailPromptState();
}

class _VerifyEmailPromptState extends State<VerifyEmailPrompt>
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
    if (state == AppLifecycleState.resumed && _auth.needsEmailVerification) {
      _auth.refreshEmailVerified();
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
    try {
      await _auth.refreshEmailVerified();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!_auth.needsEmailVerification) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.secondaryVeryLight.withAlpha(110),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondary.withAlpha(40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.mark_email_read_outlined,
                size: 20, color: AppColors.secondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verify your email',
                  style: GoogleFonts.crimsonPro(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Verify your email to start accepting chat requests.',
                  style: GoogleFonts.crimsonPro(
                    fontSize: 12.5,
                    height: 1.35,
                    color: AppColors.primaryVeryDark,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _verify,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      'Verify now',
                      style: GoogleFonts.crimsonPro(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.secondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
