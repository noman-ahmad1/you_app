import 'package:flutter/widgets.dart';
import 'package:you_app/app/app.bottomsheets.dart';
import 'package:you_app/app/app.dialogs.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/ui/common/app_strings.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class HomeViewModel extends BaseViewModel {
  final _dialogService = locator<DialogService>();
  final _bottomSheetService = locator<BottomSheetService>();

  String get counterLabel => 'Counter is: $_counter';

  int _counter = 0;
  int currentIndex = 0;

  void incrementCounter() {
    _counter++;
    rebuildUi();
  }

  void showDialog() {
    _dialogService.showCustomDialog(
      variant: DialogType.infoAlert,
      title: 'Stacked Rocks!',
      description: 'Give stacked $_counter stars on Github',
    );
  }

  void showBottomSheet() {
    _bottomSheetService.showCustomSheet(
      variant: BottomSheetType.notice,
      title: ksHomeBottomSheetTitle,
      description: ksHomeBottomSheetDescription,
    );
  }
  
  final List<GlobalKey<NavigatorState>> navigatorKeys = [
    GlobalKey<NavigatorState>(), // Home
    GlobalKey<NavigatorState>(), // Community
    GlobalKey<NavigatorState>(), // Chat
  ];

  void setTab(int index) {
    if (index == currentIndex) {
      navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      currentIndex = index;
      notifyListeners();
    }
  }
}
