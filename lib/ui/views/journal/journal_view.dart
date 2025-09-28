import 'package:flutter/material.dart';
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

class JournalView extends StackedView<VolunteerSignupInfoViewModel> {
  const JournalView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    VolunteerSignupInfoViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
        appBar: TopBar(
          title: 'Journal',
          imageAssetPath: AppConstants.back,
          color: AppColors.secondary,
          onBackPressed: () {
            viewModel.back();
          },
        ),
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
                Space.verticalSpaceTiny(context),
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

  Widget _buildTabContent(VolunteerSignupInfoViewModel viewModel) {
    switch (viewModel.currentIndex) {
      case 0:
        return WorkEntriesView(viewModel: viewModel, key: ValueKey('work'));
      case 1:
        return AllEntriesView(viewModel: viewModel, key: ValueKey('all'));
      case 2:
        return PersonalEntriesView(
            viewModel: viewModel, key: ValueKey('personal'));
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  VolunteerSignupInfoViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      VolunteerSignupInfoViewModel();
}
