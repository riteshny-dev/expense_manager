import 'dart:async';
import 'package:flutter/material.dart';
import '../services/security_logger.dart';

class AppLifecycleService extends ChangeNotifier {
  static const Duration _lockTimeout = Duration(minutes: 5);
  Timer? _lockTimer;
  bool _isLocked = false;
  final Function() _onLock;

  AppLifecycleService(this._onLock);

  bool get isLocked => _isLocked;

  void startTimer() {
    _lockTimer?.cancel();
    _lockTimer = Timer(_lockTimeout, _lockApp);
  }

  void resetTimer() {
    if (!_isLocked) {
      startTimer();
    }
  }

  void _lockApp() async {
    _isLocked = true;
    await SecurityLogger.log(
      'APP_AUTO_LOCKED',
      details: {
        'reason': 'inactivity',
        'duration': _lockTimeout.inMinutes,
      },
    );
    _onLock();
    notifyListeners();
  }

  void unlock() {
    _isLocked = false;
    startTimer();
    notifyListeners();
  }

  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }
}