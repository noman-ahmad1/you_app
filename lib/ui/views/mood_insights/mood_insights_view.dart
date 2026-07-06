import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/animation_decoder.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/shared/custom_lottie_loader.dart';
import 'package:you_app/ui/shared/fade_slide_in.dart';
import 'package:you_app/ui/shared/topbar.dart';
import 'package:you_app/ui/views/mood_insights/mood_insights_viewmodel.dart';

/// The YOU+ Mood Insights screen — a calm, warm read of the user's patterns,
/// led by one hero insight and followed by gentle, agency-oriented detail.
class MoodInsightsView extends StackedView<MoodInsightsViewModel> {
  const MoodInsightsView({super.key});

  @override
  MoodInsightsViewModel viewModelBuilder(BuildContext context) =>
      MoodInsightsViewModel();

  @override
  void onViewModelReady(MoodInsightsViewModel viewModel) => viewModel.load();

  @override
  Widget builder(
      BuildContext context, MoodInsightsViewModel viewModel, Widget? child) {
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
              title: 'Mood Insights',
              trailingActions: const [],
            ),
            Expanded(
              child: _body(context, viewModel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, MoodInsightsViewModel viewModel) {
    if (viewModel.isBusy) {
      return const Center(child: CustomLottieLoader());
    }
    if (!viewModel.hasEnoughData) {
      return _EmptyState();
    }

    final cards = <Widget>[
      _HeroCard(viewModel: viewModel),
      if (viewModel.showCorrelation) _CorrelationCard(viewModel: viewModel),
      if (viewModel.showWeekday) _WeekdayCard(viewModel: viewModel),
      if (viewModel.showTimeOfDay) _TimeOfDayCard(viewModel: viewModel),
      _ConsistencyCard(viewModel: viewModel),
      _BalanceCard(viewModel: viewModel),
      _ReflectionCard(viewModel: viewModel),
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < cards.length; i++)
            FadeSlideIn(
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: cards[i],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared building blocks
// ---------------------------------------------------------------------------

/// A soft white insight card.
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background.withAlpha(220),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.background, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

Widget _sectionTitle(String text) => Text(
      text,
      style: GoogleFonts.crimsonPro(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: AppColors.secondary,
      ),
    );

Widget _bodyText(String text) => Text(
      text,
      style: GoogleFonts.crimsonPro(
        fontSize: 15.5,
        height: 1.45,
        fontWeight: FontWeight.w500,
        color: AppColors.primaryVeryDark,
      ),
    );

/// A small gentle suggestion sub-box (agency for a tougher pattern).
class _Suggestion extends StatelessWidget {
  final String text;
  const _Suggestion({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.green.withAlpha(28),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.spa_outlined, size: 18, color: AppColors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.crimsonPro(
                fontSize: 14.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: AppColors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A row of animated vertical bars with labels, optionally highlighting one.
class _MiniBars extends StatelessWidget {
  final List<double?> values; // 0..1 (null = no data)
  final List<String> labels;
  final int? highlightIndex;
  final double maxHeight;
  const _MiniBars({
    required this.values,
    required this.labels,
    this.highlightIndex,
    this.maxHeight = 88,
  });

  @override
  Widget build(BuildContext context) {
    // Room for the bar (maxHeight) + gap + up to two lines of label.
    return SizedBox(
      height: maxHeight + 46,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (int i = 0; i < values.length; i++)
            Expanded(
              child: _bar(i),
            ),
        ],
      ),
    );
  }

  Widget _bar(int i) {
    final v = values[i];
    final highlighted = highlightIndex == i;
    final gradient = highlighted
        ? [
            Color.lerp(AppColors.green, AppColors.background, 0.45)!,
            AppColors.green,
          ]
        : [AppColors.lightPink, AppColors.secondaryLight];

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          height: maxHeight,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0, end: v ?? 0),
              builder: (context, t, _) {
                final h = v == null ? 6.0 : (10 + t * (maxHeight - 12));
                return Container(
                  width: 18,
                  height: h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: v == null
                        ? null
                        : LinearGradient(
                            colors: gradient,
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                    color: v == null
                        ? AppColors.secondaryVeryLight.withAlpha(120)
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          labels[i],
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.crimsonPro(
            fontSize: 12.5,
            height: 1.15,
            fontWeight: FontWeight.w700,
            color: highlighted ? AppColors.green : AppColors.primaryVeryDark,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Cards
// ---------------------------------------------------------------------------

class _HeroCard extends StatelessWidget {
  final MoodInsightsViewModel viewModel;
  const _HeroCard({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.secondary, AppColors.secondaryLight],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withAlpha(70),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  size: 18, color: AppColors.background),
              const SizedBox(width: 8),
              Text(
                'YOUR PATTERN',
                style: GoogleFonts.crimsonPro(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: AppColors.background.withAlpha(210),
                ),
              ),
            ],
          ),
          Space.verticalSpaceTiny(context),
          Text(
            viewModel.heroTitle,
            style: GoogleFonts.crimsonPro(
              fontSize: 26,
              height: 1.15,
              fontWeight: FontWeight.w800,
              color: AppColors.background,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            viewModel.heroBody,
            style: GoogleFonts.crimsonPro(
              fontSize: 16,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: AppColors.background.withAlpha(230),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayCard extends StatelessWidget {
  final MoodInsightsViewModel viewModel;
  const _WeekdayCard({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Your week, gently mapped'),
          const SizedBox(height: 6),
          _bodyText(viewModel.weekdayInsight),
          Space.verticalSpaceTiny(context),
          _MiniBars(
            values: viewModel.weekdayAverages,
            labels: MoodInsightsViewModel.weekdayShort,
            highlightIndex:
                viewModel.showWeekday ? viewModel.brightestWeekday : null,
          ),
          if (viewModel.weekdaySuggestion.isNotEmpty) ...[
            Space.verticalSpaceTiny(context),
            _Suggestion(text: viewModel.weekdaySuggestion),
          ],
        ],
      ),
    );
  }
}

class _TimeOfDayCard extends StatelessWidget {
  final MoodInsightsViewModel viewModel;
  const _TimeOfDayCard({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Times of day'),
          const SizedBox(height: 6),
          _bodyText(viewModel.timeInsight),
          Space.verticalSpaceSmall(context),
          _MiniBars(
            values: viewModel.timeAverages,
            labels: MoodInsightsViewModel.bucketNames,
            highlightIndex: viewModel.brightestBucket,
          ),
        ],
      ),
    );
  }
}

class _CorrelationCard extends StatelessWidget {
  final MoodInsightsViewModel viewModel;
  const _CorrelationCard({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note, size: 22, color: AppColors.green),
              const SizedBox(width: 8),
              _sectionTitle('Journaling & mood'),
            ],
          ),
          const SizedBox(height: 6),
          _bodyText(viewModel.correlationInsight),
          Space.verticalSpaceSmall(context),
          _MiniBars(
            values: [viewModel.journaledAvg, viewModel.otherAvg],
            labels: const ['Days you journal', 'Other days'],
            highlightIndex: 0,
            maxHeight: 74,
          ),
        ],
      ),
    );
  }
}

class _ConsistencyCard extends StatelessWidget {
  final MoodInsightsViewModel viewModel;
  const _ConsistencyCard({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Showing up'),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${viewModel.checkedInDays}',
                style: GoogleFonts.crimsonPro(
                  fontSize: 40,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  ' of the last 14 days',
                  style: GoogleFonts.crimsonPro(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryVeryDark,
                  ),
                ),
              ),
            ],
          ),
          Space.verticalSpaceTiny(context),
          // Forgiving dot row — filled where a check-in happened.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final on in viewModel.last14Checked)
                Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: on ? AppColors.secondary : Colors.transparent,
                    border: Border.all(
                      color: on
                          ? AppColors.secondary
                          : AppColors.secondaryVeryLight,
                      width: 1.5,
                    ),
                  ),
                ),
            ],
          ),
          Space.verticalSpaceTiny(context),
          _bodyText(viewModel.consistencyInsight),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final MoodInsightsViewModel viewModel;
  const _BalanceCard({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Your emotional balance'),
          // const SizedBox(height: 12),
          _StackedBalanceBar(viewModel: viewModel),
          const SizedBox(height: 12),
          Row(
            children: [
              _legend(AppColors.green, 'Brighter'),
              const SizedBox(width: 16),
              _legend(AppColors.secondaryVeryLight, 'Steady'),
              const SizedBox(width: 16),
              _legend(AppColors.peach, 'Heavier'),
            ],
          ),
          Space.verticalSpaceTiny(context),
          _bodyText(viewModel.balanceInsight),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.crimsonPro(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryVeryDark,
          ),
        ),
      ],
    );
  }
}

