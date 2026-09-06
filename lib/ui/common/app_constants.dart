import 'package:you_app/env.dart';

class AppConstants {
  static const String appName = Environments.appName;
  static const String privacyUrl = Environments.privacyUrl;
  static const String termsUrl = Environments.termsUrl;
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

  // Freemium free-tier limits — fallbacks used when the matching key is absent
  // from app_settings/global_config (which is the live-tunable source of truth).
  static const int dodoDailyCapDefault = 10; // Dodo AI messages per day (PKT)
  static const int welcomeChatsDefault = 3; // lifetime volunteer welcome chats
  static const int journalHistoryDaysDefault = 7; // journal history window
  static const int moodWindowDaysDefault = 7; // mood tracker view window
  static const int communityThreadsMonthlyDefault = 5; // new threads / month
  static const int communityRepliesMonthlyDefault = 30; // replies / month

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
  static const String notification2 = 'assets/icons/notification2.png';
  static const String setting = 'assets/icons/setting.png';
  static const String done = 'assets/icons/done.png';
  static const String activeChat = 'assets/icons/activeChat.png';
  static const String pending = 'assets/icons/pending.png';
  static const String journalIcon = 'assets/icons/journalIcon.png';
  static const String logout = 'assets/icons/logout.png';
  static const String delete = 'assets/icons/delete.png';
  static const String send = 'assets/icons/send.png';
  static const String cancel = 'assets/icons/cancel.png';
  static const String heart = 'assets/icons/heart.png';
  static const String group = 'assets/icons/group.png';
  static const String smsRequest = 'assets/icons/smsRequest.png';
  static const String reply = 'assets/icons/reply.png';
  static const String email = 'assets/icons/email.png';
  static const String phone = 'assets/icons/phone.png';
  static const String gift = 'assets/icons/gift.png';
  static const String moon = 'assets/icons/moon.png';
  static const String mic = 'assets/icons/mic.png';
  static const String tick = 'assets/icons/tick.png';
  static const String refresh = 'assets/icons/refresh.png';
  static const String brain = 'assets/icons/brain.png';
  static const String community2 = 'assets/icons/community2.png';
  static const String avatarFemale = 'assets/icons/avatar_female.png';
  static const String avatarBinary = 'assets/icons/avatar_binary.png';
  static const String premiumBadge = 'assets/icons/premium.png'; // outline
  static const String premiumBadgeFill = 'assets/icons/premium_fill.png';

  //images
  static const String register = 'assets/images/1.png';
  static const String avatar = 'assets/images/avatar.png';
  static const String background = 'assets/images/background.jpg';
  static const String pinkBackground = 'assets/images/pink_background.jpg';
  static const String emo = 'assets/images/emo.png';
  static const String journal = 'assets/images/journal.png';
  static const String journalImg = 'assets/images/journal_img.png';
  static const String music = 'assets/images/music.jpg';
  static const String santa = 'assets/images/santa.png';
  static const String dodoCut = 'assets/images/dodo_cut.png';
  static const String dodo = 'assets/images/dodo.png';
  static const String logoRounded = 'assets/images/logo_rounded.png';
  static const String logoRound = 'assets/images/logo_round.png';
  static const String logoSquare = 'assets/images/logo_square.png';
  static const String soothing = 'assets/images/soothing.jpg';
  static const String breathe = 'assets/images/breathe.jpg';
  static const String soothing2 = 'assets/images/soothing2.jpg';
  static const String lonliness = 'assets/images/lonliness.png';

  // UI sound effects. The soothing-sounds TRACKS are no longer bundled — they
  // live in Cloud Storage and are authored by the admin in the `sounds`
  // collection (see SoundService). Only these tiny SFX ship in the app.
  static const String drop = 'assets/sounds/drop.mp3';
  static const String page = 'assets/sounds/journal.mp3';
  static const String swipe = 'assets/sounds/swipe.mp3';

  //animations
  static const String like = 'assets/animations/like.lottie';
  static const String empty = 'assets/animations/empty.lottie';
  static const String loading = 'assets/animations/loading.lottie';
  static const String done2 = 'assets/animations/done.lottie';
  static const String pending2 = 'assets/animations/pending.lottie';
  static const String swipeRight = 'assets/animations/swipe_right.lottie';
  static const String swipeLeft = 'assets/animations/swipe_left.lottie';
  static const String searchVolunteer =
      'assets/animations/search_volunteer.lottie';
  static const String premium = 'assets/animations/premium.lottie';
  static const String plus = 'assets/animations/plus.lottie';
  static const String wave = 'assets/animations/wave.lottie';
  static const String success = 'assets/animations/success.lottie';

  // Volunteer Tags
  static const List<String> volunteerTags = [
    'ADHD',
    'Anxiety',
    'Depression',
    'Stress',
    'Relationships',
    'Panic',
    'Phobia',
    'Dysthymia',
    'Bipolar',
    'Autism',
    'PTSD',
    'OCD',
    'Hoarding',
    'Borderline',
    'Narcissism',
    'Anorexia',
    'Bulimia',
    'Schizophrenia',
    'Addiction',
    'Insomnia',
    'Delusion',
    'Trauma',
    'Clinical Psychology',
    'Counseling Psychology',
    'School Psychology',
    'Social Work',
    'Psychiatry',
    'Other'
  ];

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
