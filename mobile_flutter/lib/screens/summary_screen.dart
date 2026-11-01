import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI Summary'),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            tabs: [
              Tab(text: 'Summary'),
              Tab(text: 'Transcript'),
              Tab(text: 'Tasks'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSummaryTab(),
            _buildTranscriptTab(),
            _buildTasksTab(),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            icon: const Icon(Icons.download),
            label: const Text('Export Summary'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Summary exported successfully!')),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Executive Summary',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'The meeting focused on the Project Alpha timeline, finalized new low-latency audio capture specs, and agreed to launch sprint beta.',
          style: TextStyle(color: Colors.grey, height: 1.5),
        ),
        const SizedBox(height: 20),
        const Text(
          'Key Decisions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _decisionItem('Approved the new design direction.'),
        _decisionItem('Set Q2 launch target.'),
        _decisionItem('Allocated budget for marketing.'),
        const SizedBox(height: 20),
        const Text(
          'Action Items',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _actionItem('Design mockups - Sarah (Apr 30)', true),
        _actionItem('API integration - Ali (May 5)', false),
        _actionItem('Marketing plan - John (May 10)', false),
      ],
    );
  }

  Widget _decisionItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _actionItem(String text, bool checked) {
    return CheckboxListTile(
      value: checked,
      onChanged: (val) {},
      title: Text(text, style: const TextStyle(fontSize: 14)),
      dense: true,
      contentPadding: EdgeInsets.zero,
      activeColor: AppColors.primary,
    );
  }

  Widget _buildTranscriptTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('[00:00 - 04:12] Ali: Good morning, let us review the Project Alpha deliverables.'),
        SizedBox(height: 12),
        Text('[04:13 - 10:45] Sarah: The purple/lavender UI design is fully complete.'),
        SizedBox(height: 12),
        Text('[10:46 - 22:00] John: The backend APIs are tested and ready for release.'),
      ],
    );
  }

  Widget _buildTasksTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _actionItem('Design mockups - Sarah (Apr 30) • High', true),
        _actionItem('API integration - Ali (May 5) • High', false),
        _actionItem('Marketing plan - John (May 10) • Medium', false),
      ],
    );
  }
}
