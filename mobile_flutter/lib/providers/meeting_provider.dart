import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meeting_model.dart';

final initialMeetings = [
  MeetingModel(
    id: 1,
    title: 'Project Alpha Discussion',
    date: 'Today, 10:30 AM',
    duration: '22 min',
    tag: 'Work',
    summary: 'The meeting focused on the Project Alpha timeline, finalized new low-latency audio capture specs, and agreed to launch sprint beta.',
    decisions: ['Approved the new design direction', 'Set Q2 launch target', 'Allocated budget for marketing'],
    actionItems: ['Design mockups - Sarah (Apr 30)', 'API integration - Ali (May 5)', 'Marketing plan - John (May 10)'],
  ),
  MeetingModel(
    id: 2,
    title: 'Client Call - Acme Corp',
    date: 'Yesterday, 2:15 PM',
    duration: '45 min',
    tag: 'Client',
    summary: 'Reviewed client requirements for automated transcription, security compliance, and custom workspace data isolation.',
    decisions: ['Agreed on SOC2 compliance timeline', 'Provided custom export options in PDF/DOCX'],
    actionItems: ['Send contract draft - Legal (May 2)', 'Follow up on technical onboarding - Ali (May 4)'],
  ),
  MeetingModel(
    id: 3,
    title: 'Team Standup',
    date: 'Apr 24, 2025',
    duration: '18 min',
    tag: 'Team',
    summary: 'Daily progress check-in across engineering and design sprints. All blockers resolved.',
    decisions: ['Merged backend PRs into staging', 'Scheduled design system sign-off'],
    actionItems: ['Code review for PWA service worker - Lead Dev'],
  ),
];

class MeetingNotifier extends StateNotifier<List<MeetingModel>> {
  MeetingNotifier() : super(initialMeetings);

  void addMeeting(MeetingModel meeting) {
    state = [meeting, ...state];
  }

  void deleteMeeting(int id) {
    state = state.where((m) => m.id != id).toList();
  }
}

final meetingProvider = StateNotifierProvider<MeetingNotifier, List<MeetingModel>>((ref) {
  return MeetingNotifier();
});

final themeModeProvider = StateProvider<bool>((ref) => false); // false = light, true = dark
