// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// StackedNavigatorGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter/material.dart' as _i31;
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart' as _i1;
import 'package:stacked_services/stacked_services.dart' as _i34;
import 'package:you_app/models/journal_model.dart' as _i33;
import 'package:you_app/ui/shared/page_transitions.dart' as _i32;
import 'package:you_app/ui/views/breathe/breathe_view.dart' as _i25;
import 'package:you_app/ui/views/chat/chat_view.dart' as _i19;
import 'package:you_app/ui/views/chatbot/chatbot_view.dart' as _i12;
import 'package:you_app/ui/views/community_chat/community_chat_view.dart'
    as _i20;
import 'package:you_app/ui/views/edit_profile/edit_profile_view.dart' as _i23;
import 'package:you_app/ui/views/home/home_view.dart' as _i2;
import 'package:you_app/ui/views/journal/journal_view.dart' as _i9;
import 'package:you_app/ui/views/journal_details/journal_details_view.dart'
    as _i18;
import 'package:you_app/ui/views/login/login_view.dart' as _i5;
import 'package:you_app/ui/views/mood_insights/mood_insights_view.dart' as _i29;
import 'package:you_app/ui/views/mood_tracker/mood_tracker_view.dart' as _i10;
import 'package:you_app/ui/views/new_journal_entry/new_journal_entry_view.dart'
    as _i11;
import 'package:you_app/ui/views/paywall/paywall_view.dart' as _i27;
import 'package:you_app/ui/views/premium/premium_view.dart' as _i28;
import 'package:you_app/ui/views/profile/profile_view.dart' as _i22;
import 'package:you_app/ui/views/reset_password/reset_password_view.dart'
    as _i7;
import 'package:you_app/ui/views/signup/signup_view.dart' as _i6;
import 'package:you_app/ui/views/soothing_sounds/soothing_sounds_view.dart'
    as _i24;
import 'package:you_app/ui/views/startup/startup_view.dart' as _i3;
import 'package:you_app/ui/views/user_info/user_info_view.dart' as _i8;
import 'package:you_app/ui/views/verify_email/verify_email_view.dart' as _i30;
import 'package:you_app/ui/views/volunteer_edit_profile/volunteer_edit_profile_view.dart'
    as _i26;
import 'package:you_app/ui/views/volunteer_home/volunteer_home_view.dart'
    as _i15;
import 'package:you_app/ui/views/volunteer_pending_verification/volunteer_pending_verification_view.dart'
    as _i21;
import 'package:you_app/ui/views/volunteer_reset_password/volunteer_reset_password_view.dart'
    as _i16;
import 'package:you_app/ui/views/volunteer_signup/volunteer_otp.dart' as _i17;
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

  static const volunteerResetPasswordView = '/volunteer-reset-password-view';

  static const volunteerOtpView = '/volunteer-otp-view';

  static const journalDetailsView = '/journal-details-view';

  static const chatView = '/chat-view';

  static const communityChatView = '/community-chat-view';

  static const volunteerPendingVerificationView =
      '/volunteer-pending-verification-view';

  static const profileView = '/profile-view';

  static const editProfileView = '/edit-profile-view';

  static const soothingSoundsView = '/soothing-sounds-view';

  static const breatheView = '/breathe-view';

  static const volunteerEditProfileView = '/volunteer-edit-profile-view';

  static const paywallView = '/paywall-view';

  static const premiumView = '/premium-view';

  static const moodInsightsView = '/mood-insights-view';

  static const verifyEmailView = '/verify-email-view';

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
    volunteerResetPasswordView,
    volunteerOtpView,
    journalDetailsView,
    chatView,
    communityChatView,
    volunteerPendingVerificationView,
    profileView,
    editProfileView,
    soothingSoundsView,
    breatheView,
    volunteerEditProfileView,
    paywallView,
    premiumView,
    moodInsightsView,
    verifyEmailView,
  };
}

