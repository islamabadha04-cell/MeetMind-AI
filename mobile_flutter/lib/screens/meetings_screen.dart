import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../core/constants/colors.dart';
import '../core/localization/language_provider.dart';
import '../core/services/meeting_service.dart';
import '../models/meeting_detail_model.dart';
import 'meeting_detail_screen.dart';
import 'recording_studio_screen.dart';

class MeetingsScreen extends ConsumerStatefulWidget {
  const MeetingsScreen({super.key});

  @override
  ConsumerState<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends ConsumerState<MeetingsScreen> {
  List<MeetingDetailModel> _meetings = [];
  bool _isLoading = true;
  String _filter = '';
  int _selectedTab = 0; // 0: Upcoming, 1: Past, 2: Recording

  @override
  void initState() {
    super.initState();
    _fetchMeetings();
  }

  Future<void> _fetchMeetings() async {
    setState(() => _isLoading = true);
    try {
      final list = await MeetingService.getMeetings();
      if (mounted) {
        setState(() {
          _meetings = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isUrdu = lang == AppLanguage.urdu;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _meetings.where((m) {
      if (_filter.isNotEmpty &&
          !m.title.toLowerCase().contains(_filter.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B0E1B) : AppColors.bgLight,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Header (Matching Design Inspiration Screen 3)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meetings',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: isDark ? Colors.white : AppColors.textMainLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Stay on top of your schedule',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Search Button Toggle
                        IconButton(
                          icon: Icon(Icons.search,
                              size: 20,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : Colors.grey.shade700),
                          onPressed: () {
                            _showSearchDialog(context, isDark);
                          },
                        ),
                        // Create / Record Plus Button
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RecordingStudioScreen(),
                              ),
                            ).then((_) => _fetchMeetings());
                          },
                          child: Container(
                            width: 36,
                            height: 36,
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
                  ],
                ),
              ),

              // Segmented Filter Capsule Tabs [Upcoming] [Past] [Recording]
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141728) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF262C47)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      _segmentedTab(0, 'Upcoming', Icons.calendar_today, isDark),
                      _segmentedTab(1, 'Past', Icons.history, isDark),
                      _segmentedTab(2, 'Recording', Icons.videocam_outlined, isDark),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Today Header Date Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 14, color: Color(0xFFA78BFA)),
                    const SizedBox(width: 8),
                    Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textMainLight,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('MMM d, y').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'View Calendar >',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFA78BFA) : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Meetings Timeline List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? _buildEmptyState(isDark)
                        : RefreshIndicator(
                            onRefresh: _fetchMeetings,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
                              itemCount: filtered.length,
                              itemBuilder: (context, idx) {
                                return _buildTimelineItem(
                                  meeting: filtered[idx],
                                  index: idx,
                                  isLast: idx == filtered.length - 1,
                                  isDark: isDark,
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _segmentedTab(int tabIndex, String label, IconData icon, bool isDark) {
    final isSelected = _selectedTab == tabIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = tabIndex),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.buttonGradient : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required MeetingDetailModel meeting,
    required int index,
    required bool isLast,
    required bool isDark,
  }) {
    final times = ['09.00\nAM', '10.30\nAM', '02.00\nPM', '04.30\nPM'];
    final timeStr = times[index % times.length];
    final platforms = ['Google Meet', 'Zoom', 'Microsoft Teams'];
    final platform = platforms[index % platforms.length];
    final platformIcon = platform == 'Zoom'
        ? Icons.videocam
        : (platform == 'Google Meet'
            ? Icons.video_camera_front_outlined
            : Icons.groups_outlined);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Time Column
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // Timeline Connector Dot & Line
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == 0
                      ? const Color(0xFF8B5CF6)
                      : const Color(0xFF06B6D4),
                  boxShadow: [
                    BoxShadow(
                      color: (index == 0
                              ? const Color(0xFF8B5CF6)
                              : const Color(0xFF06B6D4))
                          .withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDark
                        ? const Color(0xFF262C47)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Meeting Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141728) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF262C47)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top status tag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          index == 0 ? 'Start in 15 min' : 'Upcoming Today',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFA78BFA),
                          ),
                        ),
                      ),
                      Icon(Icons.more_horiz,
                          size: 18,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : Colors.grey.shade400),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Meeting Title
                  Text(
                    meeting.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textMainLight,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Platform and Duration
                  Row(
                    children: [
                      Icon(platformIcon,
                          size: 13,
                          color: platform == 'Zoom'
                              ? Colors.blue
                              : const Color(0xFF34A853)),
                      const SizedBox(width: 4),
                      Text(
                        platform,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFFCBD5E1)
                              : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.access_time,
                          size: 12,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        '${meeting.durationSeconds ~/ 60} min',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Attendees Avatar Cluster + AI Summary Ready Chip
                  Row(
                    children: [
                      // Mini Avatar Stack
                      SizedBox(
                        width: 58,
                        height: 22,
                        child: Stack(
                          children: [
                            _miniAvatar(0, 'E', const Color(0xFF7C3AED)),
                            _miniAvatar(14, 'A', const Color(0xFF06B6D4)),
                            _miniAvatar(28, 'M', const Color(0xFFEC4899)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '4 attendees',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      // AI Summary Ready Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF7C3AED).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.auto_awesome,
                                size: 10, color: Color(0xFFA78BFA)),
                            SizedBox(width: 4),
                            Text(
                              'AI Ready',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFA78BFA),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // "Join Meeting ->" CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6D5AE5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      icon: const Text(
                        'Join Meeting',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      label: const Icon(Icons.arrow_forward, size: 14),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MeetingDetailScreen(meeting: meeting),
                          ),
                        );
                      },
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

  Widget _miniAvatar(double left, String text, Color color) {
    return Positioned(
      left: left,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF141728), width: 1.2),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
                color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy,
                size: 48,
                color: isDark ? const Color(0xFF64748B) : Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No meetings found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Schedule a meeting or start an audio recording to populate your timeline.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF141728) : Colors.white,
          title: Text(
            'Search Meetings',
            style: TextStyle(
                color: isDark ? Colors.white : AppColors.textMainLight),
          ),
          content: TextField(
            autofocus: true,
            style: TextStyle(
                color: isDark ? Colors.white : AppColors.textMainLight),
            decoration: const InputDecoration(
              hintText: 'Enter keyword or topic...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (val) {
              setState(() => _filter = val);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _filter = '');
                Navigator.pop(ctx);
              },
              child: const Text('Clear'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }
}
