import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/colors.dart';
import 'core/localization/language_provider.dart';
import 'core/services/background_sync_engine.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/meeting_provider.dart';
import 'providers/vault_provider.dart';
import 'screens/chat_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/integrations_screen.dart';
import 'screens/login_screen.dart';
import 'screens/meetings_screen.dart';
import 'screens/memory_screen.dart';
import 'screens/recording_studio_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/vault_screen.dart';
import 'screens/workspace_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  BackgroundSyncEngine().initialize();
  runApp(const ProviderScope(child: MeetMindApp()));
}

class MeetMindApp extends ConsumerWidget {
  const MeetMindApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    final lang = ref.watch(languageProvider);
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'MeetMind AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(lang),
      darkTheme: AppTheme.getDarkTheme(lang),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: authState.isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : authState.isAuthenticated
              ? const MainNavigationShell()
              : const LoginScreen(),
    );
  }
}

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    MeetingsScreen(),
    RecordingStudioScreen(),
    TasksScreen(),
    ChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final vaultState = ref.watch(vaultProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isUrdu = lang == AppLanguage.urdu;

    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                accountName: Text(user?.fullName ?? 'Emily Watson', style: const TextStyle(fontWeight: FontWeight.bold)),
                accountEmail: Text(user?.email ?? 'emily@example.com'),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.psychology, color: AppColors.primary, size: 36),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard_outlined),
                title: Text(AppStrings.get('nav_home', lang)),
                selected: _currentIndex == 0,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: Text(AppStrings.get('nav_meetings', lang)),
                selected: _currentIndex == 1,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.mic_none),
                title: Text(AppStrings.get('nav_record', lang)),
                selected: _currentIndex == 2,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 2);
                },
              ),
              ListTile(
                leading: const Icon(Icons.task_alt),
                title: Text(AppStrings.get('nav_tasks', lang)),
                selected: _currentIndex == 3,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 3);
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: Text(AppStrings.get('nav_ask_ai', lang)),
                selected: _currentIndex == 4,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 4);
                },
              ),
              const Divider(),
              ListTile(
                leading: Badge(
                  isLabelVisible: vaultState.pendingUploadCount > 0,
                  label: Text('${vaultState.pendingUploadCount}'),
                  child: const Icon(Icons.inventory_2_outlined),
                ),
                title: Text(AppStrings.get('vault_title', lang)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const VaultScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.psychology_outlined),
                title: Text(AppStrings.get('nav_memory', lang)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MemoryScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.search),
                title: Text(AppStrings.get('nav_search', lang)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.business_outlined),
                title: Text(AppStrings.get('nav_workspaces', lang)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkspaceScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.hub_outlined),
                title: Text(AppStrings.get('nav_integrations', lang)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const IntegrationsScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: Text(AppStrings.get('nav_settings', lang)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                },
              ),
            ],
          ),
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) {
            setState(() => _currentIndex = idx);
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard),
              label: AppStrings.get('nav_home', lang),
            ),
            NavigationDestination(
              icon: const Icon(Icons.groups_outlined),
              selectedIcon: const Icon(Icons.groups),
              label: AppStrings.get('nav_meetings', lang),
            ),
            NavigationDestination(
              icon: const Icon(Icons.mic_none_outlined),
              selectedIcon: const Icon(Icons.mic),
              label: AppStrings.get('nav_record', lang),
            ),
            NavigationDestination(
              icon: const Icon(Icons.task_alt),
              selectedIcon: const Icon(Icons.check_circle),
              label: AppStrings.get('nav_tasks', lang),
            ),
            NavigationDestination(
              icon: const Icon(Icons.chat_bubble_outline),
              selectedIcon: const Icon(Icons.chat_bubble),
              label: AppStrings.get('nav_ask_ai', lang),
            ),
          ],
        ),
      ),
    );
  }
}
