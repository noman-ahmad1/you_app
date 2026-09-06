import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/common/app_colors.dart';
import 'package:you_app/ui/shared/widgets.dart';
import 'startup_viewmodel.dart';
import "package:you_app/ui/shared/custom_lottie_loader.dart";

class StartupView extends StackedView<StartupViewModel> {
  const StartupView({super.key});

  @override
  Widget builder(
    BuildContext context,
    StartupViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [const CustomLottieLoader()],
        ),
      ),
    );
  }

  @override
  StartupViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      StartupViewModel();

  @override
  void onViewModelReady(StartupViewModel viewModel) => SchedulerBinding.instance
      .addPostFrameCallback((timeStamp) => viewModel.runStartupLogic());
}
