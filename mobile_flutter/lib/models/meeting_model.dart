class MeetingModel {
  final int id;
  final String title;
  final String date;
  final String duration;
  final String tag;
  final String summary;
  final List<String> decisions;
  final List<String> actionItems;

  MeetingModel({
    required this.id,
    required this.title,
    required this.date,
    required this.duration,
    required this.tag,
    required this.summary,
    required this.decisions,
    required this.actionItems,
  });

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      duration: json['duration'] ?? '',
      tag: json['tag'] ?? 'Work',
      summary: json['summary'] ?? '',
      decisions: List<String>.from(json['decisions'] ?? []),
      actionItems: List<String>.from(json['actionItems'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'duration': duration,
      'tag': tag,
      'summary': summary,
      'decisions': decisions,
      'actionItems': actionItems,
    };
  }
}
