import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/country_code_service.dart';
import 'package:you_app/services/firestore_service.dart';
import 'package:you_app/ui/bottom_sheets/notice/notice_sheet.dart';
import 'package:you_app/ui/dialogs/info_alert/info_alert_dialog.dart';
import 'package:you_app/ui/views/home/home_view.dart';
import 'package:you_app/ui/views/startup/startup_view.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/ui/views/volunteer_signup/volunteer_otp.dart';
import 'package:you_app/ui/views/volunteer_signup/volunteer_signup_viewmodel.dart';
import 'package:you_app/ui/views/welcome/welcome_view.dart';
import 'package:you_app/ui/views/login/login_view.dart';
import 'package:you_app/ui/views/signup/signup_view.dart';
import 'package:you_app/ui/views/reset_password/reset_password_view.dart';
import 'package:you_app/ui/views/user_info/user_info_view.dart';
import 'package:you_app/ui/views/journal/journal_view.dart';
import 'package:you_app/ui/views/mood_tracker/mood_tracker_view.dart';
import 'package:you_app/ui/views/new_journal_entry/new_journal_entry_view.dart';
import 'package:you_app/ui/views/chatbot/chatbot_view.dart';
import 'package:you_app/ui/views/volunteer_signup/volunteer_signup_view.dart';
import 'package:you_app/ui/views/volunteer_signup_info/volunteer_signup_info_view.dart';
import 'package:you_app/ui/views/volunteer_home/volunteer_home_view.dart';
import 'package:you_app/ui/views/volunteer_login/volunteer_login_view.dart';
import 'package:you_app/ui/views/volunteer_reset_password/volunteer_reset_password_view.dart';
import 'package:you_app/ui/views/journal_details/journal_details_view.dart';
import 'package:you_app/ui/views/chat/chat_view.dart';
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
    MaterialRoute(page: JournalView),
    MaterialRoute(page: MoodTrackerView),
    MaterialRoute(page: NewJournalEntryView),
    MaterialRoute(page: ChatbotView),
    MaterialRoute(page: VolunteerSignupView),
    MaterialRoute(page: VolunteerSignupInfoView),
    MaterialRoute(page: VolunteerHomeView),
    MaterialRoute(page: VolunteerLoginView),
    MaterialRoute(page: VolunteerResetPasswordView),
    MaterialRoute(page: VolunteerOtpView),
    MaterialRoute(page: JournalDetailsView),
    MaterialRoute(page: ChatView),
// @stacked-route
  ],
  dependencies: [
    LazySingleton(classType: BottomSheetService),
    LazySingleton(classType: DialogService),
    LazySingleton(classType: NavigationService),
    LazySingleton(classType: AuthenticationService),
    LazySingleton(classType: CountryService),
    LazySingleton(classType: FirestoreService),
    // @stacked-service

    LazySingleton(classType: VolunteerSignupViewModel),
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
