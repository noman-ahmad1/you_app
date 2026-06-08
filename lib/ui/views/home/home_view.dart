import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:stacked/stacked.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:you_app/ui/views/home/widgets/bottom_bar.dart';
import 'package:you_app/ui/views/home/home_viewmodel.dart';
import 'package:you_app/ui/views/home/widgets/home_drawer.dart';
import 'package:you_app/ui/views/home/widgets/notifications_drawer.dart';
import 'package:you_app/ui/views/home/tabs/communities.dart';
import 'package:you_app/ui/views/home/tabs/home_screen.dart';
import 'package:you_app/ui/views/home/tabs/volunteers.dart';

class HomeView extends StackedView<HomeViewModel> {
  final int initialIndex;
  const HomeView({Key? key, this.initialIndex = 1}) : super(key: key);

  @override
  void onViewModelReady(HomeViewModel viewModel) {
    viewModel.currentIndex = initialIndex;
    super.onViewModelReady(viewModel);
  }

  @override
  Widget builder(
    BuildContext context,
    HomeViewModel viewModel,
    Widget? child,
  ) {
    return ShowCaseWidget(
      builder: (context) {
        viewModel.checkAndStartShowcase(context);
        return Scaffold(
          backgroundColor: Colors.white,
          drawer: const NotificationsDrawer(),
          endDrawer: HomeDrawer(viewModel: viewModel),
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
      },
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
