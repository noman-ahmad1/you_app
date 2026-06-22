import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
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
  const JournalView({Key? key}) : super(key: key);

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
                Space.verticalSpaceTiny(context),
                _PromptOfTheDay(viewModel: viewModel),
                FilterBar(
                    currentIndex: viewModel.currentIndex,
                    onTap: (viewModel.setTab)),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildTabContent(viewModel),
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
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                          style: GoogleFonts.inter(
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
