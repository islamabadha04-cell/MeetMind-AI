import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/colors.dart';
import '../core/localization/app_strings.dart';
import '../core/localization/language_provider.dart';
import '../core/services/api_client.dart';
import '../core/services/secure_storage_service.dart';
import '../providers/auth_provider.dart';
import '../providers/meeting_provider.dart';
import '../providers/vault_provider.dart';
import 'vault_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadApiUrl();
  }

  void _loadApiUrl() async {
    final custom = await SecureStorageService.getCustomApiUrl();
    _apiUrlController.text = custom ?? ApiClient.defaultRemoteStagingUrl;
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }

  void _saveApiUrl() async {
    final url = _apiUrlController.text.trim();
    await SecureStorageService.saveCustomApiUrl(url);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Base URL updated!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isUrdu = lang == AppLanguage.urdu;
    final isDark = ref.watch(themeModeProvider);
    final authState = ref.watch(authProvider);
    final vaultState = ref.watch(vaultProvider);
    final user = authState.user;

    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get('nav_settings', lang)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // User Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: const Icon(Icons.person, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.fullName ?? 'Emily Watson', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(user?.email ?? 'emily@example.com', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${user?.plan ?? 'Pro'} Plan • 500 Minutes Available',
                              style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Theme Setting
            Card(
              child: SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: Text(isDark ? 'Dark theme active' : 'Light soft pastel theme active'),
                value: isDark,
                onChanged: (val) => ref.read(themeModeProvider.notifier).state = val,
                secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 12),

            // Language Selector
            Card(
              child: ListTile(
                leading: const Icon(Icons.language, color: AppColors.primary),
                title: const Text('Application Language'),
                subtitle: Text(
                  lang == AppLanguage.urdu
                      ? 'اردو (Nastaliq RTL)'
                      : (lang == AppLanguage.romanUrdu ? 'Roman Urdu' : 'English'),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => SimpleDialog(
                      title: const Text('Select Language'),
                      children: [
                        SimpleDialogOption(
                          onPressed: () {
                            ref.read(languageProvider.notifier).setLanguage(AppLanguage.english);
                            Navigator.pop(ctx);
                          },
                          child: const Text('English'),
                        ),
                        SimpleDialogOption(
                          onPressed: () {
                            ref.read(languageProvider.notifier).setLanguage(AppLanguage.urdu);
                            Navigator.pop(ctx);
                          },
                          child: const Text('اردو (Nastaliq RTL)'),
                        ),
                        SimpleDialogOption(
                          onPressed: () {
                            ref.read(languageProvider.notifier).setLanguage(AppLanguage.romanUrdu);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Roman Urdu'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Offline Vault Shortcut
            Card(
              child: ListTile(
                leading: Badge(
                  isLabelVisible: vaultState.pendingUploadCount > 0,
                  label: Text('${vaultState.pendingUploadCount}'),
                  child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                ),
                title: Text(AppStrings.get('vault_title', lang)),
                subtitle: Text('${vaultState.recordings.length} recordings cached locally'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const VaultScreen()));
                },
              ),
            ),
            const SizedBox(height: 12),

            // Custom Backend URL
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Backend API Gateway Endpoint', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('Default: Cloudflare Ingress Staging URL', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _apiUrlController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.save, size: 16),
                        label: const Text('Save Endpoint'),
                        onPressed: _saveApiUrl,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: Text(AppStrings.get('btn_logout', lang), style: const TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                ref.read(authProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
