// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// StackedNavigatorGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter/material.dart' as _i21;
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart' as _i1;
import 'package:stacked_services/stacked_services.dart' as _i23;
import 'package:you_app/models/journal_model.dart' as _i22;
import 'package:you_app/ui/views/chat/chat_view.dart' as _i20;
import 'package:you_app/ui/views/chatbot/chatbot_view.dart' as _i12;
import 'package:you_app/ui/views/home/home_view.dart' as _i2;
import 'package:you_app/ui/views/journal/journal_view.dart' as _i9;
import 'package:you_app/ui/views/journal_details/journal_details_view.dart'
    as _i19;
import 'package:you_app/ui/views/login/login_view.dart' as _i5;
import 'package:you_app/ui/views/mood_tracker/mood_tracker_view.dart' as _i10;
import 'package:you_app/ui/views/new_journal_entry/new_journal_entry_view.dart'
    as _i11;
import 'package:you_app/ui/views/reset_password/reset_password_view.dart'
    as _i7;
import 'package:you_app/ui/views/signup/signup_view.dart' as _i6;
import 'package:you_app/ui/views/startup/startup_view.dart' as _i3;
import 'package:you_app/ui/views/user_info/user_info_view.dart' as _i8;
import 'package:you_app/ui/views/volunteer_home/volunteer_home_view.dart'
    as _i15;
import 'package:you_app/ui/views/volunteer_login/volunteer_login_view.dart'
    as _i16;
import 'package:you_app/ui/views/volunteer_reset_password/volunteer_reset_password_view.dart'
    as _i17;
import 'package:you_app/ui/views/volunteer_signup/volunteer_otp.dart' as _i18;
import 'package:you_app/ui/views/volunteer_signup/volunteer_signup_view.dart'
    as _i13;
import 'package:you_app/ui/views/volunteer_signup_info/volunteer_signup_info_view.dart'
    as _i14;
import 'package:you_app/ui/views/welcome/welcome_view.dart' as _i4;

class Routes {
  static const homeView = '/home-view';

  static const startupView = '/startup-view';

  static const welcomeView = '/welcome-view';

  static const loginView = '/login-view';

  static const signupView = '/signup-view';

  static const resetPasswordView = '/reset-password-view';

  static const userInfoView = '/user-info-view';

  static const journalView = '/journal-view';

  static const moodTrackerView = '/mood-tracker-view';

  static const newJournalEntryView = '/new-journal-entry-view';

  static const chatbotView = '/chatbot-view';

  static const volunteerSignupView = '/volunteer-signup-view';

  static const volunteerSignupInfoView = '/volunteer-signup-info-view';

  static const volunteerHomeView = '/volunteer-home-view';

  static const volunteerLoginView = '/volunteer-login-view';

  static const volunteerResetPasswordView = '/volunteer-reset-password-view';

  static const volunteerOtpView = '/volunteer-otp-view';

  static const journalDetailsView = '/journal-details-view';

  static const chatView = '/chat-view';

  static const all = <String>{
    homeView,
    startupView,
    welcomeView,
    loginView,
    signupView,
    resetPasswordView,
    userInfoView,
    journalView,
    moodTrackerView,
    newJournalEntryView,
    chatbotView,
    volunteerSignupView,
    volunteerSignupInfoView,
    volunteerHomeView,
    volunteerLoginView,
    volunteerResetPasswordView,
    volunteerOtpView,
    journalDetailsView,
    chatView,
  };
}

class StackedRouter extends _i1.RouterBase {
  final _routes = <_i1.RouteDef>[
    _i1.RouteDef(Routes.homeView, page: _i2.HomeView),
    _i1.RouteDef(Routes.startupView, page: _i3.StartupView),
    _i1.RouteDef(Routes.welcomeView, page: _i4.WelcomeView),
    _i1.RouteDef(Routes.loginView, page: _i5.LoginView),
    _i1.RouteDef(Routes.signupView, page: _i6.SignupView),
    _i1.RouteDef(Routes.resetPasswordView, page: _i7.ResetPasswordView),
    _i1.RouteDef(Routes.userInfoView, page: _i8.UserInfoView),
    _i1.RouteDef(Routes.journalView, page: _i9.JournalView),
    _i1.RouteDef(Routes.moodTrackerView, page: _i10.MoodTrackerView),
    _i1.RouteDef(Routes.newJournalEntryView, page: _i11.NewJournalEntryView),
    _i1.RouteDef(Routes.chatbotView, page: _i12.ChatbotView),
    _i1.RouteDef(Routes.volunteerSignupView, page: _i13.VolunteerSignupView),
    _i1.RouteDef(
      Routes.volunteerSignupInfoView,
      page: _i14.VolunteerSignupInfoView,
    ),
    _i1.RouteDef(Routes.volunteerHomeView, page: _i15.VolunteerHomeView),
    _i1.RouteDef(Routes.volunteerLoginView, page: _i16.VolunteerLoginView),
    _i1.RouteDef(
      Routes.volunteerResetPasswordView,
      page: _i17.VolunteerResetPasswordView,
    ),
    _i1.RouteDef(Routes.volunteerOtpView, page: _i18.VolunteerOtpView),
    _i1.RouteDef(Routes.journalDetailsView, page: _i19.JournalDetailsView),
    _i1.RouteDef(Routes.chatView, page: _i20.ChatView),
  ];

