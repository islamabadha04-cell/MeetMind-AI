import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meetmind_mobile/main.dart';
import 'package:meetmind_mobile/firebase_options.dart';
import 'package:meetmind_mobile/core/localization/app_strings.dart';
import 'package:meetmind_mobile/core/localization/language_provider.dart';
import 'package:meetmind_mobile/core/theme/app_theme.dart';
import 'package:meetmind_mobile/models/vault_recording_model.dart';
import 'package:meetmind_mobile/models/meeting_detail_model.dart';
import 'package:meetmind_mobile/models/task_model.dart';
import 'package:meetmind_mobile/models/workspace_model.dart';
import 'package:meetmind_mobile/core/services/auth_service.dart';
import 'package:meetmind_mobile/providers/auth_provider.dart';
import 'package:meetmind_mobile/screens/login_screen.dart';
import 'package:meetmind_mobile/screens/dashboard_screen.dart';
import 'package:meetmind_mobile/screens/meetings_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.enableGoogleFonts = false;
  });

  group('MeetMind AI Mobile Unit & Widget Test Suite', () {
    test('1. AppStrings & Multilingual Localization dictionary', () {
      expect(AppStrings.get('app_name', AppLanguage.english), 'MeetMind AI');
      expect(AppStrings.get('app_name', AppLanguage.urdu), 'میٹ مائنڈ اے آئی');
      expect(AppStrings.get('app_name', AppLanguage.romanUrdu), 'MeetMind AI');

      expect(AppStrings.get('vault_title', AppLanguage.urdu), 'آف لائن آڈیو والٹ');
      expect(AppStrings.get('btn_start_recording', AppLanguage.romanUrdu), 'Recording shuru karein');
      expect(AppStrings.get('status_synced', AppLanguage.english), 'Synced with Cloud');
    });

    test('2. AppTheme Light & Dark Material 3 Palette', () {
      final lightTheme = AppTheme.getLightTheme(AppLanguage.english);
      expect(lightTheme.useMaterial3, isTrue);
      expect(lightTheme.brightness, Brightness.light);

      final darkTheme = AppTheme.getDarkTheme(AppLanguage.english);
      expect(darkTheme.brightness, Brightness.dark);

      final urduTheme = AppTheme.getLightTheme(AppLanguage.urdu);
      expect(urduTheme.brightness, Brightness.light);
    });

    test('3. VaultRecordingModel Serialization & Integrity Checksums', () {
      final now = DateTime.now();
      final rec = VaultRecordingModel(
        id: 'rec-test-123',
        title: 'Q4 Budget Review',
        filePath: '/data/recordings/test.m4a',
        fileSizeBytes: 204800,
        durationSeconds: 120,
        sha256Checksum: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        createdAt: now,
        syncState: VaultSyncState.localOnly,
        idempotencyKey: 'rec-test-123',
      );

      final map = rec.toMap();
      expect(map['id'], 'rec-test-123');
      expect(map['title'], 'Q4 Budget Review');
      expect(map['sync_state'], 'localOnly');

      final parsed = VaultRecordingModel.fromMap(map);
      expect(parsed.id, rec.id);
      expect(parsed.durationSeconds, 120);
      expect(parsed.syncState, VaultSyncState.localOnly);

      final synced = parsed.copyWith(syncState: VaultSyncState.synced, remoteMeetingId: 42);
      expect(synced.syncState, VaultSyncState.synced);
      expect(synced.remoteMeetingId, 42);
    });

    test('4. MeetingDetailModel & Transcript Parsing', () {
      final json = {
        'id': 10,
        'title': 'Sprint 15 Kickoff',
        'meeting_date': 'Today',
        'duration_seconds': 1800,
        'category': 'Engineering',
        'executive_summary': 'Reviewed low latency audio pipeline.',
        'urdu_summary': 'آڈیو پائپ لائن کا تفصیلی جائزہ لیا گیا۔',
        'roman_urdu_summary': 'Audio pipeline ka tafseeli review kiya gaya.',
        'decisions': ['Approved AAC-LC 128kbps encoder'],
        'action_items': ['Deploy to staging - Hasnain Ali'],
        'risks': ['Network dropouts during live sync'],
        'transcript_turns': [
          {'speaker': 'Emily', 'timestamp': '00:15', 'text': 'Let us start the sprint sync.'},
          {'speaker': 'Hasnain', 'timestamp': '00:30', 'text': 'Audio recording is active.'}
        ]
      };

      final meeting = MeetingDetailModel.fromJson(json);
      expect(meeting.id, 10);
      expect(meeting.decisions.length, 1);
      expect(meeting.transcript.length, 2);
      expect(meeting.transcript[0].speaker, 'Emily');
      expect(meeting.durationSeconds ~/ 60, 30);
    });

    test('5. TaskModel Creation & Status Progression', () {
      final task = TaskModel(
        id: 5,
        title: 'Verify Offline Audio Vault',
        description: 'Test airplane mode recording and background resumption.',
        assignee: 'Emily Watson',
        deadline: 'Monday 12:00 PM',
        priority: 'urgent',
        status: 'pending',
        project: 'Core Mobile',
        isApproved: true,
      );

      expect(task.priority, 'urgent');
      expect(task.status, 'pending');

      final updated = task.copyWith(status: 'completed');
      expect(updated.status, 'completed');
    });

    test('6. WorkspaceModel & Role-Based Access Control', () {
      final json = {
        'id': 1,
        'name': 'Cowlar Engineering',
        'slug': 'cowlar-engineering',
        'tier': 'Team',
        'owner_name': 'Emily Watson',
        'current_user_role': 'owner',
        'active_seats': 4,
        'max_seats': 10,
        'members': [
          {'id': 1, 'user_id': 1, 'email': 'emily@example.com', 'full_name': 'Emily Watson', 'role': 'owner'},
          {'id': 2, 'user_id': 2, 'email': 'ali@example.com', 'full_name': 'Hasnain Ali', 'role': 'editor'}
        ]
      };

      final ws = WorkspaceModel.fromJson(json);
      expect(ws.name, 'Cowlar Engineering');
      expect(ws.currentUserRole, 'owner');
      expect(ws.members.length, 2);
      expect(ws.members[1].role, 'editor');
    });

    testWidgets('7. MeetMindApp Widget Smoke Test', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MeetMindApp(),
        ),
      );

      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    test('8. DefaultFirebaseOptions Project & Platform Alignment', () {
      expect(DefaultFirebaseOptions.android.projectId, 'meetmind-ai-74519');
      expect(DefaultFirebaseOptions.android.appId, '1:790778332182:android:211a1b9fc7c53e7d1f6137');
      expect(DefaultFirebaseOptions.android.messagingSenderId, '790778332182');

      expect(DefaultFirebaseOptions.ios.projectId, 'meetmind-ai-74519');
      expect(DefaultFirebaseOptions.ios.appId, '1:790778332182:ios:137f95ef50fc1efc1f6137');
      expect(DefaultFirebaseOptions.ios.iosBundleId, 'com.meetmind.ai.mobile');

      expect(DefaultFirebaseOptions.web.projectId, 'meetmind-ai-74519');
      expect(DefaultFirebaseOptions.web.appId, '1:790778332182:web:b4a2c8ebbd8720a61f6137');
    });

    test('9. UserModel & AuthState Multi-Provider Deserialization', () {
      final json = {
        'id': 7,
        'email': 'emily@example.com',
        'full_name': 'Emily Watson',
        'plan': 'Enterprise',
        'minutes_used': 120,
        'minutes_limit': 1000,
        'firebase_uid': 'fb-uid-1234567890',
        'avatar_url': 'https://meetmind.ai/avatars/emily.png',
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 7);
      expect(user.email, 'emily@example.com');
      expect(user.fullName, 'Emily Watson');
      expect(user.plan, 'Enterprise');
      expect(user.firebaseUid, 'fb-uid-1234567890');
      expect(user.avatarUrl, 'https://meetmind.ai/avatars/emily.png');

      final authInitial = AuthState.initial();
      expect(authInitial.isLoading, isTrue);
      expect(authInitial.isAuthenticated, isFalse);

      final authActive = AuthState.authenticated(user);
      expect(authActive.isLoading, isFalse);
      expect(authActive.isAuthenticated, isTrue);
      expect(authActive.user?.fullName, 'Emily Watson');

      final authLoggedOut = AuthState.unauthenticated('Invalid credentials');
      expect(authLoggedOut.isAuthenticated, isFalse);
      expect(authLoggedOut.errorMessage, 'Invalid credentials');
    });

    testWidgets('10. LoginScreen Glassmorphic & Google Sign-In UI Smoke Test',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2)); // Email & Password
      expect(find.byType(GoogleLogoIcon), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('OR CONTINUE WITH'), findsOneWidget);
      expect(find.text('Continue as Guest Reviewer'), findsOneWidget);
    });

    testWidgets(
        '11. DashboardScreen Cosmic Next Meeting & AI Prompt Smoke Test',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.text('Product Strategy Sync'), findsWidgets);
      expect(find.text('Ask MeetMind AI anything...'), findsOneWidget);
      expect(find.text("Today's Overview"), findsOneWidget);
      expect(find.text('Recent AI Notes'), findsOneWidget);
      expect(find.text('Meetings Today'), findsOneWidget);
    });

    testWidgets('12. MeetingsScreen Timeline & Segmented Tabs Smoke Test',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MeetingsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(MeetingsScreen), findsOneWidget);
      expect(find.text('Meetings'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Past'), findsOneWidget);
      expect(find.text('Recording'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('13. FloatingFrostedNavBar Active Pill & Navigation Shell Smoke Test',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainNavigationShell(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(FloatingFrostedNavBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
    });
  });
}