class StackedRouter extends _i1.RouterBase {
  final _routes = <_i1.RouteDef>[
    _i1.RouteDef(
      Routes.homeView,
      page: _i2.HomeView,
    ),
    _i1.RouteDef(
      Routes.startupView,
      page: _i3.StartupView,
    ),
    _i1.RouteDef(
      Routes.welcomeView,
      page: _i4.WelcomeView,
    ),
    _i1.RouteDef(
      Routes.loginView,
      page: _i5.LoginView,
    ),
    _i1.RouteDef(
      Routes.signupView,
      page: _i6.SignupView,
    ),
    _i1.RouteDef(
      Routes.resetPasswordView,
      page: _i7.ResetPasswordView,
    ),
    _i1.RouteDef(
      Routes.userInfoView,
      page: _i8.UserInfoView,
    ),
    _i1.RouteDef(
      Routes.journalView,
      page: _i9.JournalView,
    ),
    _i1.RouteDef(
      Routes.moodTrackerView,
      page: _i10.MoodTrackerView,
    ),
    _i1.RouteDef(
      Routes.newJournalEntryView,
      page: _i11.NewJournalEntryView,
    ),
    _i1.RouteDef(
      Routes.chatbotView,
      page: _i12.ChatbotView,
    ),
    _i1.RouteDef(
      Routes.volunteerSignupView,
      page: _i13.VolunteerSignupView,
    ),
    _i1.RouteDef(
      Routes.volunteerSignupInfoView,
      page: _i14.VolunteerSignupInfoView,
    ),
    _i1.RouteDef(
      Routes.volunteerHomeView,
      page: _i15.VolunteerHomeView,
    ),
    _i1.RouteDef(
      Routes.volunteerResetPasswordView,
      page: _i16.VolunteerResetPasswordView,
    ),
    _i1.RouteDef(
      Routes.volunteerOtpView,
      page: _i17.VolunteerOtpView,
    ),
    _i1.RouteDef(
      Routes.journalDetailsView,
      page: _i18.JournalDetailsView,
    ),
    _i1.RouteDef(
      Routes.chatView,
      page: _i19.ChatView,
    ),
    _i1.RouteDef(
      Routes.communityChatView,
      page: _i20.CommunityChatView,
    ),
    _i1.RouteDef(
      Routes.volunteerPendingVerificationView,
      page: _i21.VolunteerPendingVerificationView,
    ),
    _i1.RouteDef(
      Routes.profileView,
      page: _i22.ProfileView,
    ),
    _i1.RouteDef(
      Routes.editProfileView,
      page: _i23.EditProfileView,
    ),
    _i1.RouteDef(
      Routes.soothingSoundsView,
      page: _i24.SoothingSoundsView,
    ),
    _i1.RouteDef(
      Routes.breatheView,
      page: _i25.BreatheView,
    ),
    _i1.RouteDef(
      Routes.volunteerEditProfileView,
      page: _i26.VolunteerEditProfileView,
    ),
    _i1.RouteDef(
      Routes.paywallView,
      page: _i27.PaywallView,
    ),
    _i1.RouteDef(
      Routes.premiumView,
      page: _i28.PremiumView,
    ),
    _i1.RouteDef(
      Routes.moodInsightsView,
      page: _i29.MoodInsightsView,
    ),
    _i1.RouteDef(
      Routes.verifyEmailView,
      page: _i30.VerifyEmailView,
    ),
  ];

