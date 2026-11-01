class TranscriptTurn {
  final String speaker;
  final String timestamp;
  final String text;

  TranscriptTurn({
    required this.speaker,
    required this.timestamp,
    required this.text,
  });

  factory TranscriptTurn.fromJson(Map<String, dynamic> json) {
    return TranscriptTurn(
      speaker: json['speaker'] ?? 'Speaker',
      timestamp: json['timestamp'] ?? '00:00',
      text: json['text'] ?? '',
    );
  }
}

class MeetingDetailModel {
  final int id;
  final String title;
  final String meetingDate;
  final int durationSeconds;
  final String category;
  final String executiveSummary;
  final String urduSummary;
  final String romanUrduSummary;
  final List<String> decisions;
  final List<String> actionItems;
  final List<String> risks;
  final List<TranscriptTurn> transcript;
  final String? audioUrl;

  MeetingDetailModel({
    required this.id,
    required this.title,
    required this.meetingDate,
    required this.durationSeconds,
    required this.category,
    required this.executiveSummary,
    required this.urduSummary,
    required this.romanUrduSummary,
    required this.decisions,
    required this.actionItems,
    required this.risks,
    required this.transcript,
    this.audioUrl,
  });

  factory MeetingDetailModel.fromJson(Map<String, dynamic> json) {
    final rawDecisions = json['decisions'];
    final rawActions = json['action_items'];
    final rawRisks = json['risks'];
    final rawTranscript = json['transcript_turns'] as List<dynamic>?;

    return MeetingDetailModel(
      id: json['id'] ?? 1,
      title: json['title'] ?? 'Meeting',
      meetingDate: json['meeting_date'] ?? 'Today',
      durationSeconds: json['duration_seconds'] ?? 0,
      category: json['category'] ?? 'General',
      executiveSummary: json['executive_summary'] ?? 'Meeting notes and discussion.',
      urduSummary: json['urdu_summary'] ?? 'میٹنگ کے دوران اہم امور پر تبادلہ خیال کیا گیا۔',
      romanUrduSummary: json['roman_urdu_summary'] ?? 'Meeting mein ahem topics par baat cheet hui.',
      decisions: rawDecisions is List ? rawDecisions.map((e) => e.toString()).toList() : [],
      actionItems: rawActions is List ? rawActions.map((e) => e.toString()).toList() : [],
      risks: rawRisks is List ? rawRisks.map((e) => e.toString()).toList() : [],
      transcript: rawTranscript != null
          ? rawTranscript.map((e) => TranscriptTurn.fromJson(e as Map<String, dynamic>)).toList()
          : [],
      audioUrl: json['audio_url'],
    );
  }
}
