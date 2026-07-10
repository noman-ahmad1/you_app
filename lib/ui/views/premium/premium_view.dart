import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/animation_decoder.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/custom_lottie_loader.dart';
import 'package:you_app/ui/views/premium/premium_viewmodel.dart';

/// Standard horizontal inset for the screen's content sections.
Widget _hPad(Widget child) =>
    Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: child);

/// Immersive "You+" premium screen (from the Claude design), with our prices,
/// our feature-tile icons, and a Compare button that opens the Free-vs-Premium
/// breakdown as an in-screen sheet.
class PremiumView extends StackedView<PremiumViewModel> {
  const PremiumView({super.key});

  @override
  PremiumViewModel viewModelBuilder(BuildContext context) => PremiumViewModel();

  @override
  void onViewModelReady(PremiumViewModel viewModel) => viewModel.init();

  @override
  Widget builder(
      BuildContext context, PremiumViewModel viewModel, Widget? child) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary,
                  AppColors.backgroundGradient,
                  AppColors.peachDark,
                  AppColors.secondary
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon:
                          const Icon(Icons.close, color: AppColors.textPrimary),
                      onPressed: viewModel.close,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _hPad(_Hero(viewModel: viewModel, width: width)),
                          Space.verticalSpaceTiny(context),
                          ...viewModel.highlights
                              .map((h) => _hPad(_FeatureTile(highlight: h))),
                          Space.verticalSpaceVTiny(context),
                          _hPad(_CompareButton(
                            onTap: () => _showCompareSheet(context, viewModel),
                          )),
                          Space.verticalSpaceVTiny(context),
                          if (!viewModel.isPremium) ...[
                            // Plans span nearly the full safe-area width (a small side
                            // margin) with just a small gap between the two cards.
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 17),
                              child: _PlansRow(viewModel: viewModel),
                            ),
                            Space.verticalSpaceTiny(context),
                            _hPad(_Cta(viewModel: viewModel)),
                            Space.verticalSpaceTiny(context),
                            _hPad(Text(
                              viewModel.ctaSubline,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.crimsonPro(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withAlpha(235),
                              ),
                            )),
                            if (viewModel.purchaseError != null) ...[
                              Space.verticalSpaceVTiny(context),
                              _hPad(Text(
                                viewModel.purchaseError!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.crimsonPro(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.lightPink,
                                ),
                              )),
                            ],
                            Space.verticalSpaceTiny(context),
                            _hPad(_LegalRow(viewModel: viewModel)),
                          ] else
                            _hPad(_PremiumMemberBlock(viewModel: viewModel)),
                          Space.verticalSpaceTiny(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (viewModel.showCelebration) const _CelebrationOverlay(),
        ],
      ),
    );
  }

  void _showCompareSheet(BuildContext context, PremiumViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ComparisonSheet(viewModel: viewModel),
    );
  }
}

