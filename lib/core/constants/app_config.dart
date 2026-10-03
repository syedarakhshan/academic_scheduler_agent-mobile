import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Central place for environment / backend configuration.
///
/// ── IMPORTANT — read this before running ──────────────────────────────
/// You chose to run the backend on localhost for now and test on an
/// emulator. "localhost" means something different depending on where
/// the code runs:
///
///   • Android emulator → the emulator has its own virtual network, so
///     it can't see your machine's "localhost". Google reserves the
///     special address 10.0.2.2 to mean "the host machine's localhost".
///   • iOS simulator     → shares the Mac's network, so "localhost"
///     works as-is.
///   • Physical phone     → neither works. Use your computer's LAN IP
///     (e.g. 192.168.1.23) and make sure the phone is on the same
///     Wi-Fi, and that backend/server.js's CORS `origin` allow-list
///     (or just disable CORS checks for the mobile client, since native
///     apps don't send an Origin header anyway) doesn't block it.
///
/// This file auto-picks the right host for the two emulator cases. For
/// a physical device, set [_lanOverrideIp] below.
class AppConfig {
  AppConfig._();

  /// Your backend is deployed on Render, so the app talks to that
  /// directly — no localhost/LAN-IP/firewall setup needed anymore.
  /// Set this to false to go back to hitting your local backend
  /// instead (e.g. while testing a change that isn't deployed yet).
  static const bool useDeployedBackend = true;
  static const String deployedApiBaseUrl = 'https://timecade.onrender.com/api';

  /// Backend port from backend/server.js (process.env.PORT || 5000).
  static const int backendPort = 5000;

  /// Set this to your machine's LAN IP (e.g. '192.168.1.23') if you're
  /// testing on a physical phone against your LOCAL backend instead
  /// of the deployed one above. Leave null to use the automatic
  /// emulator/simulator detection.
  static const String? _lanOverrideIp = '192.168.1.6';

  static String get _host {
    if (_lanOverrideIp != null) return _lanOverrideIp!;
    if (kIsWeb) return 'localhost';
    if (Platform.isAndroid) return '10.0.2.2'; // Android emulator -> host machine
    return 'localhost'; // iOS simulator / others
  }

  /// Same shape as REACT_APP_API_URL in the web app's api.js.
  static String get apiBaseUrl =>
      useDeployedBackend ? deployedApiBaseUrl : 'http://$_host:$backendPort/api';

  /// Mirrors api.js: 60s timeout to tolerate a cold-started DB (e.g. Neon).
  static const Duration requestTimeout = Duration(seconds: 60);
}
