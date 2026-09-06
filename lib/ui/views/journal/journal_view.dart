import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/animation_decoder.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/common/app_constants.dart';
import 'package:you_app/ui/shared/topbar.dart';
import 'package:you_app/ui/common/ui_helpers.dart';
import 'package:you_app/ui/views/journal/filter_bar.dart';
import 'package:you_app/ui/views/journal/journal_tabs/all_tab.dart';
import 'package:you_app/ui/views/journal/journal_tabs/personal_tab.dart';
import 'package:you_app/ui/views/journal/journal_tabs/work_tab.dart';
import 'journal_viewmodel.dart';

class JournalView extends StackedView<JournalViewModel> {
  const JournalView({super.key});

  @override
  Widget builder(
    BuildContext context,
    JournalViewModel viewModel,
    Widget? child,
  ) {
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TopBar(
                  leadingIconAsset: AppConstants.back, // Your 'Y' logo asset
                  onLeadingPressed: () {
                    Navigator.pop(context);
                  },
                  title: 'Journal',
                  iconColor: AppColors.primaryVeryDark,
                  trailingActions: [],
                ),
                // Modern collapsing scroll: the Prompt of the Day scrolls away,
                // the FilterBar pins to the top, and the entries scroll beneath.
                // LayoutBuilder gives us the viewport height so every tab — even
                // short ones like Work/Personal — is padded to a minimum height,
                // guaranteeing the prompt can always be scrolled away and the tab
                // bar pins consistently across all three tabs.
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final filterExtent =
                          MediaQuery.of(context).size.height * 0.07 + 12;
                      // Only the short tabs (Work / Personal) need a minimum
                      // height to stay scrollable. The All tab already has the
                      // tall composer card, so it keeps its natural layout.
                      final isAllTab = viewModel.currentIndex == 1;
                      final currentEntries = viewModel.currentIndex == 0
                          ? viewModel.workEntries
                          : (viewModel.currentIndex == 2
                              ? viewModel.personalEntries
                              : viewModel.allEntries);
                      // Empty Work/Personal: center the animation and place the
                      // upgrade button right beneath it (no large gap between).
                      final centeredEmpty = !isAllTab && currentEntries.isEmpty;
                      final tabMinHeight = (isAllTab || centeredEmpty)
                          ? 0.0
                          : (constraints.maxHeight - filterExtent)
                              .clamp(0.0, double.infinity);
                      return CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Column(
                              children: [
                                Space.verticalSpaceTiny(context),
                                _PromptOfTheDay(viewModel: viewModel),
                              ],
                            ),
                          ),
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _FilterBarHeaderDelegate(
                              extent: filterExtent,
                              currentIndex: viewModel.currentIndex,
                              onTap: viewModel.setTab,
                            ),
                          ),
                          if (centeredEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Lottie.asset(
                                    AppConstants.empty,
                                    decoder: customDecoder,
                                    width: 200,
                                    height: 200,
                                  ),
                                  if (viewModel.historyLimited) ...[
                                    Space.verticalSpaceTiny(context),
                                    _UnlockHistoryBanner(viewModel: viewModel),
                                  ],
                                ],
                              ),
                            )
                          else ...[
                            SliverToBoxAdapter(
                              child: ConstrainedBox(
                                constraints:
                                    BoxConstraints(minHeight: tabMinHeight),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  // Top-align so short tabs (Work/Personal) start
                                  // right under the pinned tab bar instead of
                                  // being centered in the tall min-height area.
                                  layoutBuilder:
                                      (currentChild, previousChildren) => Stack(
                                    alignment: Alignment.topCenter,
                                    children: [
                                      ...previousChildren,
                                      if (currentChild != null) currentChild,
                                    ],
                                  ),
                                  child: _buildTabContent(viewModel),
                                ),
                              ),
                            ),
                            if (viewModel.historyLimited)
                              SliverToBoxAdapter(
                                child:
                                    _UnlockHistoryBanner(viewModel: viewModel),
                              ),
                            SliverToBoxAdapter(
                              child: Space.verticalSpaceMedium(context),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            )));
  }

  Widget _buildTabContent(JournalViewModel viewModel) {
    switch (viewModel.currentIndex) {
      case 0:
        return WorkEntriesView(
            entries: viewModel.workEntries, key: ValueKey('work'));
      case 1:
        return AllEntriesView(
            entries: viewModel.allEntries, key: ValueKey('all'));
      case 2:
        return PersonalEntriesView(
            entries: viewModel.personalEntries, key: ValueKey('personal'));
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  JournalViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      JournalViewModel();

  @override
  void onViewModelReady(JournalViewModel viewModel) {
    // This is crucial to start fetching the data.
    viewModel.listenToJournalEntries();
  }
}

/// Pins the [FilterBar] to the top of the journal scroll. The strip is frosted
/// so entries blur gently as they scroll beneath the pinned tabs (modern glass).
class _FilterBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double extent;
  final int currentIndex;
  final Function(int) onTap;

  _FilterBarHeaderDelegate({
    required this.extent,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          alignment: Alignment.center,
          color: AppColors.background.withAlpha(overlapsContent ? 120 : 0),
          child: FilterBar(currentIndex: currentIndex, onTap: onTap),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _FilterBarHeaderDelegate oldDelegate) {
    return oldDelegate.currentIndex != currentIndex ||
        oldDelegate.extent != extent;
  }
}

/// Free-tier footer inviting the user to unlock their full journaling history.
/// Only shown when the visible entries are limited to the free window.
class _UnlockHistoryBanner extends StatelessWidget {
  final JournalViewModel viewModel;
  const _UnlockHistoryBanner({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: viewModel.onUnlockHistory,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_open_rounded,
                color: AppColors.secondary, size: 20),
            Space.horizontalSpaceSmall(context),
            Expanded(
              child: Text(
                'Showing your last ${viewModel.historyWindowDays} days. '
                'Unlock voice journalling and your full history with YOU+.',
                style: GoogleFonts.crimsonPro(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.secondary),
          ],
        ),
      ),
    );
  }
}

/// A gentle "Prompt of the Day" card. Shows the admin-scheduled prompt for today
/// (live), falling back to the viewmodel's default so it's never empty. Tapping
/// it opens a new entry.
class _PromptOfTheDay extends StatelessWidget {
  final JournalViewModel viewModel;
  const _PromptOfTheDay({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: viewModel.promptOfTheDay,
      builder: (context, snapshot) {
        final prompt = (snapshot.data?.trim().isNotEmpty ?? false)
            ? snapshot.data!.trim()
            : viewModel.defaultPrompt;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: viewModel.navigateToNewJournalEntry,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withAlpha(235),
                      AppColors.secondaryVeryLight.withAlpha(90),
                    ],
                  ),
                  border: Border.all(
                      color: AppColors.primaryVeryDark.withAlpha(20), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryVeryDark.withAlpha(18),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            size: 16, color: AppColors.secondary),
                        const SizedBox(width: 6),
                        Text(
                          'Prompt of the Day',
                          style: GoogleFonts.crimsonPro(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      prompt,
                      style: GoogleFonts.crimsonPro(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                        color: AppColors.primaryVeryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
