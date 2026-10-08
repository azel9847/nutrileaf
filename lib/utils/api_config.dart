import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration for API endpoints and third-party services.
///
/// ## Why `localhost` fails on mobile devices
/// On a physical Android/iOS device, `localhost` (127.0.0.1) refers to the
/// **device itself**, not your development machine. To reach the FastAPI server
/// running on your computer you must use:
///
/// | Environment            | Address to use              |
/// |------------------------|------------------------------|
/// | Web (Chrome)           | `localhost` (same machine)   |
/// | Android Emulator       | `10.0.2.2` (maps to host)    |
/// | iOS Simulator          | `localhost` (same machine)   |
/// | Physical Android/iOS   | Your PC's LAN IP (see below) |
///
/// ### Finding your PC's LAN IP
/// - **Windows**: run `ipconfig` → look for "IPv4 Address" (e.g. 192.168.1.5)
/// - **macOS/Linux**: run `ifconfig` or `ip a`
///
/// Set [_physicalDeviceIp] to that value when running on a real device.
class ApiConfig {
  // ── 🌐  Production backend (Google Cloud Run) ──────────────────────────────
  /// Live Cloud Run endpoint.  When non-empty this takes priority over every
  /// local-dev address below — no trailing slash.
  /// Clear this string (set to '') to fall back to local-dev routing.
  static const String _productionUrl =
      'https://nutrileaf-backend-502370293163.asia-southeast1.run.app';
  // ──────────────────────────────────────────────────────────────────────────

  // ── ✏️  Local dev — only used when _productionUrl is empty ────────────────
  /// Your development machine's LAN IP address.
  /// Used only when [_usePhysicalDeviceIp] is true.
  static const String _physicalDeviceIp = '192.168.0.71'; // ← your PC's LAN IP

  /// Set to `true` when running on a **physical** Android or iOS device.
  /// Set to `false` when using an emulator/simulator or the web.
  ///
  /// Quick reference:
  ///   • Web (Chrome)         → false  (uses localhost automatically)
  ///   • Android Emulator     → false  (uses 10.0.2.2 automatically)
  ///   • Physical Android/iOS → TRUE   (uses _physicalDeviceIp above)
  static const bool _usePhysicalDeviceIp = false;
  // ──────────────────────────────────────────────────────────────────────────

  static const int _port = 8000;

  /// Resolves the correct base URL for the current runtime environment.
  ///
  /// Priority:
  ///   1. [_productionUrl]    — Cloud Run (when non-empty)
  ///   2. localhost           — Web / browser
  ///   3. [_physicalDeviceIp] — physical Android/iOS device over LAN
  ///   4. 10.0.2.2            — Android Emulator (host alias)
  ///   5. localhost           — iOS Simulator / Desktop fallback
  static String get apiBaseUrl {
    // 1. Production override — always wins when set.
    if (_productionUrl.isNotEmpty) return _productionUrl;

    if (kIsWeb) {
      // Browser → same machine, localhost works fine.
      return 'http://localhost:$_port';
    }

    if (_usePhysicalDeviceIp) {
      // Physical device → must reach the host over LAN.
      return 'http://$_physicalDeviceIp:$_port';
    }

    if (!kIsWeb && _isAndroid()) {
      // Android Emulator → 10.0.2.2 is a special alias for the host machine.
      return 'http://10.0.2.2:$_port';
    }

    // iOS Simulator / Desktop / Web → localhost refers to the same machine.
    return 'http://localhost:$_port';
  }

  /// Safe Android platform check (avoids dart:io import errors on Web).
  static bool _isAndroid() {
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  // ── Supabase credentials (loaded from bundled .env asset) ─────────────────
  /// The Supabase project URL — read from the `.env` file at runtime.
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? '';

  /// The Supabase anon (public) key — read from the `.env` file at runtime.
  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // ── FastAPI endpoint URLs ──────────────────────────────────────────────────
  static String get healthUrl   => '$apiBaseUrl/api/health';
  static String get predictUrl  => '$apiBaseUrl/predict';
}
