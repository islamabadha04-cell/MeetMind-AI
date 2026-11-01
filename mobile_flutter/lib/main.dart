import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }
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
        extendBody: true,
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: FloatingFrostedNavBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) {
            setState(() => _currentIndex = idx);
          },
          lang: lang,
          isDark: Theme.of(context).brightness == Brightness.dark,
        ),
      ),
    );
  }
}

/// Floating Frosted Glass Pill Navigation Bar (Phase 6C Design System)
class FloatingFrostedNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final AppLanguage lang;
  final bool isDark;

  const FloatingFrostedNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.lang,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: (isDark ? const Color(0xFF141728) : Colors.white)
              .withValues(alpha: 0.92),
          border: Border.all(
            color: isDark ? const Color(0xFF262C47) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(
                    index: 0,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: AppStrings.get('nav_home', lang),
                  ),
                  _navItem(
                    index: 1,
                    icon: Icons.calendar_today_outlined,
                    activeIcon: Icons.calendar_today_rounded,
                    label: AppStrings.get('nav_meetings', lang),
                  ),
                  _centerAction(context),
                  _navItem(
                    index: 3,
                    icon: Icons.task_alt_outlined,
                    activeIcon: Icons.task_alt_rounded,
                    label: AppStrings.get('nav_tasks', lang),
                  ),
                  _navItem(
                    index: 4,
                    icon: Icons.auto_awesome_outlined,
                    activeIcon: Icons.auto_awesome,
                    label: AppStrings.get('nav_ask_ai', lang),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = selectedIndex == index;
    if (isSelected) {
      return GestureDetector(
        onTap: () => onDestinationSelected(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: AppColors.buttonGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.45),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(activeIcon, color: Colors.white, size: 19),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return IconButton(
      icon: Icon(
        icon,
        size: 22,
        color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
      ),
      onPressed: () => onDestinationSelected(index),
      tooltip: label,
    );
  }

  Widget _centerAction(BuildContext context) {
    return GestureDetector(
      onTap: () => onDestinationSelected(2),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF06B6D4).withValues(alpha: 0.45),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.mic, color: Colors.white, size: 22),
      ),
    );
  }
}