  final _pagesMap = <Type, _i1.StackedRouteFactory>{
    _i2.HomeView: (data) {
      final args = data.getArgs<HomeViewArguments>(
        orElse: () => const HomeViewArguments(),
      );
      return _i31.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i2.HomeView(key: args.key, initialIndex: args.initialIndex),
        settings: data,
      );
    },
    _i3.StartupView: (data) {
      final args = data.getArgs<StartupViewArguments>(
        orElse: () => const StartupViewArguments(),
      );
      return _i31.MaterialPageRoute<dynamic>(
        builder: (context) => _i3.StartupView(key: args.key),
        settings: data,
      );
    },
    _i4.WelcomeView: (data) {
      final args = data.getArgs<WelcomeViewArguments>(
        orElse: () => const WelcomeViewArguments(),
      );
      return _i31.MaterialPageRoute<dynamic>(
        builder: (context) => _i4.WelcomeView(key: args.key),
        settings: data,
      );
    },
    _i5.LoginView: (data) {
      final args = data.getArgs<LoginViewArguments>(
        orElse: () => const LoginViewArguments(),
      );
      return _i31.MaterialPageRoute<dynamic>(
        builder: (context) => _i5.LoginView(key: args.key),
        settings: data,
      );
    },
    _i6.SignupView: (data) {
      final args = data.getArgs<SignupViewArguments>(
        orElse: () => const SignupViewArguments(),
      );
      return _i31.MaterialPageRoute<dynamic>(
        builder: (context) => _i6.SignupView(key: args.key),
        settings: data,
      );
    },
    _i7.ResetPasswordView: (data) {
      final args = data.getArgs<ResetPasswordViewArguments>(
        orElse: () => const ResetPasswordViewArguments(),
      );
      return _i31.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i7.ResetPasswordView(key: args.key, oobCode: args.oobCode),
        settings: data,
      );
    },
    _i8.UserInfoView: (data) {
      final args = data.getArgs<UserInfoViewArguments>(nullOk: false);
      return _i31.MaterialPageRoute<dynamic>(
        builder: (context) => _i8.UserInfoView(key: args.key, uid: args.uid),
        settings: data,
      );
    },
    _i9.JournalView: (data) {
      final args = data.getArgs<JournalViewArguments>(
        orElse: () => const JournalViewArguments(),
      );
      return _i31.MaterialPageRoute<dynamic>(
        builder: (context) => _i9.JournalView(key: args.key),
        settings: data,
      );
    },
    _i10.MoodTrackerView: (data) {
      final args = data.getArgs<MoodTrackerViewArguments>(
        orElse: () => const MoodTrackerViewArguments(),
      );
      return _i31.PageRouteBuilder<dynamic>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _i10.MoodTrackerView(key: args.key),
        settings: data,
        transitionsBuilder: data.transition ?? _i32.scaleFadeTransition,
      );
    },
    _i11.NewJournalEntryView: (data) {
      final args = data.getArgs<NewJournalEntryViewArguments>(
        orElse: () => const NewJournalEntryViewArguments(),
      );
      return _i31.MaterialPageRoute<dynamic>(
        builder: (context) => _i11.NewJournalEntryView(
            key: args.key, journalEntry: args.journalEntry),
        settings: data,
      );
    },
    _i12.ChatbotView: (data) {
      final args = data.getArgs<ChatbotViewArguments>(
        orElse: () => const ChatbotViewArguments(),
      );
      return _i31.PageRouteBuilder<dynamic>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _i12.ChatbotView(key: args.key),
        settings: data,
        transitionsBuilder: data.transition ?? _i32.slideUpTransition,
      );
    },
    _i13.VolunteerSignupView: (data) {
      final args = data.getArgs<VolunteerSignupViewArguments>(
        orElse: () => const VolunteerSignupViewArguments(),
      );
      return _i31.MaterialPageRoute<dynamic>(
        builder: (context) => _i13.VolunteerSignupView(key: args.key),
        settings: data,
      );
    },
    _i14.VolunteerSignupInfoView: (data) {
      final args =
          data.getArgs<VolunteerSignupInfoViewArguments>(nullOk: false);
      return _i31.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i14.VolunteerSignupInfoView(key: args.key, uid: args.uid),
        settings: data,
      );
    },
    _i15.VolunteerHomeView: (data) {
      final args = data.getArgs<VolunteerHomeViewArguments>(
        orElse: () => const VolunteerHomeViewArguments(),
      );
      return _i31.MaterialPageRoute<dynamic>(
        builder: (context) => _i15.VolunteerHomeView(key: args.key),
        settings: data,
      );
    },
    _i16.VolunteerResetPasswordView: (data) {
      final args = data.getArgs<VolunteerResetPasswordViewArguments>(
        orElse: () => const VolunteerResetPasswordViewArguments(),
      );
      return _i31.MaterialPageRoute<dynamic>(
        builder: (context) => _i16.VolunteerResetPasswordView(
            key: args.key, oobCode: args.oobCode),
        settings: data,
      );
    },
    _i17.VolunteerOtpView: (data) {
      final args = data.getArgs<VolunteerOtpViewArguments>(
        orElse: () => const VolunteerOtpViewArguments(),
      );
      return _i31.MaterialPageRoute<dynamic>(
        builder: (context) => _i17.VolunteerOtpView(key: args.key),
        settings: data,
      );
    },
    _i18.JournalDetailsView: (data) {
      final args = data.getArgs<JournalDetailsViewArguments>(nullOk: false);
      return _i31.MaterialPageRoute<dynamic>(
        builder: (context) => _i18.JournalDetailsView(
            key: args.key, journalEntry: args.journalEntry),
        settings: data,
      );
    },
    _i19.ChatView: (data) {
      final args = data.getArgs<ChatViewArguments>(nullOk: false);
      return _i31.PageRouteBuilder<dynamic>(
        pageBuilder: (context, animation, secondaryAnimation) => _i19.ChatView(
            key: args.key,
            volunteerId: args.volunteerId,
            volunteerName: args.volunteerName,
            requestId: args.requestId),
        settings: data,
        transitionsBuilder: data.transition ?? _i32.slideUpTransition,
      );
    },
    _i20.CommunityChatView: (data) {
      final args = data.getArgs<CommunityChatViewArguments>(nullOk: false);
      return _i31.PageRouteBuilder<dynamic>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _i20.CommunityChatView(
                key: args.key,
                communityId: args.communityId,
                communityName: args.communityName),
        settings: data,
        transitionsBuilder: data.transition ?? _i32.slideUpTransition,
      );
    },
    _i21.VolunteerPendingVerificationView: (data) {
      final args = data.getArgs<VolunteerPendingVerificationViewArguments>(
        orElse: () => const VolunteerPendingVerificationViewArguments(),
      );
      return _i31.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i21.VolunteerPendingVerificationView(key: args.key),
        settings: data,
      );
    },
    _i22.ProfileView: (data) {
      final args = data.getArgs<ProfileViewArguments>(
        orElse: () => const ProfileViewArguments(),
      );
      return _i31.MaterialPageRoute<dynamic>(
        builder: (context) => _i22.ProfileView(key: args.key),
        settings: data,
      );
    },
    _i23.EditProfileView: (data) {
      final args = data.getArgs<EditProfileViewArguments>(
        orElse: () => const EditProfileViewArguments(),
      );
      return _i31.MaterialPageRoute<dynamic>(
        builder: (context) => _i23.EditProfileView(key: args.key),
        settings: data,
      );
    },
    _i24.SoothingSoundsView: (data) {
      final args = data.getArgs<SoothingSoundsViewArguments>(
        orElse: () => const SoothingSoundsViewArguments(),
      );
      return _i31.MaterialPageRoute<dynamic>(
        builder: (context) => _i24.SoothingSoundsView(key: args.key),
        settings: data,
      );
    },
    _i25.BreatheView: (data) {
      final args = data.getArgs<BreatheViewArguments>(
        orElse: () => const BreatheViewArguments(),
      );
      return _i31.PageRouteBuilder<dynamic>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _i25.BreatheView(key: args.key),
        settings: data,
        transitionsBuilder: data.transition ?? _i32.fadeTransition,
      );
    },
    _i26.VolunteerEditProfileView: (data) {
      final args = data.getArgs<VolunteerEditProfileViewArguments>(
        orElse: () => const VolunteerEditProfileViewArguments(),
      );
      return _i31.MaterialPageRoute<dynamic>(
        builder: (context) => _i26.VolunteerEditProfileView(key: args.key),
        settings: data,
      );
    },
    _i27.PaywallView: (data) {
      final args = data.getArgs<PaywallViewArguments>(
        orElse: () => const PaywallViewArguments(),
      );
      return _i31.PageRouteBuilder<dynamic>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _i27.PaywallView(feature: args.feature, key: args.key),
        settings: data,
        transitionsBuilder: data.transition ?? _i32.slideUpTransition,
      );
    },
    _i28.PremiumView: (data) {
      final args = data.getArgs<PremiumViewArguments>(
        orElse: () => const PremiumViewArguments(),
      );
      return _i31.PageRouteBuilder<dynamic>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _i28.PremiumView(key: args.key),
        settings: data,
        transitionsBuilder: data.transition ?? _i32.slideUpTransition,
      );
    },
    _i29.MoodInsightsView: (data) {
      final args = data.getArgs<MoodInsightsViewArguments>(
        orElse: () => const MoodInsightsViewArguments(),
      );
      return _i31.PageRouteBuilder<dynamic>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _i29.MoodInsightsView(key: args.key),
        settings: data,
        transitionsBuilder: data.transition ?? _i32.slideUpTransition,
      );
    },
    _i30.VerifyEmailView: (data) {
      final args = data.getArgs<VerifyEmailViewArguments>(
        orElse: () => const VerifyEmailViewArguments(),
      );
      return _i31.PageRouteBuilder<dynamic>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _i30.VerifyEmailView(key: args.key, source: args.source),
        settings: data,
        transitionsBuilder: data.transition ?? _i32.slideUpTransition,
      );
    },
  };

  @override
  List<_i1.RouteDef> get routes => _routes;

  @override
  Map<Type, _i1.StackedRouteFactory> get pagesMap => _pagesMap;
}

