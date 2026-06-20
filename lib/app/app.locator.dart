// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// StackedLocatorGenerator
// **************************************************************************

// ignore_for_file: public_member_api_docs, implementation_imports, depend_on_referenced_packages

import 'package:stacked_services/src/bottom_sheet/bottom_sheet_service.dart';
import 'package:stacked_services/src/dialog/dialog_service.dart';
import 'package:stacked_services/src/navigation/navigation_service.dart';
import 'package:stacked_services/src/snackbar/snackbar_service.dart';
import 'package:stacked_shared/stacked_shared.dart';

import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/block_service.dart';
import '../services/chat_request_service.dart';
import '../services/chat_service.dart';
import '../services/chatbot_service.dart';
import '../services/community_service.dart';
import '../services/country_code_service.dart';
import '../services/journal_service.dart';
import '../services/moderation_flag_service.dart';
import '../services/moderation_service.dart';
import '../services/monetization_service.dart';
import '../services/mood_service.dart';
import '../services/push_notification_service.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';
import '../services/volunteer_service.dart';
import '../ui/views/volunteer_signup/volunteer_signup_viewmodel.dart';

final locator = StackedLocator.instance;

Future<void> setupLocator(
    {String? environment, EnvironmentFilter? environmentFilter}) async {
// Register environments
  locator.registerEnvironment(
      environment: environment, environmentFilter: environmentFilter);

// Register dependencies
  locator.registerLazySingleton(() => BottomSheetService());
  locator.registerLazySingleton(() => DialogService());
  locator.registerLazySingleton(() => SnackbarService());
  locator.registerLazySingleton(() => NavigationService());
  locator.registerLazySingleton(() => AuthenticationService());
  locator.registerLazySingleton(() => CountryService());
  locator.registerLazySingleton(() => UserService());
  locator.registerLazySingleton(() => VolunteerService());
  locator.registerLazySingleton(() => MoodService());
  locator.registerLazySingleton(() => JournalService());
  locator.registerLazySingleton(() => ChatService());
  locator.registerLazySingleton(() => ChatRequestService());
  locator.registerLazySingleton(() => CommunityService());
  locator.registerLazySingleton(() => ChatbotService());
  locator.registerLazySingleton(() => PushNotificationService());
  locator.registerLazySingleton(() => StorageService());
  locator.registerLazySingleton(() => MonetizationService());
  locator.registerLazySingleton(() => AnalyticsService());
  locator.registerLazySingleton(() => ModerationService());
  locator.registerLazySingleton(() => ModerationFlagService());
  locator.registerLazySingleton(() => BlockService());
  locator.registerLazySingleton(() => VolunteerSignupViewModel());
}
