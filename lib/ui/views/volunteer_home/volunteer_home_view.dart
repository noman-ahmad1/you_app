import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/views/home/bottom_bar.dart';
import 'package:you_app/ui/views/volunteer_home/tabs/volunteer_home.dart';
import 'package:you_app/ui/views/volunteer_home/tabs/request.dart';
import 'package:you_app/ui/views/volunteer_home/tabs/dashboard.dart';
import 'package:you_app/ui/views/volunteer_home/volunteer_bottom_bar.dart';

import 'volunteer_home_viewmodel.dart';

class VolunteerHomeView extends StackedView<VolunteerHomeViewModel> {
  const VolunteerHomeView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    VolunteerHomeViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Screens
          _buildTabNavigator(0, viewModel),
          _buildTabNavigator(1, viewModel),
          _buildTabNavigator(2, viewModel),

          // Floating Bottom Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: FractionallySizedBox(
                widthFactor: 0.9, // 90% of screen width
                heightFactor: 0.07,
                child: VolunteerBottomBar(
                  currentIndex: viewModel.currentIndex,
                  onTap: viewModel.setTab,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  VolunteerHomeViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      VolunteerHomeViewModel();
  Widget _buildTabNavigator(int index, VolunteerHomeViewModel viewModel) {
    return Offstage(
      offstage: viewModel.currentIndex != index,
      child: Navigator(
        key: viewModel.navigatorKeys[index],
        onGenerateRoute: (settings) {
          switch (index) {
            case 0:
              return MaterialPageRoute(builder: (_) => const RequestScreen());
            case 1:
              return MaterialPageRoute(builder: (_) => const VolunteerHome());
            case 2:
              return MaterialPageRoute(builder: (_) => const DashboardScreen());
            default:
              throw Exception('Invalid tab');
          }
        },
      ),
    );
  }
}
