import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../models/vault_recording_model.dart';

class VaultDatabase {
  static const String _tableName = 'offline_audio_vault';
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String dbPath;
    try {
      final docDir = await getApplicationDocumentsDirectory();
      dbPath = p.join(docDir.path, 'meetmind_offline_vault.db');
    } catch (_) {
      dbPath = 'meetmind_offline_vault.db';
    }

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            file_path TEXT NOT NULL,
            file_size_bytes INTEGER NOT NULL,
            duration_seconds INTEGER NOT NULL,
            sha256_checksum TEXT NOT NULL,
            created_at TEXT NOT NULL,
            sync_state TEXT NOT NULL,
            remote_meeting_id INTEGER,
            retry_count INTEGER NOT NULL DEFAULT 0,
            last_error TEXT,
            idempotency_key TEXT NOT NULL
          )
        ''');
      },
    );
  }

  static Future<void> insertRecording(VaultRecordingModel recording) async {
    final db = await database;
    await db.insert(
      _tableName,
      recording.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<VaultRecordingModel>> getAllRecordings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => VaultRecordingModel.fromMap(m)).toList();
  }

  static Future<List<VaultRecordingModel>> getPendingUploads() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'sync_state IN (?, ?, ?, ?)',
      whereArgs: [
        VaultSyncState.localOnly.name,
        VaultSyncState.waitingForConnection.name,
        VaultSyncState.failed.name,
        VaultSyncState.retryRequired.name,
      ],
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => VaultRecordingModel.fromMap(m)).toList();
  }

  static Future<void> updateSyncState({
    required String id,
    required VaultSyncState state,
    int? remoteMeetingId,
    int? retryCount,
    String? lastError,
  }) async {
    final db = await database;
    final values = <String, dynamic>{
      'sync_state': state.name,
    };
    if (remoteMeetingId != null) values['remote_meeting_id'] = remoteMeetingId;
    if (retryCount != null) values['retry_count'] = retryCount;
    if (lastError != null) values['last_error'] = lastError;

    await db.update(
      _tableName,
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteRecording(String id) async {
    final db = await database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }
}
