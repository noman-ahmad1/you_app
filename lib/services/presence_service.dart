import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:you_app/app/app.locator.dart';
import 'package:you_app/services/auth_service.dart';
import 'package:you_app/services/base/app_log.dart';
import 'package:you_app/services/base/firestore_base.dart';

/// Records when a volunteer's app was last alive (`users/{uid}.lastSeen`).
///
/// **This does NOT decide who appears in discovery.** A volunteer stays listed
/// until they switch their own toggle off — deliberately. With a small volunteer
/// pool, auto-expiring anyone who hasn't opened the app in a while would empty
/// the listeners list, and a user who finds NO listeners has no path to help at
/// all. That's a worse failure than a listener who's slow to reply.
///
/// So this service just keeps an honest liveness trail:
///   • the admin panel can show "last seen 3 days ago" and nudge dormant
///     volunteers, which is the *right* fix for the problem at this size;
///   • when the pool is large enough to afford being strict, staleness expiry
///     can be turned on server-side by setting
///     `app_settings/global_config.presence_expiry_enabled = true` — no app
///     release needed, because `sweepStalePresence` flips `availabilityStatus`,
///     which is what discovery already queries.
class PresenceService with FirestoreServiceMixin, WidgetsBindingObserver {
  final _authService = locator<AuthenticationService>();

  /// Cheap: one write every few minutes, and only for volunteers who have
  /// actually toggled themselves online.
  static const Duration _heartbeatInterval = Duration(minutes: 5);

  Timer? _timer;

  /// The uid we're currently beating for. Guards against the re-entrancy that
  /// bit MonetizationService: AuthenticationService fires notifyListeners on
  /// every user-doc snapshot, and our own heartbeat write causes a snapshot.
  /// Without this, each beat would restart the timer — a tightening loop.
  String? _trackedUid;

  PresenceService() {
    WidgetsBinding.instance.addObserver(this);
    _authService.addListener(_onAuthChange);
    _onAuthChange();
  }

  void _onAuthChange() {
    final user = _authService.currentUser;

    // Only volunteers have availability. Everyone else: nothing to track.
    if (user == null || !user.isVolunteer) {
      if (_trackedUid != null) _stop();
      return;
    }
    if (_trackedUid == user.uid) return; // already beating for this volunteer
    _trackedUid = user.uid;
    _start();
  }

  void _start() {
    _timer?.cancel();
    _beat();
    _timer = Timer.periodic(_heartbeatInterval, (_) => _beat());
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _trackedUid = null;
  }

  /// Stamps `lastSeen`, but only while the volunteer's toggle is on — a volunteer
  /// who has switched themselves off isn't "available", so there's nothing to
  /// record.
  Future<void> _beat() async {
    final user = _authService.currentUser;
    if (user == null || !user.isVolunteer || !user.isOnline) return;

    try {
      await db.collection('users').doc(user.uid).update({
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Never surface this — it's background bookkeeping, and a missed beat has
      // no user-visible effect today.
      AppLog.error('PresenceService.beat', e);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_trackedUid != null) _start();
      case AppLifecycleState.paused:
        _beat(); // one last stamp on the way out
        _timer?.cancel();
        _timer = null;
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authService.removeListener(_onAuthChange);
    _stop();
  }
}
