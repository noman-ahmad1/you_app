import 'package:stacked/stacked.dart';

class UserInfoViewModel extends BaseViewModel {
  final String uid;

  UserInfoViewModel({
    required this.uid,
  });

  @override
  void onViewModelReady() {
    // You can now use the uid here
    print('User ID: $uid');
    // Initialize your view model with the user ID
    // super.onViewModelReady();
  }
}
