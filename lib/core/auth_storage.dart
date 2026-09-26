import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class AuthStorage {
  static SharedPreferences? _prefs;

  static const _keyAccessToken = 'customer_access_token';
  static const _keyRefreshToken = 'customer_refresh_token';
  static const _keyUserId = 'customer_user_id';
  static const _keyUserName = 'customer_user_name';
  static const _keyUserEmail = 'customer_user_email';
  static const _keyUserPhone = 'customer_user_phone';
  static const _keyKycStatus = 'customer_kyc_status';
  static const _keyServerUrl = 'customer_server_url';
  static const _keyLanguage = 'customer_language';
  static const _keySoundEnabled = 'customer_sound_enabled';

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Token management
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await init();
    await _prefs!.setString(_keyAccessToken, accessToken);
    await _prefs!.setString(_keyRefreshToken, refreshToken);
  }

  static String? getAccessToken() => _prefs?.getString(_keyAccessToken);
  static String? getRefreshToken() => _prefs?.getString(_keyRefreshToken);
  static bool get isLoggedIn => getAccessToken() != null && getAccessToken()!.isNotEmpty;

  // User details
  static Future<void> saveUser({
    required String id,
    required String name,
    required String email,
    required String phone,
    String? kycStatus,
  }) async {
    await init();
    await _prefs!.setString(_keyUserId, id);
    await _prefs!.setString(_keyUserName, name);
    await _prefs!.setString(_keyUserEmail, email);
    await _prefs!.setString(_keyUserPhone, phone);
    if (kycStatus != null) {
      await _prefs!.setString(_keyKycStatus, kycStatus);
    }
  }

  static String getUserId() => _prefs?.getString(_keyUserId) ?? '';
  static String getUserName() => _prefs?.getString(_keyUserName) ?? 'Customer';
  static String getUserEmail() => _prefs?.getString(_keyUserEmail) ?? '';
  static String getUserPhone() => _prefs?.getString(_keyUserPhone) ?? '';
  static String getKycStatus() => _prefs?.getString(_keyKycStatus) ?? 'UNVERIFIED';

  // Server URL
  static Future<void> setServerUrl(String url) async {
    await init();
    await _prefs!.setString(_keyServerUrl, url.trim().replaceAll(RegExp(r'/+$'), ''));
  }

  static String getServerUrl() {
    return _prefs?.getString(_keyServerUrl) ?? AppConstants.defaultBaseUrl;
  }

  // Language & Sound
  static String getLanguage() => _prefs?.getString(_keyLanguage) ?? 'bn';
  static Future<void> setLanguage(String lang) async {
    await init();
    await _prefs!.setString(_keyLanguage, lang);
  }

  static bool isSoundEnabled() => _prefs?.getBool(_keySoundEnabled) ?? true;
  static Future<void> setSoundEnabled(bool enabled) async {
    await init();
    await _prefs!.setBool(_keySoundEnabled, enabled);
  }

  // Clear Session & Auth
  static Future<void> clearSession() async {
    await init();
    await _prefs!.remove(_keyAccessToken);
    await _prefs!.remove(_keyRefreshToken);
    await _prefs!.remove(_keyUserId);
    await _prefs!.remove(_keyUserName);
    await _prefs!.remove(_keyUserEmail);
    await _prefs!.remove(_keyUserPhone);
    await _prefs!.remove(_keyKycStatus);
  }

  static Future<void> clearAuth() => clearSession();
}
