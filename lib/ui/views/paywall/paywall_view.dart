import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/animation_decoder.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/views/paywall/paywall_viewmodel.dart';

class PaywallView extends StackedView<PaywallViewModel> {
  /// The gate that triggered this paywall (see PaywallFeature.*).
  final String feature;

  const PaywallView({this.feature = 'general', Key? key}) : super(key: key);

  @override
  PaywallViewModel viewModelBuilder(BuildContext context) =>
      PaywallViewModel(feature: feature);

  @override
  Widget builder(
      BuildContext context, PaywallViewModel viewModel, Widget? child) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.secondaryVeryLight, AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textPrimary),
                  onPressed: viewModel.close,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(viewModel: viewModel, width: width),
                      Space.verticalSpaceSmall(context),
                      Text(
                        viewModel.headline,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.crimsonPro(
                          fontSize: width * 0.058,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      Space.verticalSpaceTiny(context),
                      Text(
                        viewModel.subheadline,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.crimsonPro(
                          fontSize: width * 0.038,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Space.verticalSpaceSmall(context),
                      ...viewModel.benefits.map((b) =>
                          _BenefitCard(benefit: b, accent: viewModel.accent)),
                      Space.verticalSpaceSmall(context),
                    ],
                  ),
                ),
              ),
              _Footer(viewModel: viewModel, width: width),
            ],
          ),
        ),
      ),
    );
  }
}

/// Premium badge header — a soft glow behind a crown + "PREMIUM" pill.
class _Header extends StatelessWidget {
  final PaywallViewModel viewModel;
  final double width;
  const _Header({required this.viewModel, required this.width});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                viewModel.accent.withOpacity(0.20),
                viewModel.accent.withOpacity(0.06),
              ],
            ),
          ),
          child: Lottie.asset(
            AppConstants.premium,
            decoder: customDecoder,
            width: 88,
            height: 88,
            fit: BoxFit.contain,
          ),
        ),
        // Space.verticalSpaceVTiny(context),
        // Container(
        //   padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        //   decoration: BoxDecoration(
        //     color: viewModel.accent,
        //     borderRadius: BorderRadius.circular(20),
        //   ),
        //   child: Text(
        //     'YOU PREMIUM',
        //     style: GoogleFonts.crimsonPro(
        //       fontSize: width * 0.03,
        //       fontWeight: FontWeight.w800,
        //       letterSpacing: 1.5,
        //       color: AppColors.background,
        //     ),
        //   ),
        // ),
      ],
    );
  }
}

/// A single benefit rendered as a soft card with an asset illustration.
class _BenefitCard extends StatelessWidget {
  final PremiumBenefit benefit;
  final Color accent;
  const _BenefitCard({required this.benefit, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Image.asset(benefit.imageAsset, fit: BoxFit.contain),
          ),
          Space.horizontalSpaceSmall(context),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  benefit.title,
                  style: GoogleFonts.crimsonPro(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  benefit.subtitle,
                  style: GoogleFonts.crimsonPro(
                    fontSize: 12.5,
                    height: 1.3,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Space.horizontalSpaceTiny(context),
          Icon(Icons.check_circle_rounded, color: accent, size: 22),
        ],
      ),
    );
  }
}

/// Price, upgrade CTA, and the always-free crisis reassurance.
class _Footer extends StatelessWidget {
  final PaywallViewModel viewModel;
  final double width;
  const _Footer({required this.viewModel, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${AppConstants.defaultCurrencyCode} 300',
                  style: GoogleFonts.crimsonPro(
                    fontSize: width * 0.06,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextSpan(
                  text: ' / month',
                  style: GoogleFonts.crimsonPro(
                    fontSize: width * 0.04,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Space.verticalSpaceTiny(context),
          Space.verticalSpaceVTiny(context),
          _UpgradeButton(viewModel: viewModel),
          Space.verticalSpaceTiny(context),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 5),
              Text(
                'Crisis support is always free, for everyone.',
                style: GoogleFonts.crimsonPro(
                  fontSize: width * 0.03,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: viewModel.close,
            child: Text(
              'Maybe later',
              style: GoogleFonts.crimsonPro(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width gradient upgrade CTA.
class _UpgradeButton extends StatelessWidget {
  final PaywallViewModel viewModel;
  const _UpgradeButton({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.065;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [viewModel.accent, AppColors.secondaryLight],
            ),
            borderRadius: BorderRadius.circular(27),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(27),
            onTap: viewModel.onUpgrade,
            child: Center(
              child: Text(
                'Upgrade to Premium',
                style: GoogleFonts.crimsonPro(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.background,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
