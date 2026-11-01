import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/colors.dart';
import '../core/localization/language_provider.dart';
import '../core/services/workspace_service.dart';

class WorkspaceScreen extends ConsumerStatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  List<WorkspaceModel> _workspaces = [];
  List<CollaborativeNoteModel> _notes = [];
  bool _isLoading = true;
  final _noteTitleController = TextEditingController();
  final _noteContentController = TextEditingController();
  int _activeNoteVersion = 1;
  int _activeNoteId = 1;

  @override
  void initState() {
    super.initState();
    _fetchWorkspaceData();
  }

  @override
  void dispose() {
    _noteTitleController.dispose();
    _noteContentController.dispose();
    super.dispose();
  }

  Future<void> _fetchWorkspaceData() async {
    setState(() => _isLoading = true);
    try {
      final wsList = await WorkspaceService.getWorkspaces();
      if (wsList.isNotEmpty) {
        final notes = await WorkspaceService.getNotes(wsList[0].id);
        if (notes.isNotEmpty) {
          _noteTitleController.text = notes[0].title;
          _noteContentController.text = notes[0].content;
          _activeNoteVersion = notes[0].version;
          _activeNoteId = notes[0].id;
        }
        if (mounted) {
          setState(() {
            _workspaces = wsList;
            _notes = notes;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _saveNote() async {
    if (_workspaces.isEmpty) return;
    try {
      final updated = await WorkspaceService.updateNote(
        workspaceId: _workspaces[0].id,
        noteId: _activeNoteId,
        title: _noteTitleController.text.trim(),
        content: _noteContentController.text.trim(),
        version: _activeNoteVersion,
      );
      setState(() => _activeNoteVersion = updated.version);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Collaborative Note saved (v${updated.version})! Synced to Web.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to save note: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showInviteModal() {
    final emailController = TextEditingController();
    String role = 'editor';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
              const Text('Invite Teammate',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                    labelText: 'Email Address', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(
                    labelText: 'Role Permission', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(
                      value: 'admin',
                      child: Text('Admin (Manage Team & Settings)')),
                  DropdownMenuItem(
                      value: 'manager',
                      child: Text('Manager (Approve Action Items)')),
                  DropdownMenuItem(
                      value: 'editor',
                      child: Text('Editor (Create & Edit Notes)')),
                  DropdownMenuItem(
                      value: 'viewer', child: Text('Viewer (Read Only)')),
                ],
                onChanged: (val) => setModalState(() => role = val ?? 'editor'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (emailController.text.trim().isEmpty) return;
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);
                  try {
                    await WorkspaceService.inviteTeammate(
                      workspaceId: _workspaces[0].id,
                      email: emailController.text.trim(),
                      role: role,
                    );
                    _fetchWorkspaceData();
                    messenger.showSnackBar(
                      const SnackBar(
                          content: Text('Invitation sent successfully!')),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(
                          content: Text('Invite failed: $e'),
                          backgroundColor: AppColors.error),
                    );
                  }
                },
                child: const Text('Send Invitation'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isUrdu = lang == AppLanguage.urdu;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final ws = _workspaces.isNotEmpty
        ? _workspaces[0]
        : WorkspaceModel(
            id: 1,
            name: 'Cowlar Engineering',
            slug: 'cowlar-engineering',
            tier: 'Team',
            ownerName: 'Emily Watson',
            currentUserRole: 'owner',
            activeSeats: 4,
            maxSeats: 10,
            members: [
              WorkspaceMemberModel(
                  id: 1,
                  userId: 1,
                  email: 'emily@example.com',
                  fullName: 'Emily Watson',
                  role: 'owner'),
              WorkspaceMemberModel(
                  id: 2,
                  userId: 2,
                  email: 'sarah@example.com',
                  fullName: 'Sarah Jenkins',
                  role: 'admin'),
              WorkspaceMemberModel(
                  id: 3,
                  userId: 3,
                  email: 'ali@example.com',
                  fullName: 'Hasnain Ali',
                  role: 'editor'),
              WorkspaceMemberModel(
                  id: 4,
                  userId: 4,
                  email: 'usman@example.com',
                  fullName: 'Usman Tariq',
                  role: 'viewer'),
            ],
          );

    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get('nav_workspaces', lang)),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add_alt_1_outlined),
              tooltip: 'Invite Teammate',
              onPressed: _showInviteModal,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Workspace Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ws.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          ws.tier.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Owner: ${ws.ownerName} • Role: ${ws.currentUserRole.toUpperCase()}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Seats: ${ws.members.length} / ${ws.maxSeats} active',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Collaborative Notes Pad
            Text('Collaborative Note Pad (${_notes.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _noteTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Note Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _noteContentController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Markdown Content',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                        label: Text('Save Note (v$_activeNoteVersion)'),
                        onPressed: _saveNote,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Teammates Roster
            const Text('Team Members & RBAC Roles',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...ws.members.map((m) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(m.fullName.substring(0, 1),
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold)),
                  ),
                  title: Text(m.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(m.email, style: const TextStyle(fontSize: 12)),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      m.role.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
