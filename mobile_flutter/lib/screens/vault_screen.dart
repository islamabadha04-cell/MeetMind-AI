import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/colors.dart';
import '../core/localization/app_strings.dart';
import '../core/localization/language_provider.dart';
import '../core/services/background_sync_engine.dart';
import '../models/vault_recording_model.dart';
import '../providers/vault_provider.dart';

class VaultScreen extends ConsumerWidget {
  const VaultScreen({super.key});

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final vaultState = ref.watch(vaultProvider);
    final isUrdu = lang == AppLanguage.urdu;

    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get('vault_title', lang)),
          actions: [
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Sync All Pending',
              onPressed: () {
                BackgroundSyncEngine().triggerSync(reason: 'Manual sync tap');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Checking cloud connectivity and synchronizing vault...')),
                );
              },
            ),
          ],
        ),
        body: vaultState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : vaultState.recordings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Your Offline Vault is empty',
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Recordings you take offline will be stored safely here.',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: vaultState.recordings.length,
                    itemBuilder: (context, index) {
                      final item = vaultState.recordings[index];
                      return _buildVaultCard(context, ref, item, lang);
                    },
                  ),
      ),
    );
  }

  Widget _buildVaultCard(BuildContext context, WidgetRef ref, VaultRecordingModel item, AppLanguage lang) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (item.syncState) {
      case VaultSyncState.synced:
        statusColor = AppColors.success;
        statusIcon = Icons.cloud_done;
        statusText = AppStrings.get('status_synced', lang);
        break;
      case VaultSyncState.uploading:
        statusColor = AppColors.primary;
        statusIcon = Icons.cloud_upload;
        statusText = AppStrings.get('status_uploading', lang);
        break;
      case VaultSyncState.waitingForConnection:
        statusColor = AppColors.warning;
        statusIcon = Icons.wifi_off;
        statusText = AppStrings.get('status_waiting_conn', lang);
        break;
      case VaultSyncState.failed:
      case VaultSyncState.retryRequired:
        statusColor = AppColors.error;
        statusIcon = Icons.error_outline;
        statusText = AppStrings.get('status_failed', lang);
        break;
      case VaultSyncState.localOnly:
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.phone_android;
        statusText = AppStrings.get('status_local_only', lang);
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Metadata row
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(_formatDuration(item.durationSeconds), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(width: 14),
                Icon(Icons.save_outlined, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(_formatBytes(item.fileSizeBytes), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(width: 14),
                Icon(Icons.verified_outlined, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  item.sha256Checksum.isNotEmpty ? 'SHA: ${item.sha256Checksum.substring(0, 8)}...' : 'Unchecked',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),

            if (item.lastError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: AppColors.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Retry count: ${item.retryCount} • ${item.lastError}',
                        style: const TextStyle(color: AppColors.error, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (item.syncState != VaultSyncState.synced)
                  TextButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry Upload', style: TextStyle(fontSize: 12)),
                    onPressed: () => ref.read(vaultProvider.notifier).retryUpload(item.id),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                  tooltip: 'Delete Local Recording',
                  onPressed: () {
                    ref.read(vaultProvider.notifier).deleteRecording(item.id);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
