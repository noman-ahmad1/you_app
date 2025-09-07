import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:stacked/stacked.dart';
import 'package:you_app/ui/views/home/bottom_bar.dart';
import 'package:you_app/ui/views/home/home_viewmodel.dart';
import 'package:you_app/ui/views/home/tabs/communities.dart';
import 'package:you_app/ui/views/home/tabs/home_screen.dart';
import 'package:you_app/ui/views/home/tabs/volunteers.dart';

class HomeView extends StackedView<HomeViewModel> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    HomeViewModel viewModel,
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
                child: BottomBar(
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
  HomeViewModel viewModelBuilder(BuildContext context) => HomeViewModel();

  Widget _buildTabNavigator(int index, HomeViewModel viewModel) {
    return Offstage(
      offstage: viewModel.currentIndex != index,
      child: Navigator(
        key: viewModel.navigatorKeys[index],
        onGenerateRoute: (settings) {
          switch (index) {
            case 0:
              return MaterialPageRoute(
                  builder: (_) => const CommunitiesScreen());
            case 1:
              return MaterialPageRoute(builder: (_) => const HomeScreen());
            case 2:
              return MaterialPageRoute(
                  builder: (_) => const VolunteersScreen());
            default:
              throw Exception('Invalid tab');
          }
        },
      ),
    );
  }
}
