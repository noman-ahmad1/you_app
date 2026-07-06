import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/animation_decoder.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/views/paywall/paywall_viewmodel.dart';

/// A focused, contextual upsell: it elaborates the ONE feature the user was
/// gated on, hints that You+ includes much more, and sends them to the full
/// You+ screen. No pricing here — that lives on the You+ screen.
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
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(viewModel: viewModel),
                      Space.verticalSpaceTiny(context),
                      Space.verticalSpaceTiny(context),
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
                      Space.verticalSpaceSmall(context),
                      _UpsellCard(viewModel: viewModel),
                      Space.verticalSpaceTiny(context),
                      _MoreNote(viewModel: viewModel),
                      Space.verticalSpaceSmall(context),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated You+ mark.
class _Header extends StatelessWidget {
  final PaywallViewModel viewModel;
  const _Header({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        AppConstants.plus,
        decoder: customDecoder,
        width: 84,
        height: 84,
        fit: BoxFit.contain,
      ),
    );
  }
}

/// The one feature the user unlocks — icon, title, and an elaboration of the
/// extra they get by upgrading.
class _UpsellCard extends StatelessWidget {
  final PaywallViewModel viewModel;
  const _UpsellCard({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final upsell = viewModel.upsell;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 75,
            height: 75,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
                // color: upsell.tint.withAlpha(38),
                // borderRadius: BorderRadius.circular(16),
                ),
            child: Image.asset(upsell.imageAsset, fit: BoxFit.contain),
          ),
          Space.verticalSpaceVTiny(context),
          Text(
            upsell.title,
            style: GoogleFonts.crimsonPro(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.1,
            ),
          ),
          Space.verticalSpaceVTiny(context),
          Text(
            upsell.description,
            style: GoogleFonts.crimsonPro(
              fontSize: 15,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle "there's much more in You+" reminder.
class _MoreNote extends StatelessWidget {
  final PaywallViewModel viewModel;
  const _MoreNote({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: viewModel.accent.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 18, color: viewModel.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              viewModel.moreNote,
              style: GoogleFonts.crimsonPro(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: viewModel.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width gradient "Upgrade to YOU+" CTA.
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
                'Upgrade to YOU+',
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
