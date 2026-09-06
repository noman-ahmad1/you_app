import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/services/app_content_service.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/billing_service.dart';
import 'package:you_app/services/block_service.dart';
import 'package:you_app/services/country_code_service.dart';
import 'package:you_app/services/escalation_service.dart';
import 'package:you_app/services/moderation_flag_service.dart';
import 'package:you_app/services/moderation_service.dart';
import 'package:you_app/services/user_service.dart';
import 'package:you_app/services/volunteer_service.dart';
import 'package:you_app/services/mood_service.dart';
import 'package:you_app/services/journal_service.dart';
import 'package:you_app/services/chat_service.dart';
import 'package:you_app/services/chat_request_service.dart';
import 'package:you_app/services/community_service.dart';
import 'package:you_app/services/chatbot_service.dart';
import 'package:you_app/services/presence_service.dart';
import 'package:you_app/services/push_notification_service.dart';
import 'package:you_app/services/security_log_service.dart';
import 'package:you_app/services/sound_service.dart';
import 'package:you_app/services/storage_service.dart';
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
import 'package:you_app/ui/views/volunteer_reset_password/volunteer_reset_password_view.dart';
import 'package:you_app/ui/views/journal_details/journal_details_view.dart';
import 'package:you_app/ui/views/chat/chat_view.dart';
import 'package:you_app/ui/views/community_chat/community_chat_view.dart';
import 'package:you_app/ui/views/volunteer_pending_verification/volunteer_pending_verification_view.dart';
import 'package:you_app/ui/views/profile/profile_view.dart';
import 'package:you_app/ui/views/edit_profile/edit_profile_view.dart';
import 'package:you_app/ui/views/volunteer_edit_profile/volunteer_edit_profile_view.dart';
import 'package:you_app/ui/views/soothing_sounds/soothing_sounds_view.dart';
import 'package:you_app/ui/views/breathe/breathe_view.dart';
import 'package:you_app/ui/views/paywall/paywall_view.dart';
import 'package:you_app/ui/views/premium/premium_view.dart';
import 'package:you_app/ui/views/mood_insights/mood_insights_view.dart';
import 'package:you_app/ui/views/verify_email/verify_email_view.dart';
import 'package:you_app/ui/shared/page_transitions.dart';
// @stacked-import
import 'package:you_app/services/monetization_service.dart';

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
    CustomRoute(page: MoodTrackerView, transitionsBuilder: scaleFadeTransition),
    MaterialRoute(page: NewJournalEntryView),
    CustomRoute(page: ChatbotView, transitionsBuilder: slideUpTransition),
    MaterialRoute(page: VolunteerSignupView),
    MaterialRoute(page: VolunteerSignupInfoView),
    MaterialRoute(page: VolunteerHomeView),
    MaterialRoute(page: VolunteerResetPasswordView),
    MaterialRoute(page: VolunteerOtpView),
    MaterialRoute(page: JournalDetailsView),
    CustomRoute(page: ChatView, transitionsBuilder: slideUpTransition),
    CustomRoute(page: CommunityChatView, transitionsBuilder: slideUpTransition),
    MaterialRoute(page: VolunteerPendingVerificationView),
    MaterialRoute(page: ProfileView),
    MaterialRoute(page: EditProfileView),
    MaterialRoute(page: SoothingSoundsView),
    CustomRoute(page: BreatheView, transitionsBuilder: fadeTransition),
    MaterialRoute(page: VolunteerEditProfileView),
    CustomRoute(page: PaywallView, transitionsBuilder: slideUpTransition),
    CustomRoute(page: PremiumView, transitionsBuilder: slideUpTransition),
    CustomRoute(page: MoodInsightsView, transitionsBuilder: slideUpTransition),
    CustomRoute(page: VerifyEmailView, transitionsBuilder: slideUpTransition),
// @stacked-route
  ],
  dependencies: [
    LazySingleton(classType: BottomSheetService),
    LazySingleton(classType: DialogService),
    LazySingleton(classType: SnackbarService),
    LazySingleton(classType: NavigationService),
    LazySingleton(classType: AuthenticationService),
    LazySingleton(classType: CountryService),
    LazySingleton(classType: UserService),
    LazySingleton(classType: VolunteerService),
    LazySingleton(classType: MoodService),
    LazySingleton(classType: JournalService),
    LazySingleton(classType: ChatService),
    LazySingleton(classType: ChatRequestService),
    LazySingleton(classType: CommunityService),
    LazySingleton(classType: ChatbotService),
    LazySingleton(classType: PushNotificationService),
    LazySingleton(classType: StorageService),
    // @stacked-service
    LazySingleton(classType: MonetizationService),
    LazySingleton(classType: BillingService),
    LazySingleton(classType: AnalyticsService),
    LazySingleton(classType: ModerationService),
    LazySingleton(classType: ModerationFlagService),
    LazySingleton(classType: EscalationService),
    LazySingleton(classType: AppContentService),
    LazySingleton(classType: SoundService),
    LazySingleton(classType: PresenceService),
    LazySingleton(classType: BlockService),
    LazySingleton(classType: SecurityLogService),

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
