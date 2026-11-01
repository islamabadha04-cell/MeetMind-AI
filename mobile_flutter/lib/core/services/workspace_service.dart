import 'api_client.dart';

class WorkspaceMemberModel {
  final int id;
  final int userId;
  final String email;
  final String fullName;
  final String role; // owner, admin, manager, editor, viewer

  WorkspaceMemberModel({
    required this.id,
    required this.userId,
    required this.email,
    required this.fullName,
    required this.role,
  });

  factory WorkspaceMemberModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceMemberModel(
      id: json['id'] ?? 1,
      userId: json['user_id'] ?? 1,
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? 'Teammate',
      role: json['role'] ?? 'viewer',
    );
  }
}

class CollaborativeNoteModel {
  final int id;
  final String title;
  final String content;
  final int version;
  final String lastEditedByName;

  CollaborativeNoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.version,
    required this.lastEditedByName,
  });

  factory CollaborativeNoteModel.fromJson(Map<String, dynamic> json) {
    return CollaborativeNoteModel(
      id: json['id'] ?? 1,
      title: json['title'] ?? 'Team Notes',
      content: json['content'] ?? '',
      version: json['version'] ?? 1,
      lastEditedByName: json['last_edited_by_name'] ?? 'Teammate',
    );
  }
}

class WorkspaceModel {
  final int id;
  final String name;
  final String slug;
  final String tier;
  final String ownerName;
  final String currentUserRole;
  final int activeSeats;
  final int maxSeats;
  final List<WorkspaceMemberModel> members;

  WorkspaceModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.tier,
    required this.ownerName,
    required this.currentUserRole,
    required this.activeSeats,
    required this.maxSeats,
    required this.members,
  });

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'] as List<dynamic>?;
    return WorkspaceModel(
      id: json['id'] ?? 1,
      name: json['name'] ?? 'Workspace',
      slug: json['slug'] ?? 'workspace',
      tier: json['tier'] ?? 'Team',
      ownerName: json['owner_name'] ?? 'Owner',
      currentUserRole: json['current_user_role'] ?? 'viewer',
      activeSeats: json['active_seats'] ?? 1,
      maxSeats: json['max_seats'] ?? 10,
      members: rawMembers != null
          ? rawMembers.map((e) => WorkspaceMemberModel.fromJson(e as Map<String, dynamic>)).toList()
          : [],
    );
  }
}

class IntegrationProviderModel {
  final String id;
  final String name;
  final String category;
  final String status; // connected, disconnected
  final String authType;
  final List<String> scopes;

  IntegrationProviderModel({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.authType,
    required this.scopes,
  });

  factory IntegrationProviderModel.fromJson(Map<String, dynamic> json) {
    return IntegrationProviderModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      status: json['status'] ?? 'disconnected',
      authType: json['auth_type'] ?? 'oauth2',
      scopes: (json['scopes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class WorkspaceService {
  static Future<List<WorkspaceModel>> getWorkspaces() async {
    final response = await ApiClient.get('/workspaces');
    if (response is List) {
      return response.map((e) => WorkspaceModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<List<CollaborativeNoteModel>> getNotes(int workspaceId) async {
    final response = await ApiClient.get('/workspaces/$workspaceId/notes');
    if (response is List) {
      return response.map((e) => CollaborativeNoteModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<CollaborativeNoteModel> updateNote({
    required int workspaceId,
    required int noteId,
    required String title,
    required String content,
    required int version,
  }) async {
    final response = await ApiClient.put('/workspaces/$workspaceId/notes/$noteId', body: {
      'title': title,
      'content': content,
      'version': version,
    });
    return CollaborativeNoteModel.fromJson(response as Map<String, dynamic>);
  }

  static Future<void> inviteTeammate({
    required int workspaceId,
    required String email,
    required String role,
  }) async {
    await ApiClient.post('/workspaces/$workspaceId/invites', body: {
      'email': email.trim(),
      'role': role,
    });
  }

  static Future<List<IntegrationProviderModel>> getIntegrations() async {
    final response = await ApiClient.get('/integrations/providers');
    if (response is List) {
      return response.map((e) => IntegrationProviderModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }
}

