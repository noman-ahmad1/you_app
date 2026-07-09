import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/widgets.dart';

import 'verify_email_viewmodel.dart';

class VerifyEmailView extends StackedView<VerifyEmailViewModel> {
  /// Coarse analytics attribution passed through to the view model.
  final String source;
  const VerifyEmailView({super.key, this.source = 'nudge'});

  @override
  Widget builder(
    BuildContext context,
    VerifyEmailViewModel viewModel,
    Widget? child,
  ) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.backgroundGradient,
              AppColors.peachDark,
              AppColors.secondary
            ],
            stops: [0, 0.33, 0.66, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back (non-blocking) — returns "not verified".
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.background),
                    onPressed: viewModel.back,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: screenSize.height * 0.75),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.background.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mark_email_read_outlined,
                              size: 52,
                              color: AppColors.background,
                            ),
                          ),
                          Space.verticalSpaceSmall(context),
                          Text(
                            'Verify your email',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.crimsonPro(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: AppColors.secondary,
                            ),
                          ),
                          Space.verticalSpaceTiny(context),
                          Text(
                            "Verifying your email keeps your space safe — so you "
                            "never lose your journal, mood history, and messages "
                            "if you change or lose your phone.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.crimsonPro(
                              fontSize: 16,
                              height: 1.4,
                              color: AppColors.primaryVeryDark,
                            ),
                          ),
                          Space.verticalSpaceSmall(context),
                          Text(
                            'We sent a link to',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.crimsonPro(
                              fontSize: 14,
                              color: AppColors.primaryVeryDark,
                            ),
                          ),
                          Text(
                            viewModel.email,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.crimsonPro(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.background,
                            ),
                          ),
                          if (viewModel.statusMessage != null) ...[
                            Space.verticalSpaceSmall(context),
                            Text(
                              viewModel.statusMessage!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.crimsonPro(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondaryVeryLight,
                              ),
                            ),
                          ],
                          SizedBox(height: screenSize.height * 0.045),
                          CustomButton(
                            text: viewModel.isBusy
                                ? 'Checking…'
                                : "I've verified — check again",
                            onPressed:
                                viewModel.isBusy ? null : viewModel.checkAgain,
                          ),
                          Space.verticalSpaceTiny(context),
                          TextButton(
                            onPressed:
                                viewModel.canResend ? viewModel.resend : null,
                            child: Text(
                              viewModel.cooldown > 0
                                  ? 'Resend email in ${viewModel.cooldown}s'
                                  : 'Resend email',
                              style: GoogleFonts.crimsonPro(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: viewModel.canResend
                                    ? AppColors.secondaryVeryLight
                                    : AppColors.primaryDark,
                              ),
                            ),
                          ),
                          Space.verticalSpaceTiny(context),
                          TextButton(
                            onPressed: viewModel.back,
                            child: Text(
                              'Maybe later',
                              style: GoogleFonts.crimsonPro(
                                fontSize: 15,
                                color: AppColors.background,
                              ),
                            ),
                          ),
                        ],
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

  @override
  void onViewModelReady(VerifyEmailViewModel viewModel) => viewModel.onReady();

  @override
  VerifyEmailViewModel viewModelBuilder(BuildContext context) =>
      VerifyEmailViewModel(source: source);
}
