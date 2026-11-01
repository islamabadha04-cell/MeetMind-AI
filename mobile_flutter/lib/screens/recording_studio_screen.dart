import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/colors.dart';
import '../core/localization/language_provider.dart';
import '../core/services/audio_recording_service.dart';
import '../providers/vault_provider.dart';
import 'vault_screen.dart';

class RecordingStudioScreen extends ConsumerStatefulWidget {
  const RecordingStudioScreen({super.key});

  @override
  ConsumerState<RecordingStudioScreen> createState() =>
      _RecordingStudioScreenState();
}

class _RecordingStudioScreenState extends ConsumerState<RecordingStudioScreen> {
  final AudioRecordingService _recordingService = AudioRecordingService();
  bool _isRecording = false;
  bool _isPaused = false;
  int _seconds = 0;
  List<double> _waveform = List.filled(28, 0.2);
  final List<String> _bookmarkedMoments = [];

  @override
  void initState() {
    super.initState();
    _recordingService.timerStream.listen((sec) {
      if (mounted) setState(() => _seconds = sec);
    });
    _recordingService.amplitudeStream.listen((amps) {
      if (mounted) {
        setState(() {
          _waveform = amps;
        });
      }
    });
  }

  @override
  void dispose() {
    _recordingService.dispose();
    super.dispose();
  }

  String _formatTimer(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  void _toggleRecording() async {
    if (!_isRecording) {
      try {
        await _recordingService.startRecording();
        setState(() {
          _isRecording = true;
          _isPaused = false;
          _bookmarkedMoments.clear();
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: AppColors.error,
            ),
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

  void _bookmarkMoment() {
    _recordingService.bookmarkCurrentMoment();
    final timeStr = _formatTimer(_seconds);
    setState(() {
      _bookmarkedMoments.add(timeStr);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Moment bookmarked at $timeStr'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF7C3AED),
      ),
    );
  }

  void _showStopDialog() {
    final titleController = TextEditingController(
      text: 'Meeting ${DateTime.now().toString().substring(0, 16)}',
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141728) : Colors.white,
        title: Text(
          'Save to Offline Vault',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textMainLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter a title for this meeting recording. It will be stored in your encrypted local vault with cryptographic SHA-256 verification and queued for cloud AI sync.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: titleController,
              autofocus: true,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textMainLight,
              ),
              decoration: const InputDecoration(
                labelText: 'Meeting Title',
                border: OutlineInputBorder(),
              ),
            ),
            if (_bookmarkedMoments.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '${_bookmarkedMoments.length} key moment(s) bookmarked: ${_bookmarkedMoments.join(", ")}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF06B6D4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final model = await _recordingService.stopRecording(
                title: titleController.text.trim(),
              );
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
                      content: Text(
                          'Recording securely saved in Offline Vault! AI processing queued.'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B0E1B) : AppColors.bgLight,
        appBar: AppBar(
          title: Text(
            AppStrings.get('nav_record', lang),
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textMainLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: isDark ? const Color(0xFF0B0E1B) : Colors.white,
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Live Tracking Pill Bar (Image 2, Screen 2 Mockup)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141728) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF262C47)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording
                              ? (_isPaused
                                  ? AppColors.warning
                                  : AppColors.error)
                              : Colors.grey,
                          boxShadow: _isRecording && !_isPaused
                              ? [
                                  BoxShadow(
                                    color: AppColors.error.withValues(alpha: 0.6),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isRecording
                              ? (_isPaused
                                  ? 'Recording Paused'
                                  : 'AI Tracker Notes Recording...')
                              : 'Ready to Record Meeting Audio',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textMainLight,
                          ),
                        ),
                      ),
                      // Live Time Chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _formatTimer(_seconds),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFA78BFA),
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Live Audio Waveform Visualizer
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141728) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF262C47)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 90,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: List.generate(28, (index) {
                            final val = (index < _waveform.length)
                                ? _waveform[index]
                                : 0.2;
                            final h = (val * 80).clamp(6.0, 85.0);
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              width: 4.5,
                              height: h,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 2.5),
                              decoration: BoxDecoration(
                                gradient: _isRecording && !_isPaused
                                    ? const LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Color(0xFF7C3AED),
                                          Color(0xFF06B6D4),
                                        ],
                                      )
                                    : null,
                                color: !_isRecording || _isPaused
                                    ? (isDark
                                        ? const Color(0xFF2E3554)
                                        : Colors.grey.shade300)
                                    : null,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isRecording
                            ? (_isPaused
                                ? 'Recording paused • Tap resume to continue'
                                : 'High-Fidelity AAC-LC 128 kbps • 44.1 kHz')
                            : 'Tap the microphone button to start live capture',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Live Transcript & Bookmarked Moments Stream
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141728) : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF262C47)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Live Meeting Notes & Turns',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textMainLight,
                              ),
                            ),
                            if (_isRecording)
                              ActionChip(
                                avatar: const Icon(Icons.bookmark_add,
                                    size: 14, color: Color(0xFFA78BFA)),
                                label: const Text('Bookmark Moment',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                                backgroundColor: const Color(0xFF7C3AED)
                                    .withValues(alpha: 0.15),
                                side: const BorderSide(
                                    color: Color(0xFF7C3AED)),
                                onPressed: _bookmarkMoment,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView(
                            children: [
                              _transcriptTurn(
                                speaker: 'Client',
                                time: '00:15',
                                text:
                                    'Hi! I wanted to check in on our project roadmap and review the sprint deliverables.',
                                isDark: isDark,
                                avatarColor: const Color(0xFF8B5CF6),
                              ),
                              _transcriptTurn(
                                speaker: 'User (You)',
                                time: '00:30',
                                text:
                                    'Yes, based on current progress, our mobile Flutter and Firebase foundations are complete and verified.',
                                isDark: isDark,
                                avatarColor: const Color(0xFF06B6D4),
                              ),
                              if (_bookmarkedMoments.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 6),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7C3AED)
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                          color: const Color(0xFF7C3AED)
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.bookmarks_outlined,
                                            size: 16,
                                            color: Color(0xFFA78BFA)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Bookmarked Moments: ${_bookmarkedMoments.join(", ")}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFA78BFA),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Controls Row: Pause/Resume, Big Mic Button, Stop & Save
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (_isRecording)
                      IconButton.filledTonal(
                        iconSize: 28,
                        icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                        onPressed: _pauseResume,
                        tooltip: _isPaused ? 'Resume' : 'Pause',
                      )
                    else
                      const SizedBox(width: 48),

                    // Big Pulse Record Action Button
                    GestureDetector(
                      onTap: _toggleRecording,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _isRecording
                              ? const LinearGradient(
                                  colors: [AppColors.error, Color(0xFFDC2626)],
                                )
                              : AppColors.heroGradient,
                          boxShadow: [
                            BoxShadow(
                              color: (_isRecording
                                      ? AppColors.error
                                      : const Color(0xFF7C3AED))
                                  .withValues(alpha: 0.45),
                              blurRadius: 24,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                          size: 38,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    if (_isRecording)
                      IconButton.filledTonal(
                        iconSize: 28,
                        icon: const Icon(Icons.save_outlined),
                        onPressed: _showStopDialog,
                        tooltip: 'Save to Vault',
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _transcriptTurn({
    required String speaker,
    required String time,
    required String text,
    required bool isDark,
    required Color avatarColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: avatarColor,
            child: Text(
              speaker[0],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B2038) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        speaker,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: avatarColor,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white : AppColors.textMainLight,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