class HomeViewArguments {
  const HomeViewArguments({
    this.key,
    this.initialIndex = 1,
  });

  final _i31.Key? key;

  final int initialIndex;

  @override
  String toString() {
    return '{"key": "$key", "initialIndex": "$initialIndex"}';
  }

  @override
  bool operator ==(covariant HomeViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.initialIndex == initialIndex;
  }

  @override
  int get hashCode {
    return key.hashCode ^ initialIndex.hashCode;
  }
}

class StartupViewArguments {
  const StartupViewArguments({this.key});

  final _i31.Key? key;

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

  final _i31.Key? key;

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

  final _i31.Key? key;

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

  final _i31.Key? key;

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
  const ResetPasswordViewArguments({
    this.key,
    this.oobCode,
  });

  final _i31.Key? key;

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
  const UserInfoViewArguments({
    this.key,
    required this.uid,
  });

  final _i31.Key? key;

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

  final _i31.Key? key;

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

  final _i31.Key? key;

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
  const NewJournalEntryViewArguments({
    this.key,
    this.journalEntry,
  });

  final _i31.Key? key;

  final _i33.JournalEntry? journalEntry;

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

  final _i31.Key? key;

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

  final _i31.Key? key;

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
  const VolunteerSignupInfoViewArguments({
    this.key,
    required this.uid,
  });

