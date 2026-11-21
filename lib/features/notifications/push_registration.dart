import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_ssas_rrhh/features/auth/services/staff_api.dart';

/// The native app enables push only when all Firebase options are supplied.
/// This keeps local and web builds usable before Firebase is provisioned.
class PushRegistration {
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');

  StreamSubscription<String>? _registration;
  String? _installationId;
  bool _starting = false;

  static bool get configured =>
      !kIsWeb &&
      _apiKey.isNotEmpty &&
      _appId.isNotEmpty &&
      _senderId.isNotEmpty &&
      _projectId.isNotEmpty;

  Future<void> start(StaffApi api) async {
    if (!configured || _starting || _registration != null) return;
    _starting = true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: _apiKey,
            appId: _appId,
            messagingSenderId: _senderId,
            projectId: _projectId,
          ),
        );
      }
      final messaging = FirebaseMessaging.instance;
      final permission = await messaging.requestPermission();
      if (permission.authorizationStatus != AuthorizationStatus.authorized &&
          permission.authorizationStatus != AuthorizationStatus.provisional) {
        return;
      }
      _registration = messaging.onRegistered.listen((installationId) async {
        try {
          await api.registerDevice(installationId);
          final previousId = _installationId;
          _installationId = installationId;
          if (previousId != null && previousId != installationId) {
            await api.unregisterDevice(previousId);
          }
        } on Exception {
          // A later session refresh retries registration.
        }
      });
      await messaging.register();
    } on Exception {
      await _registration?.cancel();
      _registration = null;
      // Firebase may be unavailable on a development device.
    } finally {
      _starting = false;
    }
  }

  Future<void> stop(StaffApi api) async {
    await _registration?.cancel();
    _registration = null;
    if (_installationId != null) {
      try {
        await api.unregisterDevice(_installationId!);
      } on Exception {
        /* Offline logout. */
      }
      _installationId = null;
    }
    if (configured && Firebase.apps.isNotEmpty) {
      try {
        await FirebaseMessaging.instance.unregister();
      } on Exception {
        // Local logout still completes when Firebase is unreachable.
      }
    }
  }

  void dispose() => _registration?.cancel();
}
