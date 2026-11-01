import 'api_client.dart';
import 'secure_storage_service.dart';

class UserModel {
  final int id;
  final String email;
  final String fullName;
  final String plan;
  final int minutesUsed;
  final int minutesLimit;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.plan,
    required this.minutesUsed,
    required this.minutesLimit,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 1,
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? 'Team Member',
      plan: json['plan'] ?? 'Pro',
      minutesUsed: json['minutes_used'] ?? 0,
      minutesLimit: json['minutes_limit'] ?? 500,
    );
  }
}

class AuthService {
  static Future<UserModel> login({required String email, required String password}) async {
    final response = await ApiClient.post('/auth/login', body: {
      'email': email.trim(),
      'password': password,
    });

    final token = response['access_token'] as String;
    final userName = response['user_name'] as String? ?? 'Team Member';
    final userPlan = response['plan'] as String? ?? 'Pro';

    // Store token securely first so profile fetch has auth header
    await SecureStorageService.saveSession(
      token: token,
      email: email.trim(),
      name: userName,
      plan: userPlan,
    );

    // Fetch full profile
    final profileData = await ApiClient.get('/users/me');
    final user = UserModel.fromJson(profileData as Map<String, dynamic>);

    await SecureStorageService.saveSession(
      token: token,
      email: user.email,
      name: user.fullName,
      plan: user.plan,
      userId: user.id,
    );

    return user;
  }

  static Future<UserModel> loginAsGuest() async {
    return await login(email: 'emily@example.com', password: 'password123');
  }

  static Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await ApiClient.post('/auth/register', body: {
      'email': email.trim(),
      'password': password,
      'full_name': fullName.trim(),
    });

    final token = response['access_token'] as String;
    final userName = response['user_name'] as String? ?? fullName;
    final userPlan = response['plan'] as String? ?? 'Team';

    await SecureStorageService.saveSession(
      token: token,
      email: email.trim(),
      name: userName,
      plan: userPlan,
    );

    final profileData = await ApiClient.get('/users/me');
    final user = UserModel.fromJson(profileData as Map<String, dynamic>);
    return user;
  }

  static Future<UserModel?> getCurrentUser() async {
    final hasSession = await SecureStorageService.hasValidSession();
    if (!hasSession) return null;

    try {
      final profileData = await ApiClient.get('/users/me');
      return UserModel.fromJson(profileData as Map<String, dynamic>);
    } catch (_) {
      final email = await SecureStorageService.getUserEmail();
      final name = await SecureStorageService.getUserName();
      final plan = await SecureStorageService.getUserPlan();
      final id = await SecureStorageService.getUserId();
      if (email != null) {
        return UserModel(
          id: id ?? 1,
          email: email,
          fullName: name ?? 'Team Member',
          plan: plan ?? 'Pro',
          minutesUsed: 0,
          minutesLimit: 500,
        );
      }
      return null;
    }
  }

  static Future<void> logout() async {
    await SecureStorageService.clearSession();
  }
}

