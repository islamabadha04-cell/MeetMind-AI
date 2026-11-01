import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyToken = 'meetmind_jwt_token';
  static const _keyUserEmail = 'meetmind_user_email';
  static const _keyUserName = 'meetmind_user_name';
  static const _keyUserPlan = 'meetmind_user_plan';
  static const _keyUserId = 'meetmind_user_id';
  static const _keyCustomApiUrl = 'meetmind_custom_api_url';

  static Future<void> saveSession({
    required String token,
    required String email,
    required String name,
    required String plan,
    int? userId,
  }) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyUserEmail, value: email);
    await _storage.write(key: _keyUserName, value: name);
    await _storage.write(key: _keyUserPlan, value: plan);
    if (userId != null) {
      await _storage.write(key: _keyUserId, value: userId.toString());
    }
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  static Future<String?> getUserEmail() async {
    return await _storage.read(key: _keyUserEmail);
  }

  static Future<String?> getUserName() async {
    return await _storage.read(key: _keyUserName);
  }

  static Future<String?> getUserPlan() async {
    return await _storage.read(key: _keyUserPlan);
  }

  static Future<int?> getUserId() async {
    final str = await _storage.read(key: _keyUserId);
    return str != null ? int.tryParse(str) : null;
  }

  static Future<void> saveCustomApiUrl(String url) async {
    await _storage.write(key: _keyCustomApiUrl, value: url);
  }

  static Future<String?> getCustomApiUrl() async {
    return await _storage.read(key: _keyCustomApiUrl);
  }

  static Future<void> clearSession() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUserEmail);
    await _storage.delete(key: _keyUserName);
    await _storage.delete(key: _keyUserPlan);
    await _storage.delete(key: _keyUserId);
  }

  static Future<bool> hasValidSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
