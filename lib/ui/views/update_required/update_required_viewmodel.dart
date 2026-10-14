import 'package:stacked/stacked.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:you_app/services/app_version_service.dart';
import 'package:you_app/services/base/app_log.dart';

class UpdateRequiredViewModel extends BaseViewModel {
  final UpdateRequirement requirement;

  UpdateRequiredViewModel(this.requirement);

  String get message =>
      requirement.message ??
      "We've made some important improvements to keep You safe and working "
          'smoothly. Please update to the latest version to continue.';

  bool get canOpenStore => requirement.storeUrl != null;

  Future<void> openStore() async {
    final url = requirement.storeUrl;
    if (url == null) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      AppLog.error('UpdateRequiredViewModel.openStore', e);
    }
  }
}
