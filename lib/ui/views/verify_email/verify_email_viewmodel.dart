import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/services/analytics_service.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/base/app_log.dart';

/// Full-screen, dismissible email-verification step reached from the premium
/// gate, the soft nudge, and the volunteer block. It never blocks: closing
/// returns `false`; verifying returns `true`.
///
/// Robustness: `reload()`s before every re-check; auto re-checks when the app
/// returns to the foreground (the user likely clicked the link in their mail
/// app); rate-limits resend with a 60s cooldown and handles Firebase's
/// `too-many-requests` + offline errors with calm copy.
class VerifyEmailViewModel extends BaseViewModel with WidgetsBindingObserver {
  final _authService = locator<AuthenticationService>();
  final _navigationService = locator<NavigationService>();
  final _analytics = locator<AnalyticsService>();

  /// Coarse analytics attribution for where this was opened from.
  final String source;
  VerifyEmailViewModel({this.source = 'nudge'});

  /// Seconds a user must wait between resends (protects Firebase's quota).
  static const int _cooldownSeconds = 60;
  int _cooldown = 0;
  int get cooldown => _cooldown;
  bool get canResend => _cooldown == 0 && !isBusy;
  Timer? _timer;

  /// The address the link was sent to (shown in the copy, never logged).
  String get email => _authService.currentUser?.email ?? 'your email';

  // A calm inline status line (send result / "not yet" / offline).
  String? _statusMessage;
  String? get statusMessage => _statusMessage;

  /// Called from onViewModelReady: registers the lifecycle observer, closes
  /// immediately if already verified, else sends one fresh link + starts cooldown.
  Future<void> onReady() async {
    WidgetsBinding.instance.addObserver(this);
    if (!_authService.needsEmailVerification) {
      _navigationService.back(result: true);
      return;
    }
    await _sendEmail();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Auto-detect: they probably tapped the link in their mail app and came
    // back. Quietly re-check on resume.
    if (state == AppLifecycleState.resumed) _silentRecheck();
  }

  Future<void> _silentRecheck() async {
    try {
      if (await _authService.refreshEmailVerified()) {
        _analytics.logVerificationCompleted(context: source);
        _navigationService.back(result: true);
      }
    } catch (_) {
      // Offline / transient — ignore; the explicit "check again" button remains.
    }
  }

  Future<void> _sendEmail() async {
    setBusy(true);
    _statusMessage = null;
    notifyListeners();
    try {
      await _authService.sendVerificationEmail();
      _analytics.logVerificationEmailSent(context: source);
      _statusMessage = 'We sent a fresh link to your inbox.';
      _startCooldown();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        // Already sent recently — stay calm and still hold the cooldown.
        _statusMessage =
            "You've requested a few times — please check your inbox, or try again shortly.";
        _startCooldown();
      } else {
        _statusMessage =
            "We couldn't send the email just now. Please try again.";
      }
    } catch (e) {
      AppLog.error('VerifyEmailViewModel._sendEmail', e);
      _statusMessage = "You appear to be offline. Reconnect and tap Resend.";
    } finally {
      setBusy(false);
      notifyListeners();
    }
  }

  Future<void> resend() async {
    if (!canResend) return;
    await _sendEmail();
  }

  void _startCooldown() {
    _cooldown = _cooldownSeconds;
    notifyListeners();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _cooldown--;
      if (_cooldown <= 0) {
        _cooldown = 0;
        t.cancel();
      }
      notifyListeners();
    });
  }

  /// Reloads and, if verified, closes with success. Offline/errors show a calm
  /// retry line instead of crashing.
  Future<void> checkAgain() async {
    _statusMessage = null;
    setBusy(true);
    notifyListeners();
    try {
      if (await _authService.refreshEmailVerified()) {
        _analytics.logVerificationCompleted(context: source);
        _navigationService.back(result: true);
      } else {
        _statusMessage =
            'Not verified yet. Tap the link in your inbox, then try again.';
      }
    } catch (e) {
      AppLog.error('VerifyEmailViewModel.checkAgain', e);
      _statusMessage =
          "We couldn't check just now — check your connection and try again.";
    } finally {
      setBusy(false);
      notifyListeners();
    }
  }

  /// Leave without verifying — always allowed (non-blocking). Returns false.
  void back() => _navigationService.back(result: false);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }
}
