import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/colors.dart';
import '../core/localization/app_strings.dart';
import '../core/localization/language_provider.dart';
import '../core/services/meeting_service.dart';
import '../models/meeting_detail_model.dart';
import '../providers/auth_provider.dart';
import '../providers/meeting_provider.dart';
import '../providers/vault_provider.dart';
import 'chat_screen.dart';
import 'integrations_screen.dart';
import 'meeting_detail_screen.dart';
import 'meetings_screen.dart';
import 'memory_screen.dart';
import 'recording_studio_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'tasks_screen.dart';
import 'vault_screen.dart';
import 'workspace_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  List<MeetingDetailModel> _recentMeetings = [];
  int _totalTasks = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
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

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isDark = ref.watch(themeModeProvider);
    final authState = ref.watch(authProvider);
    final vaultState = ref.watch(vaultProvider);
    final user = authState.user;
    final isUrdu = lang == AppLanguage.urdu;

    final userName = user?.fullName.split(' ').first ?? 'Emily';

    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning, $userName 👋',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              Text(
                AppStrings.get('greeting_subtitle', lang),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Badge(
                isLabelVisible: vaultState.pendingUploadCount > 0,
                label: Text('${vaultState.pendingUploadCount}'),
                child: const Icon(Icons.inventory_2_outlined),
              ),
              tooltip: AppStrings.get('vault_title', lang),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const VaultScreen()));
              },
            ),
            IconButton(
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                ref.read(themeModeProvider.notifier).state = !isDark;
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Hero Recording Studio Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.offline_bolt, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('Offline Vault Ready', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const Icon(Icons.mic, color: Colors.white, size: 28),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      AppStrings.get('hero_record_title', lang),
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.get('hero_record_desc', lang),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.fiber_manual_record, color: AppColors.error, size: 16),
                      label: Text(AppStrings.get('btn_start_recording', lang)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RecordingStudioScreen()),
                        ).then((_) => _loadDashboardData());
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // KPI Metric Cards
              Row(
                children: [
                  Expanded(child: _kpiCard(Icons.groups_outlined, '${_recentMeetings.length}', AppStrings.get('stat_meetings', lang), Colors.blue)),
                  const SizedBox(width: 10),
                  Expanded(child: _kpiCard(Icons.assignment_turned_in_outlined, '$_totalTasks', AppStrings.get('stat_tasks', lang), AppColors.primary)),
                  const SizedBox(width: 10),
                  Expanded(child: _kpiCard(Icons.schedule, '42m', AppStrings.get('stat_minutes', lang), Colors.orange)),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Access Grid
              const Text('Intelligence Features', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 10,
                children: [
                  _quickAction(Icons.mic_none, 'Record', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecordingStudioScreen()))),
                  _quickAction(Icons.groups, 'Meetings', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MeetingsScreen()))),
                  _quickAction(Icons.chat_bubble_outline, 'Ask AI', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()))),
                  _quickAction(Icons.task_alt, 'Tasks', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TasksScreen()))),
                  _quickAction(Icons.psychology_outlined, 'Memory', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MemoryScreen()))),
                  _quickAction(Icons.search, 'Search', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()))),
                  _quickAction(Icons.business_outlined, 'Workspace', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkspaceScreen()))),
                  _quickAction(Icons.hub_outlined, 'Integrations', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IntegrationsScreen()))),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Meetings Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Meetings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MeetingsScreen())),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              else if (_recentMeetings.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text('No meetings yet. Start your first recording above!', style: TextStyle(color: Colors.grey.shade600)),
                    ),
                  ),
                )
              else
                ..._recentMeetings.take(3).map((m) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        child: const Icon(Icons.groups, color: AppColors.primary),
                      ),
                      title: Text(m.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(
                        '${m.meetingDate} • ${m.durationSeconds ~/ 60}m • ${m.category}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => MeetingDetailScreen(meeting: m)));
                      },
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiCard(IconData icon, String val, String label, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
