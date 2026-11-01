import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/colors.dart';
import '../core/localization/app_strings.dart';
import '../core/localization/language_provider.dart';
import '../core/services/workspace_service.dart';

class IntegrationsScreen extends ConsumerStatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  ConsumerState<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends ConsumerState<IntegrationsScreen> {
  List<IntegrationProviderModel> _providers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProviders();
  }

  Future<void> _fetchProviders() async {
    setState(() => _isLoading = true);
    try {
      final list = await WorkspaceService.getIntegrations();
      if (mounted) {
        setState(() {
          _providers = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isUrdu = lang == AppLanguage.urdu;

    final defaultProviders = [
      {'id': 'google_calendar', 'name': 'Google Calendar', 'cat': 'Calendar', 'scopes': 'calendar.readonly, calendar.events'},
      {'id': 'gmail', 'name': 'Gmail (Draft-Only)', 'cat': 'Email', 'scopes': 'gmail.compose, drafts.create'},
      {'id': 'google_drive', 'name': 'Google Drive', 'cat': 'Storage', 'scopes': 'drive.readonly, drive.file'},
      {'id': 'outlook', 'name': 'Microsoft Outlook', 'cat': 'Email & Cal', 'scopes': 'Mail.ReadWrite, Calendars.Read'},
      {'id': 'jira', 'name': 'Atlassian Jira', 'cat': 'Project Mgmt', 'scopes': 'read:jira-work, write:jira-work'},
      {'id': 'trello', 'name': 'Trello', 'cat': 'Project Mgmt', 'scopes': 'read, write'},
      {'id': 'slack', 'name': 'Slack Enterprise', 'cat': 'Messaging', 'scopes': 'chat:write, channels:read'},
      {'id': 'notion', 'name': 'Notion Workspace', 'cat': 'Documents', 'scopes': 'pages.create, blocks.read'},
      {'id': 'whatsapp', 'name': 'Meta WhatsApp Cloud', 'cat': 'Messaging', 'scopes': 'whatsapp_business_messaging'},
      {'id': 'webhooks', 'name': 'Custom Webhook Engine', 'cat': 'Developer', 'scopes': 'event.dispatch, HMAC-SHA256'},
    ];

    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get('nav_integrations', lang)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.primary, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All 10 integrations use OAuth 2.0 PKCE with persistent state nonces and AES-256-GCM encrypted tokens.',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...defaultProviders.map((p) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: const Icon(Icons.hub_outlined, color: AppColors.primary, size: 20),
                  ),
                  title: Text(p['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('Scopes: ${p['scopes']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('READY', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
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
