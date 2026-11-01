import 'dart:convert';
import 'api_client.dart';
import '../../models/meeting_detail_model.dart';
import '../../models/task_model.dart';

class SearchResultHit {
  final int meetingId;
  final String meetingTitle;
  final String excerpt;
  final double score;

  SearchResultHit({
    required this.meetingId,
    required this.meetingTitle,
    required this.excerpt,
    required this.score,
  });

  factory SearchResultHit.fromJson(Map<String, dynamic> json) {
    return SearchResultHit(
      meetingId: json['meeting_id'] ?? 1,
      meetingTitle: json['meeting_title'] ?? 'Meeting',
      excerpt: json['excerpt'] ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MemoryItem {
  final int id;
  final String category;
  final String factStatement;
  final String meetingTitle;
  final String timestamp;
  final String confidence;

  MemoryItem({
    required this.id,
    required this.category,
    required this.factStatement,
    required this.meetingTitle,
    required this.timestamp,
    required this.confidence,
  });

  factory MemoryItem.fromJson(Map<String, dynamic> json) {
    return MemoryItem(
      id: json['id'] ?? 1,
      category: json['category'] ?? 'General',
      factStatement: json['fact_statement'] ?? '',
      meetingTitle: json['meeting_title'] ?? 'Meeting',
      timestamp: json['timestamp'] ?? '00:00',
      confidence: json['confidence'] ?? '0.95',
    );
  }
}

class MeetingService {
  static Future<List<MeetingDetailModel>> getMeetings() async {
    final response = await ApiClient.get('/meetings');
    if (response is List) {
      return response.map((e) => MeetingDetailModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<MeetingDetailModel> getMeetingDetail(int id) async {
    final response = await ApiClient.get('/meetings/$id');
    return MeetingDetailModel.fromJson(response as Map<String, dynamic>);
  }

  static Future<List<TaskModel>> getTasks() async {
    final response = await ApiClient.get('/tasks');
    if (response is List) {
      return response.map((e) => TaskModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<TaskModel> createTask({
    required String title,
    required String description,
    required String assignee,
    required String deadline,
    required String priority,
    required String project,
  }) async {
    final response = await ApiClient.post('/tasks', body: {
      'title': title,
      'description': description,
      'assignee': assignee,
      'deadline': deadline,
      'priority': priority,
      'project': project,
    });
    return TaskModel.fromJson(response as Map<String, dynamic>);
  }

  static Future<void> updateTaskStatus(int id, String newStatus) async {
    await ApiClient.put('/tasks/$id', body: {'status': newStatus});
  }

  static Future<List<SearchResultHit>> searchMeetings(String query) async {
    final response = await ApiClient.post('/search/meetings', body: {
      'query': query,
      'limit': 6,
    });
    if (response is Map && response['results'] is List) {
      final list = response['results'] as List;
      return list.map((e) => SearchResultHit.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<List<MemoryItem>> getMemories() async {
    final response = await ApiClient.get('/memory');
    if (response is List) {
      return response.map((e) => MemoryItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<String> askAiChat({
    required String message,
    String provider = 'gemini', // 'gemini' or 'ollama'
  }) async {
    if (provider == 'ollama') {
      try {
        final res = await ApiClient.post('/ai/ollama/chat', body: {'prompt': message});
        return (res is Map ? res['reply'] : res.toString()) ?? 'No reply from Ollama.';
      } on ApiException catch (e) {
        if (e.statusCode == 402) {
          return '⚠️ Ollama Cloud Notice: Account usage credits are needed at https://ollama.com/plans to call glm-5.3-flash. Falling back to Google Gemini...';
        }
        rethrow;
      }
    }

    final response = await ApiClient.post('/search/chat', body: {
      'message': message,
      'history': [],
    });
    return (response is Map ? response['response'] : response.toString()) ?? 'I have reviewed your meeting transcripts.';
  }
}
