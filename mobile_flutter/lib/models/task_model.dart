class TaskModel {
  final int id;
  final String title;
  final String description;
  final String assignee;
  final String deadline;
  final String priority; // low, medium, high, urgent
  final String status; // pending, in_progress, completed
  final String project;
  final bool isApproved;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.assignee,
    required this.deadline,
    required this.priority,
    required this.status,
    required this.project,
    required this.isApproved,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? 1,
      title: json['title'] ?? 'Action Item',
      description: json['description'] ?? '',
      assignee: json['assignee'] ?? 'Unassigned',
      deadline: json['deadline'] ?? 'No deadline',
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'pending',
      project: json['project'] ?? 'General',
      isApproved: json['is_approved'] ?? true,
    );
  }

  TaskModel copyWith({String? status, bool? isApproved}) {
    return TaskModel(
      id: id,
      title: title,
      description: description,
      assignee: assignee,
      deadline: deadline,
      priority: priority,
      status: status ?? this.status,
      project: project,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}
