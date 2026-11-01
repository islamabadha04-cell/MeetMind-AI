import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/background_sync_engine.dart';
import '../core/services/vault_database.dart';
import '../models/vault_recording_model.dart';

class VaultState {
  final List<VaultRecordingModel> recordings;
  final bool isLoading;
  final int pendingUploadCount;
  final SyncStatusEvent? activeSyncEvent;

  VaultState({
    required this.recordings,
    required this.isLoading,
    required this.pendingUploadCount,
    this.activeSyncEvent,
  });

  factory VaultState.initial() => VaultState(recordings: [], isLoading: true, pendingUploadCount: 0);

  VaultState copyWith({
    List<VaultRecordingModel>? recordings,
    bool? isLoading,
    int? pendingUploadCount,
    SyncStatusEvent? activeSyncEvent,
  }) {
    return VaultState(
      recordings: recordings ?? this.recordings,
      isLoading: isLoading ?? this.isLoading,
      pendingUploadCount: pendingUploadCount ?? this.pendingUploadCount,
      activeSyncEvent: activeSyncEvent ?? this.activeSyncEvent,
    );
  }
}

class VaultNotifier extends StateNotifier<VaultState> {
  VaultNotifier() : super(VaultState.initial()) {
    refresh();
    _listenToSyncEvents();
  }

  void _listenToSyncEvents() {
    BackgroundSyncEngine().statusStream.listen((event) {
      state = state.copyWith(activeSyncEvent: event);
      refresh();
    });
  }

  Future<void> refresh() async {
    try {
      final list = await VaultDatabase.getAllRecordings();
      final pending = list.where((r) => r.syncState != VaultSyncState.synced).length;
      state = state.copyWith(recordings: list, isLoading: false, pendingUploadCount: pending);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> saveNewRecording({
    required String id,
    required String title,
    required String filePath,
    required int fileSizeBytes,
    required int durationSeconds,
    required String sha256Checksum,
  }) async {
    final recording = VaultRecordingModel(
      id: id,
      title: title,
      filePath: filePath,
      fileSizeBytes: fileSizeBytes,
      durationSeconds: durationSeconds,
      sha256Checksum: sha256Checksum,
      createdAt: DateTime.now(),
      syncState: VaultSyncState.localOnly,
      idempotencyKey: id,
    );

    await VaultDatabase.insertRecording(recording);
    await refresh();

    // Trigger sync automatically if connection exists
    BackgroundSyncEngine().triggerSync(reason: 'New recording saved');
  }

  Future<void> retryUpload(String id) async {
    await VaultDatabase.updateSyncState(id: id, state: VaultSyncState.waitingForConnection);
    await refresh();
    BackgroundSyncEngine().triggerSync(reason: 'User manual retry');
  }

  Future<void> deleteRecording(String id) async {
    await VaultDatabase.deleteRecording(id);
    await refresh();
  }
}

final vaultProvider = StateNotifierProvider<VaultNotifier, VaultState>((ref) {
  return VaultNotifier();
});
