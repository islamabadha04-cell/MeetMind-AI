import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/colors.dart';
import '../core/localization/language_provider.dart';
import '../core/services/meeting_service.dart';
import '../models/meeting_detail_model.dart';
import '../providers/auth_provider.dart';
import '../providers/meeting_provider.dart';
import '../providers/vault_provider.dart';
import 'chat_screen.dart';
import 'meeting_detail_screen.dart';
import 'meetings_screen.dart';
import 'recording_studio_screen.dart';
import 'vault_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  List<MeetingDetailModel> _recentMeetings = [];
  int _totalTasks = 0;
  bool _isLoading = true;
  final TextEditingController _promptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      final meetings = await MeetingService.getMeetings();
      final tasks = await MeetingService.getTasks();
      if (mounted) {
        setState(() {
          _recentMeetings = meetings;
          _totalTasks = tasks.length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openChatWithPrompt(String prompt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(initialPrompt: prompt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isDark = ref.watch(themeModeProvider);
    final authState = ref.watch(authProvider);
    final vaultState = ref.watch(vaultProvider);
    final user = authState.user;
    final isUrdu = lang == AppLanguage.urdu;

    final userName = user?.fullName.split(' ').first ?? 'Nathan';

    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B0E1B) : AppColors.bgLight,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _loadDashboardData,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 90),
              children: [
                // Top Header: User Profile, Greeting, and Action Icons
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.heroGradient,
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            isDark ? const Color(0xFF141728) : Colors.white,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'N',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Good Morning, $userName 👋',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textMainLight,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            AppStrings.get('greeting_subtitle', lang),
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Vault Sync Badge
                    IconButton(
                      icon: Badge(
                        isLabelVisible: vaultState.pendingUploadCount > 0,
                        label: Text('${vaultState.pendingUploadCount}'),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 20,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : Colors.grey.shade700,
                        ),
                      ),
                      tooltip: AppStrings.get('vault_title', lang),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const VaultScreen()),
                        );
                      },
                    ),
                    // Notification Bell with Violet Unread Dot
                    Stack(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.notifications_none_rounded,
                            size: 22,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : Colors.grey.shade700,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('All notifications are up to date!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        Positioned(
                          right: 12,
                          top: 10,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF8B5CF6),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Next Meeting Hero Card (Mockup Inspiration)
                _buildNextMeetingCard(isDark, lang),
                const SizedBox(height: 20),

                // "Ask MeetMind AI anything..." Prompt Bar
                _buildAskAiBar(isDark),
                const SizedBox(height: 12),

                // Quick Prompt Suggestion Chips
                _buildQuickPromptChips(isDark),
                const SizedBox(height: 24),

                // Today's Overview (Bento Grid Metrics)
                Text(
                  "Today's Overview",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTodayOverviewGrid(isDark, lang),
                const SizedBox(height: 26),

                // Recent AI Notes Header with Floating Gradient '+'
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent AI Notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textMainLight,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RecordingStudioScreen(),
                          ),
                        ).then((_) => _loadDashboardData());
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: AppColors.buttonGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED)
                                  .withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Recent Meetings List
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_recentMeetings.isEmpty)
                  _buildEmptyMeetings(isDark, lang)
                else
                  ..._recentMeetings.take(4).map((m) => _buildMeetingNoteCard(m, isDark)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextMeetingCard(bool isDark, AppLanguage lang) {
    final nextMeeting = _recentMeetings.isNotEmpty ? _recentMeetings.first : null;
    final title = nextMeeting?.title ?? 'Product Strategy Sync';
    final date = nextMeeting?.meetingDate ?? 'Today • 09:00 AM';

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B1E38), Color(0xFF111424)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF1F5F9)],
              ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3554) : const Color(0xFFCBD5E1),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_month_outlined,
                    color: Color(0xFFA78BFA), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textMainLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.schedule,
                            size: 12, color: Color(0xFF06B6D4)),
                        const SizedBox(width: 4),
                        const Text(
                          'Start in 15 min',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF06B6D4),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• $date',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Attendees Row & Platform Tag
          Row(
            children: [
              // Overlapping Avatar Cluster
              SizedBox(
                width: 76,
                height: 26,
                child: Stack(
                  children: [
                    _avatarItem(0, 'E', const Color(0xFF6D5AE5)),
                    _avatarItem(16, 'H', const Color(0xFF06B6D4)),
                    _avatarItem(32, 'M', const Color(0xFFEC4899)),
                    Positioned(
                      left: 48,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? const Color(0xFF262C47)
                              : Colors.grey.shade300,
                          border: Border.all(
                              color: isDark
                                  ? const Color(0xFF141728)
                                  : Colors.white,
                              width: 1.5),
                        ),
                        child: const Center(
                          child: Text('+4',
                              style: TextStyle(
                                  fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '8 Participants',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              // Platform Chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A2035)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.video_camera_front_outlined,
                        size: 13, color: Color(0xFF34A853)),
                    SizedBox(width: 4),
                    Text('Google Meet',
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Glowing "Join Meeting ->" CTA Button
          Container(
            width: double.infinity,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Text(
                'Join Meeting',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              label: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 18),
              onPressed: () {
                if (nextMeeting != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MeetingDetailScreen(meeting: nextMeeting),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MeetingsScreen(),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarItem(double left, String initial, Color bg) {
    return Positioned(
      left: left,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
          border: Border.all(color: const Color(0xFF141728), width: 1.5),
        ),
        child: Center(
          child: Text(
            initial,
            style: const TextStyle(
                color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildAskAiBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141728) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF262C47) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFFA78BFA), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _promptController,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : AppColors.textMainLight,
              ),
              decoration: InputDecoration(
                hintText: 'Ask MeetMind AI anything...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : Colors.grey.shade500,
                ),
                border: InputBorder.none,
              ),
              onSubmitted: (query) {
                if (query.trim().isNotEmpty) {
                  _openChatWithPrompt(query.trim());
                  _promptController.clear();
                }
              },
            ),
          ),
          GestureDetector(
            onTap: () {
              final query = _promptController.text.trim();
              if (query.isNotEmpty) {
                _openChatWithPrompt(query);
                _promptController.clear();
              } else {
                _openChatWithPrompt('Summarize my recent meetings and key action items.');
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                gradient: AppColors.buttonGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPromptChips(bool isDark) {
    final chips = [
      '✨ Summarize yesterday\'s meeting',
      '📋 Show action items',
      '⚡ Review key decisions',
      '🎙 Audio vault status',
    ];

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final text = chips[idx];
          return ActionChip(
            label: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade800,
              ),
            ),
            backgroundColor: isDark
                ? const Color(0xFF141728)
                : Colors.grey.shade100,
            side: BorderSide(
              color: isDark
                  ? const Color(0xFF262C47)
                  : const Color(0xFFE2E8F0),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onPressed: () => _openChatWithPrompt(text),
          );
        },
      ),
    );
  }

  Widget _buildTodayOverviewGrid(bool isDark, AppLanguage lang) {
    return Row(
      children: [
        // Metric 1: Meetings Today
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141728) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF262C47)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calendar_today_rounded,
                          color: Color(0xFFA78BFA), size: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '+20%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${_recentMeetings.isEmpty ? 3 : _recentMeetings.length}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Meetings Today',
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
        ),
        const SizedBox(width: 12),

        // Metric 2: AI Recaps
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141728) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF262C47)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.auto_awesome,
                          color: Color(0xFF06B6D4), size: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '+40%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${_totalTasks > 0 ? _totalTasks : 12}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'AI Recaps Ready',
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
        ),
      ],
    );
  }

  Widget _buildMeetingNoteCard(MeetingDetailModel m, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141728) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF262C47) : const Color(0xFFE2E8F0),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.description_outlined,
              color: Color(0xFFA78BFA), size: 18),
        ),
        title: Text(
          m.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isDark ? Colors.white : AppColors.textMainLight,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              '${m.meetingDate} • ${m.durationSeconds ~/ 60}m',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'AI Summary Ready',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFA78BFA),
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MeetingDetailScreen(meeting: m),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyMeetings(bool isDark, AppLanguage lang) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141728) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF262C47) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_note,
                size: 36,
                color: isDark ? const Color(0xFF64748B) : Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'No meetings found',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textMainLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
