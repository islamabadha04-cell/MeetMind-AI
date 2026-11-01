import 'package:crypto/crypto.dart';
import 'dart:io';

enum VaultSyncState {
  localOnly,
  waitingForConnection,
  uploading,
  synced,
  failed,
  retryRequired,
}

class VaultRecordingModel {
  final String id; // UUID
  final String title;
  final String filePath;
  final int fileSizeBytes;
  final int durationSeconds;
  final String sha256Checksum;
  final DateTime createdAt;
  final VaultSyncState syncState;
  final int? remoteMeetingId;
  final int retryCount;
  final String? lastError;
  final String idempotencyKey;

  VaultRecordingModel({
    required this.id,
    required this.title,
    required this.filePath,
    required this.fileSizeBytes,
    required this.durationSeconds,
    required this.sha256Checksum,
    required this.createdAt,
    required this.syncState,
    this.remoteMeetingId,
    this.retryCount = 0,
    this.lastError,
    required this.idempotencyKey,
  });

  static Future<String> computeChecksum(String path) async {
    final file = File(path);
    if (!await file.exists()) return '';
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'file_path': filePath,
      'file_size_bytes': fileSizeBytes,
      'duration_seconds': durationSeconds,
      'sha256_checksum': sha256Checksum,
      'created_at': createdAt.toIso8601String(),
      'sync_state': syncState.name,
      'remote_meeting_id': remoteMeetingId,
      'retry_count': retryCount,
      'last_error': lastError,
      'idempotency_key': idempotencyKey,
    };
  }

  factory VaultRecordingModel.fromMap(Map<String, dynamic> map) {
    return VaultRecordingModel(
      id: map['id'] as String,
      title: map['title'] as String,
      filePath: map['file_path'] as String,
      fileSizeBytes: (map['file_size_bytes'] as int?) ?? 0,
      durationSeconds: (map['duration_seconds'] as int?) ?? 0,
      sha256Checksum: (map['sha256_checksum'] as String?) ?? '',
      createdAt:
          DateTime.tryParse(map['created_at'] as String) ?? DateTime.now(),
      syncState: VaultSyncState.values.firstWhere(
        (e) => e.name == map['sync_state'],
        orElse: () => VaultSyncState.localOnly,
      ),
      remoteMeetingId: map['remote_meeting_id'] as int?,
      retryCount: (map['retry_count'] as int?) ?? 0,
      lastError: map['last_error'] as String?,
      idempotencyKey:
          (map['idempotency_key'] as String?) ?? map['id'] as String,
    );
  }

  VaultRecordingModel copyWith({
    String? title,
    VaultSyncState? syncState,
    int? remoteMeetingId,
    int? retryCount,
    String? lastError,
  }) {
    return VaultRecordingModel(
      id: id,
      title: title ?? this.title,
      filePath: filePath,
      fileSizeBytes: fileSizeBytes,
      durationSeconds: durationSeconds,
      sha256Checksum: sha256Checksum,
      createdAt: createdAt,
      syncState: syncState ?? this.syncState,
      remoteMeetingId: remoteMeetingId ?? this.remoteMeetingId,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      idempotencyKey: idempotencyKey,
    );
  }
}
