import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meetmind_mobile/main.dart';
import 'package:meetmind_mobile/core/localization/app_strings.dart';
import 'package:meetmind_mobile/core/localization/language_provider.dart';
import 'package:meetmind_mobile/core/theme/app_theme.dart';
import 'package:meetmind_mobile/models/vault_recording_model.dart';
import 'package:meetmind_mobile/models/meeting_detail_model.dart';
import 'package:meetmind_mobile/models/task_model.dart';
import 'package:meetmind_mobile/models/workspace_model.dart';

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
  });
}
