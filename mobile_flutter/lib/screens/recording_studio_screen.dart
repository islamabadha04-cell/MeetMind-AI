import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/colors.dart';
import '../core/localization/app_strings.dart';
import '../core/localization/language_provider.dart';
import '../core/services/audio_recording_service.dart';
import '../providers/vault_provider.dart';
import 'vault_screen.dart';

class RecordingStudioScreen extends ConsumerStatefulWidget {
  const RecordingStudioScreen({super.key});

  @override
  ConsumerState<RecordingStudioScreen> createState() => _RecordingStudioScreenState();
}

class _RecordingStudioScreenState extends ConsumerState<RecordingStudioScreen> {
  final AudioRecordingService _recordingService = AudioRecordingService();
  bool _isRecording = false;
  bool _isPaused = false;
  int _seconds = 0;
  List<double> _waveform = List.filled(24, 0.2);

  @override
  void initState() {
    super.initState();
    _recordingService.timerStream.listen((sec) {
      if (mounted) setState(() => _seconds = sec);
    });
    _recordingService.amplitudeStream.listen((amps) {
      if (mounted) setState(() => _waveform = amps);
    });
  }

  @override
  void dispose() {
    _recordingService.dispose();
    super.dispose();
  }

  String _formatTimer(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  void _toggleRecording() async {
    if (!_isRecording) {
      try {
        await _recordingService.startRecording();
        setState(() {
          _isRecording = true;
          _isPaused = false;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
          );
        }
      }
    } else {
      _showStopDialog();
    }
  }

  void _pauseResume() async {
    if (_isPaused) {
      await _recordingService.resumeRecording();
      setState(() => _isPaused = false);
    } else {
      await _recordingService.pauseRecording();
      setState(() => _isPaused = true);
    }
  }

  void _showStopDialog() {
    final titleController = TextEditingController(
      text: 'Meeting ${DateTime.now().toString().substring(0, 16)}',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Save to Offline Vault'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a title for this meeting recording. It will be stored safely in your device vault and queued for cloud AI sync.'),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Meeting Title',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final model = await _recordingService.stopRecording(title: titleController.text.trim());
              if (model != null) {
                await ref.read(vaultProvider.notifier).saveNewRecording(
                  id: model.id,
                  title: model.title,
                  filePath: model.filePath,
                  fileSizeBytes: model.fileSizeBytes,
                  durationSeconds: model.durationSeconds,
                  sha256Checksum: model.sha256Checksum,
                );
                setState(() {
                  _isRecording = false;
                  _isPaused = false;
                  _seconds = 0;
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Recording safely saved in Offline Vault! AI processing queued.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            child: const Text('Save to Vault'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final vaultState = ref.watch(vaultProvider);
    final isUrdu = lang == AppLanguage.urdu;

    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get('nav_record', lang)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Badge(
                isLabelVisible: vaultState.pendingUploadCount > 0,
                label: Text('${vaultState.pendingUploadCount}'),
                child: const Icon(Icons.inventory_2_outlined),
              ),
              tooltip: AppStrings.get('vault_title', lang),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VaultScreen()),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Indicator Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? (_isPaused ? AppColors.warning.withValues(alpha: 0.15) : AppColors.error.withValues(alpha: 0.15))
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording
                              ? (_isPaused ? AppColors.warning : AppColors.error)
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isRecording
                            ? (_isPaused ? AppStrings.get('recording_paused', lang) : AppStrings.get('recording_active', lang))
                            : 'Ready to Record',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _isRecording
                              ? (_isPaused ? AppColors.warning : AppColors.error)
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Digital Timer
                Text(
                  _formatTimer(_seconds),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),

                // Live Audio Waveform
                SizedBox(
                  height: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(24, (index) {
                      final val = (index < _waveform.length) ? _waveform[index] : 0.2;
                      final h = (val * 90).clamp(8.0, 100.0);
                      return Container(
                        width: 5,
                        height: h,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          gradient: _isRecording && !_isPaused ? AppColors.heroGradient : null,
                          color: !_isRecording || _isPaused ? Colors.grey.shade400 : null,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),

                // Actions & Controls
                Column(
                  children: [
                    if (_isRecording)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.bookmark_add_outlined),
                          label: Text(AppStrings.get('btn_bookmark', lang)),
                          onPressed: () {
                            _recordingService.bookmarkCurrentMoment();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Moment bookmarked at ${_formatTimer(_seconds)}'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (_isRecording)
                          IconButton.filledTonal(
                            iconSize: 32,
                            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                            onPressed: _pauseResume,
                            tooltip: _isPaused ? AppStrings.get('btn_resume', lang) : AppStrings.get('btn_pause', lang),
                          ),

                        // Main Big Record Button
                        GestureDetector(
                          onTap: _toggleRecording,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: _isRecording
                                  ? const LinearGradient(colors: [AppColors.error, Color(0xFFDC2626)])
                                  : AppColors.heroGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isRecording ? AppColors.error : AppColors.primary).withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              _isRecording ? Icons.stop_rounded : Icons.mic,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        if (_isRecording)
                          IconButton.filledTonal(
                            iconSize: 32,
                            icon: const Icon(Icons.save_outlined),
                            onPressed: _showStopDialog,
                            tooltip: AppStrings.get('btn_stop_save', lang),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
