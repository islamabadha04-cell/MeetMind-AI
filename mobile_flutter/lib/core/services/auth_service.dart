import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_client.dart';
import 'secure_storage_service.dart';

class UserModel {
  final int id;
  final String email;
  final String fullName;
  final String plan;
  final int minutesUsed;
  final int minutesLimit;
  final String? firebaseUid;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.plan,
    required this.minutesUsed,
    required this.minutesLimit,
    this.firebaseUid,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 1,
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? 'Team Member',
      plan: json['plan'] ?? 'Pro',
      minutesUsed: json['minutes_used'] ?? 0,
      minutesLimit: json['minutes_limit'] ?? 500,
      firebaseUid: json['firebase_uid'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class AuthService {
  /// Sign in with Email and Password.
  /// Attempts native Firebase Auth first, falling back to direct FastAPI JWT backend.
  static Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      final idToken = await userCredential.user?.getIdToken();
      if (idToken != null) {
        final displayName = userCredential.user?.displayName ?? 'Team Member';
        await SecureStorageService.saveSession(
          token: idToken,
          email: cleanEmail,
          name: displayName,
          plan: 'Pro',
        );

        final profileData = await ApiClient.get('/users/me');
        final user = UserModel.fromJson(profileData as Map<String, dynamic>);

        await SecureStorageService.saveSession(
          token: idToken,
          email: user.email,
          name: user.fullName,
          plan: user.plan,
          userId: user.id,
        );
        return user;
      }
    } catch (firebaseErr) {
      debugPrint('Firebase sign-in notice / falling back to direct backend auth: $firebaseErr');
    }

    // Direct FastAPI backend authentication fallback
    final response = await ApiClient.post('/auth/login', body: {
      'email': cleanEmail,
      'password': password,
    });

    final token = response['access_token'] as String;
    final userName = response['user_name'] as String? ?? 'Team Member';
    final userPlan = response['plan'] as String? ?? 'Pro';

    await SecureStorageService.saveSession(
      token: token,
      email: cleanEmail,
      name: userName,
      plan: userPlan,
    );

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

  /// Sign in with Google using native credential picker & Firebase Auth.
  static Future<UserModel> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
    );

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google Sign-In was cancelled by the user.');
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    final firebaseUser = userCredential.user;
    if (firebaseUser == null) {
      throw Exception('Firebase authentication returned an empty user profile.');
    }

    final idToken = await firebaseUser.getIdToken();
    if (idToken == null) {
      throw Exception('Failed to obtain Firebase ID token.');
    }

    final email = firebaseUser.email ?? googleUser.email;
    final name = firebaseUser.displayName ?? googleUser.displayName ?? 'Google User';

    await SecureStorageService.saveSession(
      token: idToken,
      email: email,
      name: name,
      plan: 'Pro',
    );

    final profileData = await ApiClient.get('/users/me');
    final user = UserModel.fromJson(profileData as Map<String, dynamic>);

    await SecureStorageService.saveSession(
      token: idToken,
      email: user.email,
      name: user.fullName,
      plan: user.plan,
      userId: user.id,
    );

    return user;
  }

  /// Guest demo login using seed user Emily Watson
  static Future<UserModel> loginAsGuest() async {
    return await login(email: 'emily@example.com', password: 'password123');
  }

  /// Register new user account.
  /// Attempts native Firebase Auth registration first, then provisions backend database.
  static Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final cleanEmail = email.trim();
    final cleanName = fullName.trim();

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      await userCredential.user?.updateDisplayName(cleanName);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken != null) {
        await SecureStorageService.saveSession(
          token: idToken,
          email: cleanEmail,
          name: cleanName,
          plan: 'Pro',
        );

        final profileData = await ApiClient.get('/users/me');
        final user = UserModel.fromJson(profileData as Map<String, dynamic>);

        await SecureStorageService.saveSession(
          token: idToken,
          email: user.email,
          name: user.fullName,
          plan: user.plan,
          userId: user.id,
        );
        return user;
      }
    } catch (firebaseErr) {
      debugPrint('Firebase registration notice / falling back to direct backend auth: $firebaseErr');
    }

    // Direct FastAPI backend registration fallback
    final response = await ApiClient.post('/auth/register', body: {
      'email': cleanEmail,
      'password': password,
      'full_name': cleanName,
    });

    final token = response['access_token'] as String;
    final userName = response['user_name'] as String? ?? cleanName;
    final userPlan = response['plan'] as String? ?? 'Team';

    await SecureStorageService.saveSession(
      token: token,
      email: cleanEmail,
      name: userName,
      plan: userPlan,
    );

    final profileData = await ApiClient.get('/users/me');
    final user = UserModel.fromJson(profileData as Map<String, dynamic>);
    return user;
  }

  /// Retrieve current active user session.
  static Future<UserModel?> getCurrentUser() async {
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        final idToken = await fbUser.getIdToken();
        if (idToken != null) {
          await SecureStorageService.saveSession(
            token: idToken,
            email: fbUser.email ?? '',
            name: fbUser.displayName ?? 'Team Member',
            plan: 'Pro',
          );
        }
      }
    } catch (_) {}

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

  /// Sign out across Firebase, Google Sign-In, and local Secure Keystore.
  static Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await SecureStorageService.clearSession();
  }
}
