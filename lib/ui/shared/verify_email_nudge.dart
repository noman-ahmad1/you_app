import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:you_app/ui/common/app_colors.dart';

/// A gentle, dismissible card nudging unverified email/password USERS to verify
/// their email — framed as protecting THEIR data, never a chore or warning.
/// Shown on the user home and profile. Visibility and dismissal are owned by the
/// host view model (see [VerifyEmailNudgePrefs]); this widget is presentational.
class VerifyEmailNudge extends StatelessWidget {
  final VoidCallback onVerify;
  final VoidCallback onDismiss;
  const VerifyEmailNudge({
    super.key,
    required this.onVerify,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
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
                  'Keep your space safe',
                  style: GoogleFonts.crimsonPro(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Verify your email so you don't lose your journal and mood "
                  'history if you ever change phones.',
                  style: GoogleFonts.crimsonPro(
                    fontSize: 12.5,
                    height: 1.35,
                    color: AppColors.primaryVeryDark,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: onVerify,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      'Verify email',
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
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onDismiss,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close,
                  size: 16, color: AppColors.primaryVeryDark.withAlpha(140)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Persistence for the USER nudge's "respect a dismissal for a sensible
/// cooldown" behaviour. A dismissal hides the nudge for [_cooldown]; afterward
/// it gently returns (only while the email is still unverified).
class VerifyEmailNudgePrefs {
  const VerifyEmailNudgePrefs._();

  static const String _key = 'verify_email_nudge_dismissed_until';
  static const Duration _cooldown = Duration(days: 7);

  static Future<bool> isDismissedActive() async {
    final prefs = await SharedPreferences.getInstance();
    final until = prefs.getInt(_key);
    if (until == null) return false;
    return DateTime.now().millisecondsSinceEpoch < until;
  }

  static Future<void> dismissForCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final until = DateTime.now().add(_cooldown).millisecondsSinceEpoch;
    await prefs.setInt(_key, until);
  }
}