  final _pagesMap = <Type, _i1.StackedRouteFactory>{
    _i2.HomeView: (data) {
      final args = data.getArgs<HomeViewArguments>(
        orElse: () => const HomeViewArguments(),
      );
      return _i21.MaterialPageRoute<dynamic>(
        builder: (context) => _i2.HomeView(key: args.key),
        settings: data,
      );
    },
    _i3.StartupView: (data) {
      final args = data.getArgs<StartupViewArguments>(
        orElse: () => const StartupViewArguments(),
      );
      return _i21.MaterialPageRoute<dynamic>(
        builder: (context) => _i3.StartupView(key: args.key),
        settings: data,
      );
    },
    _i4.WelcomeView: (data) {
      final args = data.getArgs<WelcomeViewArguments>(
        orElse: () => const WelcomeViewArguments(),
      );
      return _i21.MaterialPageRoute<dynamic>(
        builder: (context) => _i4.WelcomeView(key: args.key),
        settings: data,
      );
    },
    _i5.LoginView: (data) {
      final args = data.getArgs<LoginViewArguments>(
        orElse: () => const LoginViewArguments(),
      );
      return _i21.MaterialPageRoute<dynamic>(
        builder: (context) => _i5.LoginView(key: args.key),
        settings: data,
      );
    },
    _i6.SignupView: (data) {
      final args = data.getArgs<SignupViewArguments>(
        orElse: () => const SignupViewArguments(),
      );
      return _i21.MaterialPageRoute<dynamic>(
        builder: (context) => _i6.SignupView(key: args.key),
        settings: data,
      );
    },
    _i7.ResetPasswordView: (data) {
      final args = data.getArgs<ResetPasswordViewArguments>(
        orElse: () => const ResetPasswordViewArguments(),
      );
      return _i21.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i7.ResetPasswordView(key: args.key, oobCode: args.oobCode),
        settings: data,
      );
    },
    _i8.UserInfoView: (data) {
      final args = data.getArgs<UserInfoViewArguments>(nullOk: false);
      return _i21.MaterialPageRoute<dynamic>(
        builder: (context) => _i8.UserInfoView(key: args.key, uid: args.uid),
        settings: data,
      );
    },
    _i9.JournalView: (data) {
      final args = data.getArgs<JournalViewArguments>(
        orElse: () => const JournalViewArguments(),
      );
      return _i21.MaterialPageRoute<dynamic>(
        builder: (context) => _i9.JournalView(key: args.key),
        settings: data,
      );
    },
    _i10.MoodTrackerView: (data) {
      final args = data.getArgs<MoodTrackerViewArguments>(
        orElse: () => const MoodTrackerViewArguments(),
      );
      return _i21.MaterialPageRoute<dynamic>(
        builder: (context) => _i10.MoodTrackerView(key: args.key),
        settings: data,
      );
    },
    _i11.NewJournalEntryView: (data) {
      final args = data.getArgs<NewJournalEntryViewArguments>(
        orElse: () => const NewJournalEntryViewArguments(),
      );
      return _i21.MaterialPageRoute<dynamic>(
        builder: (context) => _i11.NewJournalEntryView(
          key: args.key,
          journalEntry: args.journalEntry,
        ),
        settings: data,
      );
    },
    _i12.ChatbotView: (data) {
      final args = data.getArgs<ChatbotViewArguments>(
        orElse: () => const ChatbotViewArguments(),
      );
      return _i21.MaterialPageRoute<dynamic>(
        builder: (context) => _i12.ChatbotView(key: args.key),
        settings: data,
      );
    },
    _i13.VolunteerSignupView: (data) {
      final args = data.getArgs<VolunteerSignupViewArguments>(
        orElse: () => const VolunteerSignupViewArguments(),
      );
      return _i21.MaterialPageRoute<dynamic>(
        builder: (context) => _i13.VolunteerSignupView(key: args.key),
        settings: data,
      );
    },
    _i14.VolunteerSignupInfoView: (data) {
      final args = data.getArgs<VolunteerSignupInfoViewArguments>(
        nullOk: false,
      );
      return _i21.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i14.VolunteerSignupInfoView(key: args.key, uid: args.uid),
        settings: data,
      );
    },
    _i15.VolunteerHomeView: (data) {
      final args = data.getArgs<VolunteerHomeViewArguments>(
        orElse: () => const VolunteerHomeViewArguments(),
      );
      return _i21.MaterialPageRoute<dynamic>(
        builder: (context) => _i15.VolunteerHomeView(key: args.key),
        settings: data,
      );
    },
    _i16.VolunteerLoginView: (data) {
      final args = data.getArgs<VolunteerLoginViewArguments>(
        orElse: () => const VolunteerLoginViewArguments(),
      );
      return _i21.MaterialPageRoute<dynamic>(
        builder: (context) => _i16.VolunteerLoginView(key: args.key),
        settings: data,
      );
    },
    _i17.VolunteerResetPasswordView: (data) {
      final args = data.getArgs<VolunteerResetPasswordViewArguments>(
        orElse: () => const VolunteerResetPasswordViewArguments(),
      );
      return _i21.MaterialPageRoute<dynamic>(
        builder: (context) => _i17.VolunteerResetPasswordView(
          key: args.key,
          oobCode: args.oobCode,
        ),
        settings: data,
      );
    },
    _i18.VolunteerOtpView: (data) {
      final args = data.getArgs<VolunteerOtpViewArguments>(
        orElse: () => const VolunteerOtpViewArguments(),
      );
      return _i21.MaterialPageRoute<dynamic>(
        builder: (context) => _i18.VolunteerOtpView(key: args.key),
        settings: data,
      );
    },
    _i19.JournalDetailsView: (data) {
      final args = data.getArgs<JournalDetailsViewArguments>(nullOk: false);
      return _i21.MaterialPageRoute<dynamic>(
        builder: (context) => _i19.JournalDetailsView(
          key: args.key,
          journalEntry: args.journalEntry,
        ),
        settings: data,
      );
    },
    _i20.ChatView: (data) {
      final args = data.getArgs<ChatViewArguments>(nullOk: false);
      return _i21.MaterialPageRoute<dynamic>(
        builder: (context) => _i20.ChatView(
          key: args.key,
          volunteerId: args.volunteerId,
          volunteerName: args.volunteerName,
          requestId: args.requestId,
        ),
        settings: data,
      );
    },
  };

  @override
  List<_i1.RouteDef> get routes => _routes;

  @override
  Map<Type, _i1.StackedRouteFactory> get pagesMap => _pagesMap;
}

