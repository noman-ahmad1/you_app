import 'package:you_app/env.dart';

class AppConstants {
  static const String appName = Environments.appName;
  static const String defaultCurrencyCode =
      'PKR'; // your currency code in 3 digit
  static const String defaultCurrencySide =
      'right'; // default currency position
  static const String defaultCurrencySymbol = '\$'; // default currency symbol
  static const String defaultLanguageApp = 'en';
  static const int defaultMakeingOrder =
      0; // 0=> from multiple stores // 1 = single store only
  static const String defaultSMSGateway = '2'; // 2 = firebase // 1 = rest
  static const double defaultDeliverRadius = 50;
  static const int userLogin = 0;
  static const int defaultVerificationForSignup = 0; // 0 = email // 1= phone
  static const int defaultShippingMethod = 0;

  //icons
  static const String add = 'assets/icons/add.png';
  static const String apple = 'assets/icons/Apple.png';
  static const String back = 'assets/icons/back.png';
  static const String backward = 'assets/icons/backward.png';
  static const String chat = 'assets/icons/chat.png';
  static const String community = 'assets/icons/community.png';
  static const String edit = 'assets/icons/edit.png';
  static const String forward = 'assets/icons/forward.png';
  static const String google = 'assets/icons/Google.png';
  static const String home = 'assets/icons/home.png';
  static const String menu = 'assets/icons/menu.png';
  static const String msg = 'assets/icons/msg.png';
  static const String next = 'assets/icons/next.png';
  static const String pause = 'assets/icons/pause.png';
  static const String play = 'assets/icons/play.png';
  static const String star = 'assets/icons/star.png';
  static const String starFill = 'assets/icons/star_fill.png';
  static const String anxiety = 'assets/images/anxiety.jpg';
  static const String write = 'assets/icons/write.png';
  static const String emoji_1 = 'assets/icons/emo1.png';
  static const String emoji_2 = 'assets/icons/emo2.png';
  static const String emoji_3 = 'assets/icons/emo3.png';
  static const String emoji_4 = 'assets/icons/emo4.png';
  static const String emoji_5 = 'assets/icons/emo5.png';
  static const String emoji_6 = 'assets/icons/emo6.png';
  static const String emoji_7 = 'assets/icons/emo7.png';
  static const String emoji_8 = 'assets/icons/emo8.png';
  static const String emoji_9 = 'assets/icons/emo9.png';
  static const String camera = 'assets/icons/camera.png';
  static const String person = 'assets/icons/person.png';
  static const String stat = 'assets/icons/stat.png';
  static const String notification = 'assets/icons/notification.png';
  static const String setting = 'assets/icons/setting.png';
  static const String done = 'assets/icons/done.png';
  static const String activeChat = 'assets/icons/activeChat.png';
  static const String pending = 'assets/icons/pending.png';
  static const String journalIcon = 'assets/icons/journalIcon.png';
  static const String logout = 'assets/icons/logout.png';

  //images
  static const String register = 'assets/images/1.png';
  static const String avatar = 'assets/images/avatar.png';
  static const String background = 'assets/images/background.jpg';
  static const String emo = 'assets/images/emo.png';
  static const String journal = 'assets/images/journal.png';
  static const String music = 'assets/images/music.jpg';
  static const String santa = 'assets/images/santa.png';
  static const String logo = 'assets/images/You.png';

  //sounds
  static const String drop = 'assets/sounds/drop.mp3';
  static const String page = 'assets/sounds/journal.mp3';
  static const String swipe = 'assets/sounds/swipe.mp3';

  // static List<LanguageModel> languages = [
  //   LanguageModel(
  //       imageUrl: '',
  //       languageName: 'English',
  //       countryCode: 'US',
  //       languageCode: 'en'),
  //   LanguageModel(
  //       imageUrl: '',
  //       languageName: 'عربي',
  //       countryCode: 'AE',
  //       languageCode: 'ar'),
  //   LanguageModel(
  //       imageUrl: '',
  //       languageName: 'हिन्दी',
  //       countryCode: 'IN',
  //       languageCode: 'hi'),
  // ];
}
