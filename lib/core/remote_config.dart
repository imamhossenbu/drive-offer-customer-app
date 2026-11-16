import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Remote app config hosted as a static JSON file (GitHub), independent of the
/// backend. It lets us:
///  * move the backend to a new host without shipping a new APK (`apiBaseUrl`)
///  * announce app updates even while the backend is down (`customer`/`admin`)
///
/// File format (app-config.json):
/// {
///   "apiBaseUrl": "https://.../api/v1",
///   "customer": {"latestVersion": "1.1.0", "buildNumber": 11,
///                "downloadUrl": "https://.../app.apk", "forceUpdate": false,
///                "releaseNotes": "..."},
///   "admin": { ...same shape... }
/// }
class RemoteConfig {
  RemoteConfig._();

  static const String configUrl =
      'https://raw.githubusercontent.com/imamhossenbu/drive-offer-customer-app/main/app-config.json';

  static const String _kApiBaseUrl = 'remote_api_base_url';
  static const String _kRawJson = 'remote_config_json';

  static Map<String, dynamic> _data = {};

  /// Loads the last cached config, then tries to fetch a fresh one.
  /// Never throws; waits at most [timeout] so app start is not blocked.
  static Future<void> init({Duration timeout = const Duration(seconds: 3)}) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_kRawJson);
    if (cached != null) {
      try {
        _data = Map<String, dynamic>.from(jsonDecode(cached) as Map);
      } catch (_) {}
    }
    try {
      await refresh().timeout(timeout);
    } catch (_) {
      // Offline / slow network: keep using the cached config.
    }
  }

  static Future<void> refresh() async {
    try {
      final res = await http
          .get(Uri.parse(configUrl), headers: {'Cache-Control': 'no-cache'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return;
      final decoded = jsonDecode(res.body);
      if (decoded is! Map) return;
      _data = Map<String, dynamic>.from(decoded);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kRawJson, res.body);
      final url = apiBaseUrl;
      if (url != null) {
        await prefs.setString(_kApiBaseUrl, url);
      }
    } catch (e) {
      debugPrint('RemoteConfig refresh failed: $e');
    }
  }

  /// Backend base URL from the remote config, if it is a valid http(s) URL.
  static String? get apiBaseUrl {
    final v = _data['apiBaseUrl']?.toString().trim().replaceAll(RegExp(r'/+$'), '');
    if (v == null || v.isEmpty) return null;
    final uri = Uri.tryParse(v);
    if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http') || uri.host.isEmpty) {
      return null;
    }
    return v;
  }

  /// Cached remote API URL readable synchronously (also from other isolates
  /// via SharedPreferences key [cachedApiBaseUrlKey]).
  static String get cachedApiBaseUrlKey => _kApiBaseUrl;

  /// Version info for an app section ("customer" or "admin"), or empty map.
  static Map<String, dynamic> appVersion(String app) {
    final v = _data[app];
    return v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
  }
}
