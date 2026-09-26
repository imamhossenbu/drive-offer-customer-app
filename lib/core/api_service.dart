import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'auth_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  ApiException(this.message, {this.statusCode, this.code});

  @override
  String toString() => message;
}

class CustomerApiService {
  static final CustomerApiService instance = CustomerApiService._internal();
  CustomerApiService._internal();

  String get _baseUrl => AuthStorage.getServerUrl();

  Map<String, String> _headers({bool withAuth = true}) {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth) {
      final token = AuthStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        map['Authorization'] = 'Bearer $token';
      }
    }
    return map;
  }

  Map<String, dynamic> _parse(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return body is Map<String, dynamic> ? body : {'data': body, 'success': true};
      }
      final msg = body['message'] ?? body['error'] ?? 'Request failed (${res.statusCode})';
      throw ApiException(msg.toString(), statusCode: res.statusCode, code: body['code']?.toString());
    } on FormatException {
      throw ApiException('Server returned an unexpected response format', statusCode: res.statusCode);
    }
  }

  // ── 1. Authentication & Registration ─────────────────────────────────────

  /// Multi-step registration with NID Front & Back files
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String pin,
    Uint8List? nidFrontBytes,
    String? nidFrontPath,
    Uint8List? nidBackBytes,
    String? nidBackPath,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/register');
    final req = http.MultipartRequest('POST', uri);

    req.fields['name'] = name.trim();
    req.fields['email'] = email.trim();
    req.fields['phone'] = phone.trim();
    req.fields['pin'] = pin.trim();

    if (nidFrontBytes != null) {
      req.files.add(http.MultipartFile.fromBytes(
        'nidFrontImage',
        nidFrontBytes,
        filename: 'nid_front.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
    } else if (nidFrontPath != null && nidFrontPath.isNotEmpty) {
      req.files.add(await http.MultipartFile.fromPath('nidFrontImage', nidFrontPath));
    }

    if (nidBackBytes != null) {
      req.files.add(http.MultipartFile.fromBytes(
        'nidBackImage',
        nidBackBytes,
        filename: 'nid_back.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
    } else if (nidBackPath != null && nidBackPath.isNotEmpty) {
      req.files.add(await http.MultipartFile.fromPath('nidBackImage', nidBackPath));
    }

    final streamedRes = await req.send();
    final res = await http.Response.fromStream(streamedRes);
    return _parse(res);
  }

  Future<Map<String, dynamic>> verifyRegistration({
    required String registrationId,
    required String code,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/register/verify'),
      headers: _headers(withAuth: false),
      body: jsonEncode({'registrationId': registrationId, 'code': code}),
    );
    final data = _parse(res);
    final payload = data['data'] ?? data;
    if (payload['accessToken'] != null) {
      await AuthStorage.saveTokens(
        accessToken: payload['accessToken'],
        refreshToken: payload['refreshToken'] ?? '',
      );
      if (payload['user'] != null) {
        final u = payload['user'];
        await AuthStorage.saveUser(
          id: u['id'] ?? u['_id'] ?? '',
          name: u['name'] ?? '',
          email: u['email'] ?? '',
          phone: u['phone'] ?? '',
          kycStatus: u['kycStatus'] ?? 'VERIFIED',
        );
      }
    }
    return data;
  }

  Future<Map<String, dynamic>> resendRegistrationOtp({
    required String registrationId,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/register/resend'),
      headers: _headers(withAuth: false),
      body: jsonEncode({'registrationId': registrationId}),
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> login({
    required String emailOrPhone,
    required String pin,
    String? deviceId,
    String? deviceName,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: _headers(withAuth: false),
      body: jsonEncode({
        'email': emailOrPhone.trim(),
        'pin': pin.trim(),
        'deviceId': deviceId ?? 'device-${DateTime.now().millisecondsSinceEpoch}',
        'deviceName': deviceName ?? 'Mobile App',
        'platform': Platform.isAndroid ? 'ANDROID' : (Platform.isIOS ? 'IOS' : 'OTHER'),
        'appVersion': '1.0.0',
      }),
    );
    final data = _parse(res);
    final payload = data['data'] ?? data;
    if (payload['accessToken'] != null) {
      await AuthStorage.saveTokens(
        accessToken: payload['accessToken'],
        refreshToken: payload['refreshToken'] ?? '',
      );
      if (payload['user'] != null) {
        final u = payload['user'];
        await AuthStorage.saveUser(
          id: u['id'] ?? u['_id'] ?? '',
          name: u['name'] ?? '',
          email: u['email'] ?? '',
          phone: u['phone'] ?? '',
          kycStatus: u['kycStatus'] ?? 'UNVERIFIED',
        );
      }
    }
    return data;
  }

  Future<Map<String, dynamic>> forgotPin({required String email}) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/forgot-pin'),
      headers: _headers(withAuth: false),
      body: jsonEncode({'email': email.trim()}),
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> verifyForgotPin({
    required String verificationId,
    required String code,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/forgot-pin/verify'),
      headers: _headers(withAuth: false),
      body: jsonEncode({'verificationId': verificationId, 'code': code}),
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> resetPin({
    required String resetToken,
    required String newPin,
    required String confirmPin,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/reset-pin'),
      headers: _headers(withAuth: false),
      body: jsonEncode({
        'resetToken': resetToken,
        'newPin': newPin,
        'confirmPin': confirmPin,
      }),
    );
    return _parse(res);
  }

  // ── 2. Profile & KYC ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getMe() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/users/me'),
      headers: _headers(),
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> updateMe({String? name, String? phone}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;

    final res = await http.patch(
      Uri.parse('$_baseUrl/users/me'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> changePin({
    required String currentPin,
    required String newPin,
    required String confirmPin,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/users/me/change-pin'),
      headers: _headers(),
      body: jsonEncode({
        'currentPin': currentPin,
        'newPin': newPin,
        'confirmPin': confirmPin,
      }),
    );
    return _parse(res);
  }

  // ── 3. Offers & Operators ────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDriveOffers({String? operator, String? category}) async {
    final params = <String, String>{};
    if (operator != null && operator != 'ALL') params['operator'] = operator;
    if (category != null && category != 'ALL') params['category'] = category;

    final uri = Uri.parse('$_baseUrl/drive-offers').replace(queryParameters: params.isEmpty ? null : params);
    final res = await http.get(uri, headers: _headers(withAuth: false));
    return _parse(res);
  }

  Future<Map<String, dynamic>> getRegularOffers({String? operator, String? category}) async {
    final params = <String, String>{};
    if (operator != null && operator != 'ALL') params['operator'] = operator;
    if (category != null && category != 'ALL') params['category'] = category;

    final uri = Uri.parse('$_baseUrl/offers').replace(queryParameters: params.isEmpty ? null : params);
    final res = await http.get(uri, headers: _headers(withAuth: false));
    return _parse(res);
  }

  Future<Map<String, dynamic>> getOperators() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/operators'),
      headers: _headers(withAuth: false),
    );
    return _parse(res);
  }

  // ── 4. Orders ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createOrder({
    required String offerId,
    required String offerType, // "DRIVE" or "REGULAR" or "NORMAL"
    required String recipientPhone,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/orders'),
      headers: _headers(),
      body: jsonEncode({
        'offerId': offerId,
        'offerType': offerType,
        'phone': recipientPhone.trim(),
      }),
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> getOrders({int page = 1, int limit = 20}) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/orders?page=$page&limit=$limit'),
      headers: _headers(),
    );
    return _parse(res);
  }

  // ── 5. Wallet & Add Money (Top-Up) ───────────────────────────────────────

  Future<Map<String, dynamic>> getPaymentMethods() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/payment-methods'),
      headers: _headers(withAuth: false),
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> createTopUp({
    required String provider, // "BKASH", "NAGAD", "ROCKET", "UPAY"
    required double amount,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/wallet/topups'),
      headers: _headers(),
      body: jsonEncode({
        'provider': provider.toUpperCase(),
        'amount': amount,
      }),
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> verifyTopUp({
    required String topUpId,
    required String transactionId,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/wallet/topups/$topUpId/verify'),
      headers: _headers(),
      body: jsonEncode({'transactionId': transactionId.trim()}),
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> getWalletTransactions({int page = 1, int limit = 20}) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/wallet/transactions?page=$page&limit=$limit'),
      headers: _headers(),
    );
    return _parse(res);
  }

  // ── 6. Notifications ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getNotifications() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/notifications'),
      headers: _headers(),
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> markNotificationRead(String id) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/notifications/$id/read'),
      headers: _headers(),
    );
    return _parse(res);
  }
}