  final _i31.Key? key;

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

  final _i31.Key? key;

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

class VolunteerResetPasswordViewArguments {
  const VolunteerResetPasswordViewArguments({
    this.key,
    this.oobCode,
  });

  final _i31.Key? key;

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

  final _i31.Key? key;

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
  const JournalDetailsViewArguments({
    this.key,
    required this.journalEntry,
  });

  final _i31.Key? key;

  final _i33.JournalEntry journalEntry;

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

  final _i31.Key? key;

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

class CommunityChatViewArguments {
  const CommunityChatViewArguments({
    this.key,
    required this.communityId,
    required this.communityName,
  });

  final _i31.Key? key;

  final String communityId;

  final String communityName;

  @override
  String toString() {
    return '{"key": "$key", "communityId": "$communityId", "communityName": "$communityName"}';
  }

  @override
  bool operator ==(covariant CommunityChatViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key &&
        other.communityId == communityId &&
        other.communityName == communityName;
  }

  @override
  int get hashCode {
    return key.hashCode ^ communityId.hashCode ^ communityName.hashCode;
  }
}

class VolunteerPendingVerificationViewArguments {
  const VolunteerPendingVerificationViewArguments({this.key});

  final _i31.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant VolunteerPendingVerificationViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class ProfileViewArguments {
  const ProfileViewArguments({this.key});

  final _i31.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant ProfileViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class EditProfileViewArguments {
  const EditProfileViewArguments({this.key});

  final _i31.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant EditProfileViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class SoothingSoundsViewArguments {
  const SoothingSoundsViewArguments({this.key});

  final _i31.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant SoothingSoundsViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class BreatheViewArguments {
  const BreatheViewArguments({this.key});

  final _i31.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant BreatheViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class VolunteerEditProfileViewArguments {
  const VolunteerEditProfileViewArguments({this.key});

  final _i31.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant VolunteerEditProfileViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class PaywallViewArguments {
  const PaywallViewArguments({
    this.feature = 'general',
    this.key,
  });

  final String feature;

  final _i31.Key? key;

  @override
  String toString() {
    return '{"feature": "$feature", "key": "$key"}';
  }

  @override
  bool operator ==(covariant PaywallViewArguments other) {
    if (identical(this, other)) return true;
    return other.feature == feature && other.key == key;
  }

  @override
  int get hashCode {
    return feature.hashCode ^ key.hashCode;
  }
}

class PremiumViewArguments {
  const PremiumViewArguments({this.key});

  final _i31.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant PremiumViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class MoodInsightsViewArguments {
  const MoodInsightsViewArguments({this.key});

  final _i31.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant MoodInsightsViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class VerifyEmailViewArguments {
  const VerifyEmailViewArguments({
    this.key,
    this.source = 'nudge',
  });

  final _i31.Key? key;

  final String source;

  @override
  String toString() {
    return '{"key": "$key", "source": "$source"}';
  }

  @override
  bool operator ==(covariant VerifyEmailViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.source == source;
  }

  @override
  int get hashCode {
    return key.hashCode ^ source.hashCode;
  }
}

extension NavigatorStateExtension on _i34.NavigationService {
  Future<dynamic> navigateToHomeView({
    _i31.Key? key,
    int initialIndex = 1,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.homeView,
        arguments: HomeViewArguments(key: key, initialIndex: initialIndex),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToStartupView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.startupView,
        arguments: StartupViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToWelcomeView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.welcomeView,
        arguments: WelcomeViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToLoginView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.loginView,
        arguments: LoginViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToSignupView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.signupView,
        arguments: SignupViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToResetPasswordView({
    _i31.Key? key,
    String? oobCode,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.resetPasswordView,
        arguments: ResetPasswordViewArguments(key: key, oobCode: oobCode),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToUserInfoView({
    _i31.Key? key,
    required String uid,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.userInfoView,
        arguments: UserInfoViewArguments(key: key, uid: uid),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToJournalView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.journalView,
        arguments: JournalViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToMoodTrackerView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.moodTrackerView,
        arguments: MoodTrackerViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToNewJournalEntryView({
    _i31.Key? key,
    _i33.JournalEntry? journalEntry,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.newJournalEntryView,
        arguments:
            NewJournalEntryViewArguments(key: key, journalEntry: journalEntry),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToChatbotView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.chatbotView,
        arguments: ChatbotViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToVolunteerSignupView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.volunteerSignupView,
        arguments: VolunteerSignupViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToVolunteerSignupInfoView({
    _i31.Key? key,
    required String uid,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.volunteerSignupInfoView,
        arguments: VolunteerSignupInfoViewArguments(key: key, uid: uid),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToVolunteerHomeView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.volunteerHomeView,
        arguments: VolunteerHomeViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToVolunteerResetPasswordView({
    _i31.Key? key,
    String? oobCode,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.volunteerResetPasswordView,
        arguments:
            VolunteerResetPasswordViewArguments(key: key, oobCode: oobCode),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToVolunteerOtpView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.volunteerOtpView,
        arguments: VolunteerOtpViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToJournalDetailsView({
    _i31.Key? key,
    required _i33.JournalEntry journalEntry,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.journalDetailsView,
        arguments:
            JournalDetailsViewArguments(key: key, journalEntry: journalEntry),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToChatView({
    _i31.Key? key,
    required String volunteerId,
    required String volunteerName,
    required String requestId,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.chatView,
        arguments: ChatViewArguments(
            key: key,
            volunteerId: volunteerId,
            volunteerName: volunteerName,
            requestId: requestId),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToCommunityChatView({
    _i31.Key? key,
    required String communityId,
    required String communityName,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.communityChatView,
        arguments: CommunityChatViewArguments(
            key: key, communityId: communityId, communityName: communityName),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToVolunteerPendingVerificationView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.volunteerPendingVerificationView,
        arguments: VolunteerPendingVerificationViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToProfileView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.profileView,
        arguments: ProfileViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToEditProfileView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.editProfileView,
        arguments: EditProfileViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToSoothingSoundsView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.soothingSoundsView,
        arguments: SoothingSoundsViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToBreatheView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.breatheView,
        arguments: BreatheViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToVolunteerEditProfileView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.volunteerEditProfileView,
        arguments: VolunteerEditProfileViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToPaywallView({
    String feature = 'general',
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.paywallView,
        arguments: PaywallViewArguments(feature: feature, key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToPremiumView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.premiumView,
        arguments: PremiumViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToMoodInsightsView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.moodInsightsView,
        arguments: MoodInsightsViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> navigateToVerifyEmailView({
    _i31.Key? key,
    String source = 'nudge',
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return navigateTo<dynamic>(Routes.verifyEmailView,
        arguments: VerifyEmailViewArguments(key: key, source: source),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithHomeView({
    _i31.Key? key,
    int initialIndex = 1,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.homeView,
        arguments: HomeViewArguments(key: key, initialIndex: initialIndex),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithStartupView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.startupView,
        arguments: StartupViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithWelcomeView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.welcomeView,
        arguments: WelcomeViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithLoginView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.loginView,
        arguments: LoginViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithSignupView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.signupView,
        arguments: SignupViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithResetPasswordView({
    _i31.Key? key,
    String? oobCode,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.resetPasswordView,
        arguments: ResetPasswordViewArguments(key: key, oobCode: oobCode),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithUserInfoView({
    _i31.Key? key,
    required String uid,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.userInfoView,
        arguments: UserInfoViewArguments(key: key, uid: uid),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithJournalView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.journalView,
        arguments: JournalViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithMoodTrackerView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.moodTrackerView,
        arguments: MoodTrackerViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithNewJournalEntryView({
    _i31.Key? key,
    _i33.JournalEntry? journalEntry,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.newJournalEntryView,
        arguments:
            NewJournalEntryViewArguments(key: key, journalEntry: journalEntry),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithChatbotView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.chatbotView,
        arguments: ChatbotViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithVolunteerSignupView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.volunteerSignupView,
        arguments: VolunteerSignupViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithVolunteerSignupInfoView({
    _i31.Key? key,
    required String uid,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.volunteerSignupInfoView,
        arguments: VolunteerSignupInfoViewArguments(key: key, uid: uid),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithVolunteerHomeView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.volunteerHomeView,
        arguments: VolunteerHomeViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithVolunteerResetPasswordView({
    _i31.Key? key,
    String? oobCode,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.volunteerResetPasswordView,
        arguments:
            VolunteerResetPasswordViewArguments(key: key, oobCode: oobCode),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithVolunteerOtpView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.volunteerOtpView,
        arguments: VolunteerOtpViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithJournalDetailsView({
    _i31.Key? key,
    required _i33.JournalEntry journalEntry,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.journalDetailsView,
        arguments:
            JournalDetailsViewArguments(key: key, journalEntry: journalEntry),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithChatView({
    _i31.Key? key,
    required String volunteerId,
    required String volunteerName,
    required String requestId,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.chatView,
        arguments: ChatViewArguments(
            key: key,
            volunteerId: volunteerId,
            volunteerName: volunteerName,
            requestId: requestId),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithCommunityChatView({
    _i31.Key? key,
    required String communityId,
    required String communityName,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.communityChatView,
        arguments: CommunityChatViewArguments(
            key: key, communityId: communityId, communityName: communityName),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithVolunteerPendingVerificationView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.volunteerPendingVerificationView,
        arguments: VolunteerPendingVerificationViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithProfileView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.profileView,
        arguments: ProfileViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithEditProfileView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.editProfileView,
        arguments: EditProfileViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithSoothingSoundsView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.soothingSoundsView,
        arguments: SoothingSoundsViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithBreatheView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.breatheView,
        arguments: BreatheViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithVolunteerEditProfileView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.volunteerEditProfileView,
        arguments: VolunteerEditProfileViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithPaywallView({
    String feature = 'general',
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.paywallView,
        arguments: PaywallViewArguments(feature: feature, key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithPremiumView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.premiumView,
        arguments: PremiumViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithMoodInsightsView({
    _i31.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.moodInsightsView,
        arguments: MoodInsightsViewArguments(key: key),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }

  Future<dynamic> replaceWithVerifyEmailView({
    _i31.Key? key,
    String source = 'nudge',
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transition,
  }) async {
    return replaceWith<dynamic>(Routes.verifyEmailView,
        arguments: VerifyEmailViewArguments(key: key, source: source),
        id: routerId,
        preventDuplicates: preventDuplicates,
        parameters: parameters,
        transition: transition);
  }
}