class HomeViewArguments {
  const HomeViewArguments({this.key});

  final _i21.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant HomeViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class StartupViewArguments {
  const StartupViewArguments({this.key});

  final _i21.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant StartupViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class WelcomeViewArguments {
  const WelcomeViewArguments({this.key});

  final _i21.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant WelcomeViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class LoginViewArguments {
  const LoginViewArguments({this.key});

  final _i21.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant LoginViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class SignupViewArguments {
  const SignupViewArguments({this.key});

  final _i21.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant SignupViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class ResetPasswordViewArguments {
  const ResetPasswordViewArguments({this.key, this.oobCode});

  final _i21.Key? key;

  final String? oobCode;

  @override
  String toString() {
    return '{"key": "$key", "oobCode": "$oobCode"}';
  }

  @override
  bool operator ==(covariant ResetPasswordViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.oobCode == oobCode;
  }

  @override
  int get hashCode {
    return key.hashCode ^ oobCode.hashCode;
  }
}

class UserInfoViewArguments {
  const UserInfoViewArguments({this.key, required this.uid});

  final _i21.Key? key;

  final String uid;

  @override
  String toString() {
    return '{"key": "$key", "uid": "$uid"}';
  }

  @override
  bool operator ==(covariant UserInfoViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.uid == uid;
  }

  @override
  int get hashCode {
    return key.hashCode ^ uid.hashCode;
  }
}

class JournalViewArguments {
  const JournalViewArguments({this.key});

  final _i21.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant JournalViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class MoodTrackerViewArguments {
  const MoodTrackerViewArguments({this.key});

  final _i21.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant MoodTrackerViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class NewJournalEntryViewArguments {
  const NewJournalEntryViewArguments({this.key, this.journalEntry});

  final _i21.Key? key;

  final _i22.JournalEntry? journalEntry;

  @override
  String toString() {
    return '{"key": "$key", "journalEntry": "$journalEntry"}';
  }

  @override
  bool operator ==(covariant NewJournalEntryViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.journalEntry == journalEntry;
  }

  @override
  int get hashCode {
    return key.hashCode ^ journalEntry.hashCode;
  }
}

class ChatbotViewArguments {
  const ChatbotViewArguments({this.key});

  final _i21.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant ChatbotViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class VolunteerSignupViewArguments {
  const VolunteerSignupViewArguments({this.key});

  final _i21.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant VolunteerSignupViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class VolunteerSignupInfoViewArguments {
  const VolunteerSignupInfoViewArguments({this.key, required this.uid});

  final _i21.Key? key;

  final String uid;

  @override
  String toString() {
    return '{"key": "$key", "uid": "$uid"}';
  }

  @override
  bool operator ==(covariant VolunteerSignupInfoViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.uid == uid;
  }

  @override
  int get hashCode {
    return key.hashCode ^ uid.hashCode;
  }
}

class VolunteerHomeViewArguments {
  const VolunteerHomeViewArguments({this.key});

  final _i21.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant VolunteerHomeViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class VolunteerLoginViewArguments {
  const VolunteerLoginViewArguments({this.key});

  final _i21.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant VolunteerLoginViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class VolunteerResetPasswordViewArguments {
  const VolunteerResetPasswordViewArguments({this.key, this.oobCode});

  final _i21.Key? key;

  final String? oobCode;

  @override
  String toString() {
    return '{"key": "$key", "oobCode": "$oobCode"}';
  }

  @override
  bool operator ==(covariant VolunteerResetPasswordViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.oobCode == oobCode;
  }

  @override
  int get hashCode {
    return key.hashCode ^ oobCode.hashCode;
  }
}

class VolunteerOtpViewArguments {
  const VolunteerOtpViewArguments({this.key});

  final _i21.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant VolunteerOtpViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class JournalDetailsViewArguments {
  const JournalDetailsViewArguments({this.key, required this.journalEntry});

  final _i21.Key? key;

  final _i22.JournalEntry journalEntry;

  @override
  String toString() {
    return '{"key": "$key", "journalEntry": "$journalEntry"}';
  }

  @override
  bool operator ==(covariant JournalDetailsViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.journalEntry == journalEntry;
  }

  @override
  int get hashCode {
    return key.hashCode ^ journalEntry.hashCode;
  }
}

class ChatViewArguments {
  const ChatViewArguments({
    this.key,
    required this.volunteerId,
    required this.volunteerName,
    required this.requestId,
  });

  final _i21.Key? key;

  final String volunteerId;

  final String volunteerName;

  final String requestId;

  @override
  String toString() {
    return '{"key": "$key", "volunteerId": "$volunteerId", "volunteerName": "$volunteerName", "requestId": "$requestId"}';
  }

  @override
  bool operator ==(covariant ChatViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key &&
        other.volunteerId == volunteerId &&
        other.volunteerName == volunteerName &&
        other.requestId == requestId;
  }

  @override
  int get hashCode {
    return key.hashCode ^
        volunteerId.hashCode ^
        volunteerName.hashCode ^
        requestId.hashCode;
  }
}

extension NavigatorStateExtension on _i23.NavigationService {
  Future<dynamic> navigateToHomeView({
    _i21.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.homeView,
      arguments: HomeViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToStartupView({
    _i21.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.startupView,
      arguments: StartupViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToWelcomeView({
    _i21.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.welcomeView,
      arguments: WelcomeViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToLoginView({
    _i21.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.loginView,
      arguments: LoginViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToSignupView({
    _i21.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.signupView,
      arguments: SignupViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToResetPasswordView({
    _i21.Key? key,
    String? oobCode,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.resetPasswordView,
      arguments: ResetPasswordViewArguments(key: key, oobCode: oobCode),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToUserInfoView({
    _i21.Key? key,
    required String uid,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.userInfoView,
      arguments: UserInfoViewArguments(key: key, uid: uid),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToJournalView({
    _i21.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.journalView,
      arguments: JournalViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToMoodTrackerView({
    _i21.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.moodTrackerView,
      arguments: MoodTrackerViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToNewJournalEntryView({
    _i21.Key? key,
    _i22.JournalEntry? journalEntry,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.newJournalEntryView,
      arguments: NewJournalEntryViewArguments(
        key: key,
        journalEntry: journalEntry,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToChatbotView({
    _i21.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.chatbotView,
      arguments: ChatbotViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToVolunteerSignupView({
    _i21.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.volunteerSignupView,
      arguments: VolunteerSignupViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToVolunteerSignupInfoView({
    _i21.Key? key,
    required String uid,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.volunteerSignupInfoView,
      arguments: VolunteerSignupInfoViewArguments(key: key, uid: uid),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToVolunteerHomeView({
    _i21.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.volunteerHomeView,
      arguments: VolunteerHomeViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToVolunteerLoginView({
    _i21.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.volunteerLoginView,
      arguments: VolunteerLoginViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToVolunteerResetPasswordView({
    _i21.Key? key,
    String? oobCode,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.volunteerResetPasswordView,
      arguments: VolunteerResetPasswordViewArguments(
        key: key,
        oobCode: oobCode,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToVolunteerOtpView({
    _i21.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.volunteerOtpView,
      arguments: VolunteerOtpViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToJournalDetailsView({
    _i21.Key? key,
    required _i22.JournalEntry journalEntry,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.journalDetailsView,
      arguments: JournalDetailsViewArguments(
        key: key,
        journalEntry: journalEntry,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToChatView({
    _i21.Key? key,
    required String volunteerId,
    required String volunteerName,
    required String requestId,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.chatView,
      arguments: ChatViewArguments(
        key: key,
        volunteerId: volunteerId,
        volunteerName: volunteerName,
        requestId: requestId,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithHomeView({
    _i21.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.homeView,
      arguments: HomeViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithStartupView({
    _i21.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.startupView,
      arguments: StartupViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithWelcomeView({
    _i21.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.welcomeView,
      arguments: WelcomeViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithLoginView({
    _i21.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.loginView,
      arguments: LoginViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithSignupView({
    _i21.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.signupView,
      arguments: SignupViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithResetPasswordView({
    _i21.Key? key,
    String? oobCode,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.resetPasswordView,
      arguments: ResetPasswordViewArguments(key: key, oobCode: oobCode),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithUserInfoView({
    _i21.Key? key,
    required String uid,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.userInfoView,
      arguments: UserInfoViewArguments(key: key, uid: uid),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithJournalView({
    _i21.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.journalView,
      arguments: JournalViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithMoodTrackerView({
    _i21.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.moodTrackerView,
      arguments: MoodTrackerViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithNewJournalEntryView({
    _i21.Key? key,
    _i22.JournalEntry? journalEntry,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.newJournalEntryView,
      arguments: NewJournalEntryViewArguments(
        key: key,
        journalEntry: journalEntry,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithChatbotView({
    _i21.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.chatbotView,
      arguments: ChatbotViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithVolunteerSignupView({
    _i21.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.volunteerSignupView,
      arguments: VolunteerSignupViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithVolunteerSignupInfoView({
    _i21.Key? key,
    required String uid,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.volunteerSignupInfoView,
      arguments: VolunteerSignupInfoViewArguments(key: key, uid: uid),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithVolunteerHomeView({
    _i21.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.volunteerHomeView,
      arguments: VolunteerHomeViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithVolunteerLoginView({
    _i21.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.volunteerLoginView,
      arguments: VolunteerLoginViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithVolunteerResetPasswordView({
    _i21.Key? key,
    String? oobCode,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.volunteerResetPasswordView,
      arguments: VolunteerResetPasswordViewArguments(
        key: key,
        oobCode: oobCode,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithVolunteerOtpView({
    _i21.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.volunteerOtpView,
      arguments: VolunteerOtpViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithJournalDetailsView({
    _i21.Key? key,
    required _i22.JournalEntry journalEntry,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.journalDetailsView,
      arguments: JournalDetailsViewArguments(
        key: key,
        journalEntry: journalEntry,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithChatView({
    _i21.Key? key,
    required String volunteerId,
    required String volunteerName,
    required String requestId,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.chatView,
      arguments: ChatViewArguments(
        key: key,
        volunteerId: volunteerId,
        volunteerName: volunteerName,
        requestId: requestId,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }
}
