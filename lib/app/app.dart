import 'package:you_app/ui/bottom_sheets/notice/notice_sheet.dart';
import 'package:you_app/ui/dialogs/info_alert/info_alert_dialog.dart';
import 'package:you_app/ui/views/home/home_view.dart';
import 'package:you_app/ui/views/startup/startup_view.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/ui/views/welcome/welcome_view.dart';
import 'package:you_app/ui/views/login/login_view.dart';
import 'package:you_app/ui/views/signup/signup_view.dart';
import 'package:you_app/ui/views/reset_password/reset_password_view.dart';
import 'package:you_app/ui/views/user_info/user_info_view.dart';
// @stacked-import

@StackedApp(
  routes: [
    MaterialRoute(page: HomeView),
    MaterialRoute(page: StartupView),
    MaterialRoute(page: WelcomeView),
    MaterialRoute(page: LoginView),
    MaterialRoute(page: SignupView),
    MaterialRoute(page: ResetPasswordView),
    MaterialRoute(page: UserInfoView),
// @stacked-route
  ],
  dependencies: [
    LazySingleton(classType: BottomSheetService),
    LazySingleton(classType: DialogService),
    LazySingleton(classType: NavigationService),
    // @stacked-service
  ],
  bottomsheets: [
    StackedBottomsheet(classType: NoticeSheet),
    // @stacked-bottom-sheet
  ],
  dialogs: [
    StackedDialog(classType: InfoAlertDialog),
    // @stacked-dialog
  ],
)
class App {}
