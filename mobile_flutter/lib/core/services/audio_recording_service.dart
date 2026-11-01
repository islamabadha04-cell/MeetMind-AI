import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import '../../models/vault_recording_model.dart';
import 'notification_service.dart';

class AudioRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _timer;
  int _secondsRecorded = 0;
  String? _currentRecordingPath;
  String? _currentRecordingId;
  final List<double> _waveformAmplitudes = [];
  final List<int> _bookmarkedTimestamps = [];

  StreamSubscription<Amplitude>? _amplitudeSubscription;
  final _stateController = StreamController<bool>.broadcast();
  final _timerController = StreamController<int>.broadcast();
  final _amplitudeController = StreamController<List<double>>.broadcast();

  Stream<bool> get isRecordingStream => _stateController.stream;
  Stream<int> get timerStream => _timerController.stream;
  Stream<List<double>> get amplitudeStream => _amplitudeController.stream;

  int get secondsRecorded => _secondsRecorded;
  List<int> get bookmarks => List.unmodifiable(_bookmarkedTimestamps);

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<String> startRecording() async {
    final permitted = await hasPermission();
    if (!permitted) {
      throw Exception('Microphone permission was denied by the user.');
    }

    final docDir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory(p.join(docDir.path, 'recordings'));
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }

    final id = const Uuid().v4();
    final path = p.join(recordingsDir.path, 'meetmind_rec_$id.m4a');

    _currentRecordingId = id;
    _currentRecordingPath = path;
    _secondsRecorded = 0;
    _waveformAmplitudes.clear();
    _bookmarkedTimestamps.clear();

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    _stateController.add(true);
    NotificationService().showRecordingNotification(
      title: 'MeetMind Live Recording',
      duration: '00:00',
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsRecorded++;
      _timerController.add(_secondsRecorded);
    });

    _amplitudeSubscription = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 150))
        .listen((amp) {
      // Normalize amplitude between 0.1 and 1.0
      final normalized = ((amp.current + 60.0) / 60.0).clamp(0.1, 1.0);
      _waveformAmplitudes.add(normalized);
      if (_waveformAmplitudes.length > 32) {
        _waveformAmplitudes.removeAt(0);
      }
      _amplitudeController.add(List.from(_waveformAmplitudes));
    });

    return id;
  }

  Future<void> pauseRecording() async {
    await _recorder.pause();
    _timer?.cancel();
    _stateController.add(false);
  }

  Future<void> resumeRecording() async {
    await _recorder.resume();
    _stateController.add(true);
    NotificationService().showRecordingNotification(
      title: 'MeetMind Live Recording',
      duration: '00:00',
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsRecorded++;
      _timerController.add(_secondsRecorded);
    });
  }

  void bookmarkCurrentMoment() {
    _bookmarkedTimestamps.add(_secondsRecorded);
  }

  Future<VaultRecordingModel?> stopRecording({required String title}) async {
    _timer?.cancel();
    await _amplitudeSubscription?.cancel();
    await NotificationService().cancelRecordingNotification();
    final path = await _recorder.stop();
    _stateController.add(false);

    final finalPath = path ?? _currentRecordingPath;
    if (finalPath == null) return null;

    final file = File(finalPath);
    if (!await file.exists()) return null;

    final sizeBytes = await file.length();
    final checksum = await VaultRecordingModel.computeChecksum(finalPath);

    final model = VaultRecordingModel(
      id: _currentRecordingId ?? const Uuid().v4(),
      title: title.isNotEmpty ? title : 'Recorded Meeting ${DateTime.now().toString().substring(0, 16)}',
      filePath: finalPath,
      fileSizeBytes: sizeBytes,
      durationSeconds: _secondsRecorded,
      sha256Checksum: checksum,
      createdAt: DateTime.now(),
      syncState: VaultSyncState.localOnly,
      idempotencyKey: _currentRecordingId ?? const Uuid().v4(),
    );

    return model;
  }

  void dispose() {
    NotificationService().cancelRecordingNotification();
    _timer?.cancel();
    _amplitudeSubscription?.cancel();
    _recorder.dispose();
    _stateController.close();
    _timerController.close();
    _amplitudeController.close();
  }
}

