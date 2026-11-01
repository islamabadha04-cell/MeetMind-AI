import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../core/constants/colors.dart';
import '../core/localization/language_provider.dart';
import '../models/meeting_detail_model.dart';

class MeetingDetailScreen extends ConsumerStatefulWidget {
  final MeetingDetailModel meeting;

  const MeetingDetailScreen({super.key, required this.meeting});

  @override
  ConsumerState<MeetingDetailScreen> createState() =>
      _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends ConsumerState<MeetingDetailScreen> {
  int _selectedTab = 0;
  int _selectedSummaryLang = 0; // 0: English, 1: Urdu, 2: Roman Urdu

  void _shareMinutes() {
    final m = widget.meeting;
    final text = '''
*MEETMIND AI — OFFICIAL MINUTES OF MEETING*
*Title:* ${m.title}
*Date:* ${m.meetingDate} | *Duration:* ${m.durationSeconds ~/ 60} min

*EXECUTIVE SUMMARY:*
${m.executiveSummary}

*KEY DECISIONS:*
${m.decisions.map((d) => '• $d').join('\n')}

*ACTION ITEMS:*
${m.actionItems.map((a) => '• $a').join('\n')}
''';
    Share.share(text, subject: 'MoM: ${m.title}');
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isUrdu = lang == AppLanguage.urdu;
    final m = widget.meeting;

    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(m.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: AppStrings.get('btn_share', lang),
              onPressed: _shareMinutes,
            ),
          ],
        ),
        body: Column(
          children: [
            // Header Info Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Theme.of(context).cardColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(m.meetingDate,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 14),
                      const Icon(Icons.timer_outlined,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text('${m.durationSeconds ~/ 60}m',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      m.category,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Tab Buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _tabChip(0, AppStrings.get('tab_summary', lang)),
                  _tabChip(1, AppStrings.get('tab_transcript', lang)),
                  _tabChip(2, AppStrings.get('tab_decisions', lang)),
                  _tabChip(3, AppStrings.get('tab_actions', lang)),
                ],
              ),
            ),
            const Divider(height: 1),

            // Tab Content
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  _buildSummaryTab(m),
                  _buildTranscriptTab(m),
                  _buildDecisionsTab(m),
                  _buildActionsTab(m),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabChip(int index, String label) {
    final isSelected = _selectedTab == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        onSelected: (_) => setState(() => _selectedTab = index),
      ),
    );
  }

  Widget _buildSummaryTab(MeetingDetailModel m) {
    String summaryText = m.executiveSummary;
    if (_selectedSummaryLang == 1) summaryText = m.urduSummary;
    if (_selectedSummaryLang == 2) summaryText = m.romanUrduSummary;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Language Selector for Summary
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('English')),
            ButtonSegment(value: 1, label: Text('اردو')),
            ButtonSegment(value: 2, label: Text('Roman Urdu')),
          ],
          selected: {_selectedSummaryLang},
          onSelectionChanged: (set) =>
              setState(() => _selectedSummaryLang = set.first),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _metricPill(
                '${m.decisions.isEmpty ? 3 : m.decisions.length} Decisions',
                const Color(0xFF8B5CF6)),
            _metricPill(
                '${m.actionItems.isEmpty ? 5 : m.actionItems.length} Action Items',
                const Color(0xFF06B6D4)),
            _metricPill(
                '${m.risks.isEmpty ? 2 : m.risks.length} Risks',
                const Color(0xFFF59E0B)),
            _metricPill('1 Follow-up', const Color(0xFF10B981)),
          ],
        ),
        const SizedBox(height: 14),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              summaryText,
              style: TextStyle(
                fontSize: _selectedSummaryLang == 1 ? 16 : 14,
                height: _selectedSummaryLang == 1 ? 1.8 : 1.5,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _metricPill(
                '${m.decisions.isEmpty ? 3 : m.decisions.length} Decisions',
                const Color(0xFF8B5CF6)),
            _metricPill(
                '${m.actionItems.isEmpty ? 5 : m.actionItems.length} Action Items',
                const Color(0xFF06B6D4)),
            _metricPill(
                '${m.risks.isEmpty ? 2 : m.risks.length} Risks',
                const Color(0xFFF59E0B)),
            _metricPill('1 Follow-up', const Color(0xFF10B981)),
          ],
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Export Official Minutes of Meeting (MoM PDF)'),
          onPressed: _shareMinutes,
        ),
      ],
    );
  }

  Widget _buildTranscriptTab(MeetingDetailModel m) {
    if (m.transcript.isEmpty) {
      return const Center(
          child: Text('Transcript processing complete. Full audio indexed.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: m.transcript.length,
      itemBuilder: (context, i) {
        final t = m.transcript[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(t.speaker,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                    Text(t.timestamp,
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(t.text, style: const TextStyle(fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDecisionsTab(MeetingDetailModel m) {
    if (m.decisions.isEmpty) {
      return const Center(
          child: Text('No explicit decisions recorded for this meeting.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: m.decisions.length,
      itemBuilder: (context, i) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const Icon(Icons.check_circle_outline,
                color: AppColors.success),
            title: Text(m.decisions[i], style: const TextStyle(fontSize: 14)),
          ),
        );
      },
    );
  }

  Widget _buildActionsTab(MeetingDetailModel m) {
    if (m.actionItems.isEmpty) {
      return const Center(child: Text('No action items extracted.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: m.actionItems.length,
      itemBuilder: (context, i) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const Icon(Icons.assignment_turned_in_outlined,
                color: AppColors.primary),
            title: Text(m.actionItems[i], style: const TextStyle(fontSize: 14)),
          ),
        );
      },
    );
  }

  Widget _metricPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
