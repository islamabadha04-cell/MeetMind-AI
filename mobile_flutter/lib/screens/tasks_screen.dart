import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/colors.dart';
import '../core/localization/app_strings.dart';
import '../core/localization/language_provider.dart';
import '../core/services/meeting_service.dart';
import '../models/task_model.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  List<TaskModel> _tasks = [];
  bool _isLoading = true;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    try {
      final list = await MeetingService.getTasks();
      if (mounted) {
        setState(() {
          _tasks = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddTaskModal() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final assigneeController = TextEditingController(text: 'Emily Watson');
    final deadlineController = TextEditingController(text: 'Friday 5:00 PM');
    String priority = 'high';
    String project = 'Core Sprint';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add New Action Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Task Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description / Context', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: assigneeController,
                      decoration: const InputDecoration(labelText: 'Assignee', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: deadlineController,
                      decoration: const InputDecoration(labelText: 'Deadline', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: priority,
                decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'urgent', child: Text('🔴 Urgent')),
                  DropdownMenuItem(value: 'high', child: Text('🟠 High')),
                  DropdownMenuItem(value: 'medium', child: Text('🟡 Medium')),
                  DropdownMenuItem(value: 'low', child: Text('🟢 Low')),
                ],
                onChanged: (val) => setModalState(() => priority = val ?? 'high'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  try {
                    await MeetingService.createTask(
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      assignee: assigneeController.text.trim(),
                      deadline: deadlineController.text.trim(),
                      priority: priority,
                      project: project,
                    );
                    _fetchTasks();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Task created & synced across mobile and web!')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save task: $e'), backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
                child: const Text('Save Action Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleTaskStatus(TaskModel task) async {
    final nextStatus = task.status == 'completed' ? 'pending' : 'completed';
    try {
      await MeetingService.updateTaskStatus(task.id, nextStatus);
      _fetchTasks();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isUrdu = lang == AppLanguage.urdu;

    final filtered = _tasks.where((t) {
      if (_selectedStatus == 'all') return true;
      return t.status == _selectedStatus;
    }).toList();

    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get('nav_tasks', lang)),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add Task',
              onPressed: _showAddTaskModal,
            ),
          ],
        ),
        body: Column(
          children: [
            // Status Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _filterChip('all', 'All (${_tasks.length})'),
                  _filterChip('pending', 'Pending (${_tasks.where((t) => t.status == 'pending').length})'),
                  _filterChip('in_progress', 'In Progress (${_tasks.where((t) => t.status == 'in_progress').length})'),
                  _filterChip('completed', 'Completed (${_tasks.where((t) => t.status == 'completed').length})'),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text('No action items in this column', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchTasks,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final task = filtered[i];
                              final isCompleted = task.status == 'completed';

                              Color priorityColor;
                              switch (task.priority) {
                                case 'urgent':
                                  priorityColor = AppColors.error;
                                  break;
                                case 'high':
                                  priorityColor = AppColors.warning;
                                  break;
                                default:
                                  priorityColor = Colors.blue;
                                  break;
                              }

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                          color: isCompleted ? AppColors.success : Colors.grey,
                                        ),
                                        onPressed: () => _toggleTaskStatus(task),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              task.title,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                                                color: isCompleted ? Colors.grey : null,
                                              ),
                                            ),
                                            if (task.description.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(task.description, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                            ],
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: priorityColor.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    task.priority.toUpperCase(),
                                                    style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(Icons.person_outline, size: 12, color: Colors.grey.shade500),
                                                const SizedBox(width: 4),
                                                Text(task.assignee, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                                                const SizedBox(width: 12),
                                                Icon(Icons.schedule, size: 12, color: Colors.grey.shade500),
                                                const SizedBox(width: 4),
                                                Text(task.deadline, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String status, String label) {
    final isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        selected: isSelected,
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        labelStyle: TextStyle(color: isSelected ? AppColors.primary : Colors.grey.shade700),
        onSelected: (_) => setState(() => _selectedStatus = status),
      ),
    );
  }
}
