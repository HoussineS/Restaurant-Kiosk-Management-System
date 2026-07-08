import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:window_manager/window_manager.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../menu/presentation/providers/menu_providers.dart';
import '../../../menu/presentation/widgets/admin_scaffold.dart';
import '../../../orders/presentation/providers/order_providers.dart';
import '../../../orders/utils/printer_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isBackingUp = false;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _loadWindowState();
  }

  Future<void> _loadWindowState() async {
    final isFullscreen = await windowManager.isFullScreen();
    if (mounted) {
      setState(() => _isFullscreen = isFullscreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(allOrdersProvider);

    return AdminPageLayout(
      title: 'Settings',
      subtitle: 'Back up data, print reports, and control kiosk mode.',
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _SettingsSection(
            title: 'Data',
            children: [
              _SettingsTile(
                icon: Icons.backup_outlined,
                title: 'Database Backup',
                subtitle: 'Copy the local SQLite database to a folder.',
                trailing: FilledButton.icon(
                  onPressed: _isBackingUp ? null : _backupDatabase,
                  icon: _isBackingUp
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.folder_copy_outlined),
                  label: const Text('Back Up'),
                ),
              ),
              _SettingsTile(
                icon: Icons.refresh,
                title: 'Refresh App Data',
                subtitle: 'Reload menu, orders, kitchen queue, and dashboard.',
                trailing: OutlinedButton.icon(
                  onPressed: () {
                    ref.invalidate(categoriesControllerProvider);
                    ref.invalidate(productsControllerProvider);
                    ref.invalidate(ordersControllerProvider);
                    ref.invalidate(allOrdersProvider);
                    _showMessage('Data refreshed.');
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Reports',
            children: [
              _SettingsTile(
                icon: Icons.print_outlined,
                title: 'Print Sales Summary',
                subtitle: ordersState.maybeWhen(
                  data: (orders) => '${orders.length} orders available',
                  orElse: () => 'Loads all saved orders.',
                ),
                trailing: OutlinedButton.icon(
                  onPressed: ordersState.maybeWhen(
                    data: (orders) => orders.isEmpty
                        ? null
                        : () => PrinterService.printSummary(orders, null, null),
                    orElse: () => null,
                  ),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Print'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Kiosk',
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.fullscreen),
                title: const Text('Fullscreen Mode'),
                subtitle: const Text(
                  'Useful for locked-down touchscreen kiosks.',
                ),
                value: _isFullscreen,
                onChanged: (value) async {
                  await windowManager.setFullScreen(value);
                  setState(() => _isFullscreen = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'System',
            children: [
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'Restaurant Kiosk Management System',
                subtitle:
                    'Offline desktop kiosk with menu, POS, kitchen, reports, and local backup.',
                trailing: Text(DateFormat('yyyy').format(DateTime.now())),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _backupDatabase() async {
    final directory = await FilePicker.getDirectoryPath(
      dialogTitle: 'Choose backup folder',
    );
    if (directory == null) {
      return;
    }

    setState(() => _isBackingUp = true);
    try {
      final result = await ref
          .read(databaseMaintenanceServiceProvider)
          .backupToDirectory(directory);
      if (!mounted) return;
      _showMessage(
        'Backup saved: ${result.files.length} file(s) in ${result.directoryPath}',
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage('Backup failed: $error');
    } finally {
      if (mounted) {
        setState(() => _isBackingUp = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
