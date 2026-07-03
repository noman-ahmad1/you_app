import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/shared/topbar.dart';

/// Read-only Volunteer Code of Conduct & Guidelines screen.
/// No actions other than navigating back.
class VolunteerGuidelinesView extends StatelessWidget {
  const VolunteerGuidelinesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppConstants.background),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            TopBar(
              leadingIconAsset: AppConstants.back,
              iconColor: AppColors.primaryVeryDark,
              onLeadingPressed: () => Navigator.pop(context),
              title: 'Guidelines',
              trailingActions: const [],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Volunteer Code of Conduct & Guidelines',
                          style: GoogleFonts.crimsonPro(
                            fontSize: 27,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _paragraph(
                          'Thank you for being a listener on You. Your empathy and time make a profound difference to those navigating difficult moments.',
                        ),
                        const SizedBox(height: 10),
                        _paragraph(
                          'To ensure this platform remains a safe, secure, and healing environment for both our users and you, please carefully review your responsibilities.',
                        ),
                        const SizedBox(height: 24),
                        _section(
                          title: 'Your Core Role',
                          tag: "The Do's",
                          icon: Icons.volunteer_activism_rounded,
                          accent: AppColors.green,
                          items: const [
                            _Guideline(
                              'Practice Active Listening',
                              'Your primary goal is to provide a safe, judgment-free space. Validate their feelings, listen to understand (not just to reply), and be present.',
                            ),
                            _Guideline(
                              'Maintain Absolute Confidentiality',
                              'Privacy is our foundation. Treat every conversation with the utmost respect and secrecy.',
                            ),
                            _Guideline(
                              'Use the Emergency Escalation Button',
                              'If a user expresses intent to harm themselves or others, immediately use the escalate button. You are a peer listener, not a crisis responder—never attempt to handle immediate emergencies alone.',
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _section(
                          title: 'Strict Boundaries',
                          tag: "The Don'ts",
                          icon: Icons.gpp_maybe_rounded,
                          accent: AppColors.error,
                          note:
                              'Violating these rules compromises user safety and will result in immediate removal from the platform.',
                          items: const [
                            _Guideline(
                              'No Diagnosing or Prescribing',
                              'You are providing peer-to-peer emotional support, not clinical therapy. Never attempt to formally diagnose a user, suggest treatments, or advise them on medications.',
                            ),
                            _Guideline(
                              'No Contact Exchanging',
                              'Never share your personal phone number, social media handles, or physical location, and never ask a user for theirs. All communication must remain inside the app.',
                            ),
                            _Guideline(
                              'No Screenshots or Recording',
                              'Capturing, saving, or sharing chat logs is a severe violation of user privacy and our zero-content logging policy.',
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _section(
                          title: 'Protecting Your Own Peace',
                          icon: Icons.self_improvement_rounded,
                          accent: AppColors.secondary,
                          items: const [
                            _Guideline(
                              'Toggle Your Availability',
                              'Only switch your status to "Online" when you are in a quiet, private environment and have the emotional bandwidth to take on someone else\'s struggles.',
                            ),
                            _Guideline(
                              'Log Off When Needed',
                              'Secondary burnout is real. If you feel overwhelmed, end your session gracefully and take a break. You cannot pour from an empty cup.',
                            ),
                          ],
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

  Widget _paragraph(String text) => Text(
        text,
        style: GoogleFonts.crimsonPro(
          fontSize: 14,
          height: 1.55,
          color: AppColors.primaryVeryDark.withAlpha(200),
        ),
      );

  Widget _section({
    required String title,
    required IconData icon,
    required Color accent,
    required List<_Guideline> items,
    String? tag,
    String? note,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withAlpha(242),
            accent.withAlpha(28),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: AppColors.primaryVeryDark.withAlpha(20), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryVeryDark.withAlpha(18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                    color: accent.withAlpha(36), shape: BoxShape.circle),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.crimsonPro(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryVeryDark,
                  ),
                ),
              ),
              if (tag != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.crimsonPro(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withAlpha(22),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                note,
                style: GoogleFonts.crimsonPro(
                  fontSize: 12.5,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          ...items.map((g) => _bullet(g, accent)),
        ],
      ),
    );
  }

  Widget _bullet(_Guideline g, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(Icons.check_circle_rounded, size: 17, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${g.heading}. ',
                    style: GoogleFonts.crimsonPro(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryVeryDark,
                    ),
                  ),
                  TextSpan(
                    text: g.body,
                    style: GoogleFonts.crimsonPro(
                      fontSize: 13.5,
                      height: 1.5,
                      color: AppColors.primaryVeryDark.withAlpha(190),
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

class _Guideline {
  final String heading;
  final String body;
  const _Guideline(this.heading, this.body);
}
