import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../models/vault_recording_model.dart';
import 'api_client.dart';
import 'vault_database.dart';

class SyncStatusEvent {
  final String recordingId;
  final VaultSyncState state;
  final String? message;
  final double progress; // 0.0 to 1.0

  SyncStatusEvent({
    required this.recordingId,
    required this.state,
    this.message,
    this.progress = 0.0,
  });
}

class BackgroundSyncEngine {
  static final BackgroundSyncEngine _instance = BackgroundSyncEngine._internal();
  factory BackgroundSyncEngine() => _instance;
  BackgroundSyncEngine._internal();

  final _statusController = StreamController<SyncStatusEvent>.broadcast();
  Stream<SyncStatusEvent> get statusStream => _statusController.stream;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  void initialize() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        triggerSync(reason: 'Network restored');
      }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _statusController.close();
  }

  Future<void> triggerSync({String reason = 'Manual trigger'}) async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pending = await VaultDatabase.getPendingUploads();
      if (pending.isEmpty) {
        _isSyncing = false;
        return;
      }

      for (final recording in pending) {
        await _processSingleRecording(recording);
      }
    } catch (_) {
      // Background loop guardrail
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _processSingleRecording(VaultRecordingModel recording) async {
    final file = File(recording.filePath);
    if (!await file.exists()) {
      await VaultDatabase.updateSyncState(
        id: recording.id,
        state: VaultSyncState.failed,
        lastError: 'Local audio file missing from storage',
      );
      _statusController.add(SyncStatusEvent(
        recordingId: recording.id,
        state: VaultSyncState.failed,
        message: 'File missing from storage',
      ));
      return false;
    }

    // Verify SHA-256 integrity before upload
    final currentChecksum = await VaultRecordingModel.computeChecksum(recording.filePath);
    if (recording.sha256Checksum.isNotEmpty && currentChecksum != recording.sha256Checksum) {
      await VaultDatabase.updateSyncState(
        id: recording.id,
        state: VaultSyncState.failed,
        lastError: 'File integrity checksum mismatch',
      );
      return false;
    }

    // Notify uploading
    await VaultDatabase.updateSyncState(id: recording.id, state: VaultSyncState.uploading);
    _statusController.add(SyncStatusEvent(
      recordingId: recording.id,
      state: VaultSyncState.uploading,
      progress: 0.25,
      message: 'Uploading to MeetMind Cloud...',
    ));

    try {
      final result = await ApiClient.uploadAudioFile(
        filePath: recording.filePath,
        title: recording.title,
        idempotencyKey: recording.idempotencyKey,
      );

      final remoteId = (result is Map) ? (result['id'] as int? ?? 1) : 1;

      // Mark synced permanently
      await VaultDatabase.updateSyncState(
        id: recording.id,
        state: VaultSyncState.synced,
        remoteMeetingId: remoteId,
      );

      _statusController.add(SyncStatusEvent(
        recordingId: recording.id,
        state: VaultSyncState.synced,
        progress: 1.0,
        message: 'Synced successfully with MeetMind AI Cloud',
      ));
      return true;
    } catch (e) {
      final newRetryCount = recording.retryCount + 1;
      final backoffSeconds = min(pow(2, newRetryCount).toInt() * 2, 60);

      await VaultDatabase.updateSyncState(
        id: recording.id,
        state: VaultSyncState.retryRequired,
        retryCount: newRetryCount,
        lastError: e.toString().replaceAll('ApiException: ', ''),
      );

      _statusController.add(SyncStatusEvent(
        recordingId: recording.id,
        state: VaultSyncState.retryRequired,
        message: 'Upload failed: Will retry in ${backoffSeconds}s',
      ));
      return false;
    }
  }
}