class _Hero extends StatelessWidget {
  final PremiumViewModel viewModel;
  final double width;
  const _Hero({required this.viewModel, required this.width});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipOval(
                child: Image.asset(
                  AppConstants.logoRound,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              // Animated "+" badge overlaid on the logo.
              Positioned(
                top: -6,
                right: -6,
                child: Lottie.asset(
                  AppConstants.plus,
                  decoder: customDecoder,
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
        // Space.verticalSpaceTiny(context),
        // Container(
        //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        //   decoration: BoxDecoration(
        //     color: Colors.white.withAlpha(210),
        //     borderRadius: BorderRadius.circular(30),
        //   ),
        //   child: Text(
        //     'YOU+',
        //     style: GoogleFonts.crimsonPro(
        //       fontSize: 14,
        //       fontWeight: FontWeight.w800,
        //       letterSpacing: 2.2,
        //       color: AppColors.secondary,
        //     ),
        //   ),
        // ),
        Space.verticalSpaceTiny(context),
        _heading(width),
        Space.verticalSpaceVTiny(context),
        Text(
          viewModel.isPremium
              ? 'Thank you for supporting You. Everything, unlocked.'
              : 'Everything You offers — unlocked, unlimited, and a little '
                  'more personal.',
          textAlign: TextAlign.center,
          style: GoogleFonts.crimsonPro(
            fontSize: 15.5,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: Colors.white.withAlpha(235),
          ),
        ),
      ],
    );
  }

  Widget _heading(double width) {
    final base = GoogleFonts.crimsonPro(
      fontSize: width * 0.078,
      fontWeight: FontWeight.w800,
      height: 1.12,
      color: Colors.white,
      shadows: [
        Shadow(color: AppColors.secondary.withAlpha(90), blurRadius: 12),
      ],
    );
    if (viewModel.isPremium) {
      return Text("You're YOU+ member",
          textAlign: TextAlign.center, style: base);
    }
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'Your safe space,\n'),
          TextSpan(
            text: 'without limits.',
            style: base.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.lightPink,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final PremiumHighlight highlight;
  const _FeatureTile({required this.highlight});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(150),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(170)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: highlight.tint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Image.asset(highlight.imageAsset, fit: BoxFit.contain),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  highlight.title,
                  style: GoogleFonts.crimsonPro(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryVeryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  highlight.subtitle,
                  style: GoogleFonts.crimsonPro(
                    fontSize: 13,
                    height: 1.3,
                    color: AppColors.textSecondary,
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

class _CompareButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CompareButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.compare_arrows_rounded,
            size: 18, color: Colors.white),
        label: Text(
          'Compare Free & Premium',
          style: GoogleFonts.crimsonPro(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            decoration: TextDecoration.underline,
            decorationColor: Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _PlansRow extends StatelessWidget {
  final PremiumViewModel viewModel;
  const _PlansRow({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    // Two equal-width cards filling the row, with just a small gap between them.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _PlanCard(
            period: 'Monthly',
            price: viewModel.monthlyPrice,
            per: 'per month',
            selected: viewModel.isSelected(BillingPeriod.monthly),
            onTap: () => viewModel.selectPlan(BillingPeriod.monthly),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PlanCard(
            period: 'Yearly',
            price: viewModel.yearlyPrice,
            per: viewModel.yearlyPerMonth,
            badge: viewModel.yearlySaveLabel,
            selected: viewModel.isSelected(BillingPeriod.yearly),
            onTap: () => viewModel.selectPlan(BillingPeriod.yearly),
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String period;
  final String price;
  final String per;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;
  const _PlanCard({
    required this.period,
    required this.price,
    required this.per,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 8), // room for the badge
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              // Fill the Expanded slot width (a non-positioned Stack child would
              // otherwise shrink to its text content).
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 16, 10, 14),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(selected ? 235 : 150),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppColors.secondary : Colors.white,
                  width: 2,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.secondary.withAlpha(60),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Text(
                    period.toUpperCase(),
                    style: GoogleFonts.crimsonPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    price,
                    style: GoogleFonts.crimsonPro(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryVeryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    per,
                    style: GoogleFonts.crimsonPro(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: -8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.secondary, AppColors.secondaryLight],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      badge!,
                      style: GoogleFonts.crimsonPro(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
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
}

class _Cta extends StatelessWidget {
  final PremiumViewModel viewModel;
  const _Cta({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.068,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.secondary, AppColors.secondaryLight],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withAlpha(90),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: viewModel.isWorking ? null : viewModel.subscribe,
            child: Center(
              child: viewModel.isWorking
                  ? const CustomLottieLoader(
                      width: 46,
                      height: 46,
                      loaderWidth: 170,
                      loaderHeight: 170,
                    )
                  : Text(
                      viewModel.ctaLabel,
                      style: GoogleFonts.crimsonPro(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalRow extends StatelessWidget {
  final PremiumViewModel viewModel;
  const _LegalRow({required this.viewModel});

  Widget _link(String label) => Builder(
        builder: (context) => GestureDetector(
          onTap: () => viewModel.onLegalTap(label),
          child: Text(
            label,
            style: GoogleFonts.crimsonPro(
              fontSize: 12.5,
              color: Colors.white.withAlpha(190),
              decoration: TextDecoration.underline,
              decorationColor: Colors.white54,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _link('Restore purchase'),
        const SizedBox(width: 22),
        _link('Terms'),
        const SizedBox(width: 22),
        _link('Privacy'),
      ],
    );
  }
}

/// Shown in place of the plans/CTA when the user is already Premium.
class _PremiumMemberBlock extends StatelessWidget {
  final PremiumViewModel viewModel;
  const _PremiumMemberBlock({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.068,
          child: Material(
            color: Colors.white.withAlpha(230),
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: viewModel.celebrate,
              child: Center(
                child: Text(
                  "You're YOU+ member 💛",
                  style: GoogleFonts.crimsonPro(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Cancelling happens in the Play Store — we only open it (see
        // PremiumViewModel.unsubscribe). Quiet by design: never alarming.
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.058,
          child: Material(
            color: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: BorderSide(color: Colors.white.withAlpha(150), width: 1.4),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: viewModel.isWorking ? null : viewModel.unsubscribe,
              child: Center(
                child: Text(
                  viewModel.isWorking ? 'Opening…' : 'Cancel subscription',
                  style: GoogleFonts.crimsonPro(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color:
                        Colors.white.withAlpha(viewModel.isWorking ? 150 : 235),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A brief (~2s) full-screen celebration shown after a successful subscribe:
/// a birthday-blast success animation behind the logo-with-plus mark.
class _CelebrationOverlay extends StatelessWidget {
  const _CelebrationOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        child: Container(
          color: Colors.black.withAlpha(105),
          child: Stack(
            children: [
              // Birthday-blast background (plays once).
              Positioned.fill(
                child: Lottie.asset(
                  AppConstants.success,
                  decoder: customDecoder,
                  fit: BoxFit.cover,
                  repeat: false,
                ),
              ),
              // Centered logo + animated plus mark and welcome line.
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipOval(
                            child: Image.asset(
                              AppConstants.logoRound,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: -8,
                            right: -8,
                            child: Lottie.asset(
                              AppConstants.plus,
                              decoder: customDecoder,
                              width: 60,
                              height: 60,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Welcome to YOU+',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.crimsonPro(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: AppColors.secondary.withAlpha(140),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Compare-only view: a bottom sheet with the full Free-vs-Premium table.
class _ComparisonSheet extends StatelessWidget {
  final PremiumViewModel viewModel;
  const _ComparisonSheet({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.secondaryVeryLight,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Row(
                  children: [
                    Text(
                      'Free vs Premium',
                      style: GoogleFonts.crimsonPro(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon:
                          const Icon(Icons.close, color: AppColors.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Column headers.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Expanded(flex: 4, child: SizedBox()),
                    Expanded(
                      flex: 3,
                      child: Text('Free',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.crimsonPro(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          )),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text('Premium',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.crimsonPro(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.secondary,
                          )),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: viewModel.comparison.length,
                  itemBuilder: (context, i) => _ComparisonRow(
                    row: viewModel.comparison[i],
                    shaded: i.isOdd,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final PlanRow row;
  final bool shaded;
  const _ComparisonRow({required this.row, required this.shaded});

  Widget _cell(String value, {required bool premium}) {
    if (value.isEmpty) {
      return Icon(Icons.remove,
          size: 16, color: AppColors.textSecondary.withAlpha(120));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_rounded,
            size: 15,
            color: premium ? AppColors.secondary : AppColors.textSecondary),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: GoogleFonts.crimsonPro(
            fontSize: 11.5,
            fontWeight: premium ? FontWeight.w700 : FontWeight.w500,
            color: premium ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: shaded ? AppColors.secondaryVeryLight.withAlpha(40) : null,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              row.feature,
              style: GoogleFonts.crimsonPro(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
              flex: 3, child: Center(child: _cell(row.free, premium: false))),
          Expanded(
              flex: 3, child: Center(child: _cell(row.premium, premium: true))),
        ],
      ),
    );
  }
}