class _StackedBalanceBar extends StatelessWidget {
  final MoodInsightsViewModel viewModel;
  const _StackedBalanceBar({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    int flex(double f) => (f * 1000).round().clamp(0, 1000);
    final pos = flex(viewModel.positiveFraction);
    final neu = flex(viewModel.neutralFraction);
    final neg = flex(viewModel.negativeFraction);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 18,
        child: Row(
          children: [
            if (pos > 0)
              Expanded(
                  flex: pos, child: const ColoredBox(color: AppColors.green)),
            if (neu > 0)
              Expanded(
                  flex: neu,
                  child: const ColoredBox(color: AppColors.secondaryVeryLight)),
            if (neg > 0)
              Expanded(
                  flex: neg, child: const ColoredBox(color: AppColors.peach)),
          ],
        ),
      ),
    );
  }
}

class _ReflectionCard extends StatelessWidget {
  final MoodInsightsViewModel viewModel;
  const _ReflectionCard({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: AppColors.secondaryVeryLight.withAlpha(90),
        border: Border.all(color: AppColors.secondaryVeryLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_border,
                  size: 18, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text(
                'A gentle reflection',
                style: GoogleFonts.crimsonPro(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            viewModel.reflection,
            style: GoogleFonts.crimsonPro(
              fontSize: 16.5,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              AppConstants.empty,
              decoder: customDecoder,
              width: 180,
              height: 180,
            ),
            Space.verticalSpaceSmall(context),
            Text(
              'Your insights are just beginning',
              textAlign: TextAlign.center,
              style: GoogleFonts.crimsonPro(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Keep checking in with how you feel. As the days add up, gentle patterns will appear here — just for you.',
              textAlign: TextAlign.center,
              style: GoogleFonts.crimsonPro(
                fontSize: 16,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryVeryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
