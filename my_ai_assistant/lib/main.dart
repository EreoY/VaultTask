import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html; 

import 'firebase_options.dart';
import 'config/env_config.dart';
import 'state_managers/state_boards.dart';
import 'state_managers/state_tasks.dart';
import 'state_managers/state_chat.dart';
import 'ui/theme/glass_theme.dart';
import 'ui/common/glass_widgets.dart';
import 'ui/common/aether_side_nav.dart';
import 'ui/chat/chat_page.dart';
import 'ui/dashboard/dashboard_page.dart';
import 'ui/kanban/kanban_page.dart';
import 'ui/calendar/calendar_page.dart';
import 'ui/auth/login_page.dart';
import 'ui/profile/profile_page.dart';
import 'ui/boards/boards_page.dart';
import 'ui/common/floating_assistant_shell.dart';
import 'ui/common/responsive_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  try {
    final envPath = kIsWeb ? 'env' : 'assets/env';
    await dotenv.load(fileName: envPath, isOptional: true);
  } catch (e) {
    debugPrint('No env file found: $e');
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StateBoards()),
        ChangeNotifierProxyProvider<StateBoards, StateTasks>(
          create: (_) => StateTasks(),
          update: (_, boards, tasks) => tasks!..updateStateBoards(boards),
        ),
        ChangeNotifierProvider(create: (_) => StateChat()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calenda',
      debugShowCheckedModeBanner: false,
      scrollBehavior: AppScrollBehavior(),
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: GlassColors.background,
        useMaterial3: true,
      ),
      home: const StartupGuard(),
    );
  }
}

class StartupGuard extends StatefulWidget {
  const StartupGuard({super.key});

  @override
  State<StartupGuard> createState() => _StartupGuardState();
}

class _StartupGuardState extends State<StartupGuard> {
  bool _showRetry = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _timeoutTimer = Timer(const Duration(seconds: 12), () {
      if (mounted) setState(() => _showRetry = true);
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasData) return const AppShell();
        return const LoginPage();
      },
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: GlassColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: GlassColors.primary),
            const SizedBox(height: 32),
            Text('AETHER INITIALIZING', style: GlassText.labelSM().copyWith(letterSpacing: 2.0)),
            if (_showRetry) ...[
              const SizedBox(height: 48),
              Text('Connection taking longer than usual.', style: GlassText.bodyMD().copyWith(color: Colors.white30)),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  if (kIsWeb) {
                    html.window.location.reload();
                  }
                },
                style: OutlinedButton.styleFrom(side: const BorderSide(color: GlassColors.gold)),
                child: Text('FORCE RELOAD', style: GlassText.labelSM().copyWith(color: GlassColors.gold)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 24),
              Text('STARTUP FAILURE', style: GlassText.labelSM().copyWith(color: Colors.redAccent)),
              const SizedBox(height: 16),
              Text(error, textAlign: TextAlign.center, style: GlassText.bodyMD().copyWith(color: Colors.white60)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (kIsWeb) {
                    html.window.location.reload();
                  }
                }, 
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<ui.PointerDeviceKind> get dragDevices => {
        ui.PointerDeviceKind.touch,
        ui.PointerDeviceKind.mouse,
        ui.PointerDeviceKind.trackpad,
      };
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}
class _AppShellState extends State<AppShell> {
  int _index = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DashboardPage(isDark: false),
      const BoardsPage(isDark: false),
      CalendarPage(
        isDark: false,
        onNavigate: (i) => setState(() => _index = i),
      ),
      const ChatPage(isDark: false),
      const ProfilePage(isDark: false),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StateBoards>().fetchAllBoards();
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedBoard = context.watch<StateBoards>().selectedBoard;
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: GlassColors.background,
      bottomNavigationBar: !isDesktop && selectedBoard == null
          ? GlassBottomBar(
              selectedIndex: _index,
              onItemSelected: (index) {
                setState(() {
                  _index = index;
                  context.read<StateBoards>().setSelectedBoard(null);
                });
              },
              items: const [
                GlassBottomBarItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
                GlassBottomBarItem(icon: Icons.grid_view_rounded, label: 'Boards'),
                GlassBottomBarItem(icon: Icons.calendar_today_outlined, label: 'Calendar'),
                GlassBottomBarItem(icon: Icons.chat_bubble_outline_rounded, label: 'Chat'),
                GlassBottomBarItem(icon: Icons.person_outline_rounded, label: 'Profile'),
              ],
              isDark: false,
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: GlassGradients.background(),
        ),
        child: Row(
          children: [
            if (isDesktop)
              AetherSideNav(
                selectedIndex: _index,
                onItemSelected: (index) {
                  setState(() {
                    _index = index;
                    if (index != 1) {
                      context.read<StateBoards>().setSelectedBoard(null);
                    }
                  });
                },
                isDark: false,
              ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0.7, -0.6),
                            radius: 1.2,
                            colors: [
                              GlassColors.primary.withOpacity(0.03),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    top: !isDesktop,
                    bottom: false,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      switchInCurve: Curves.easeOutQuart,
                      switchOutCurve: Curves.easeInQuart,
                      child: selectedBoard != null
                          ? KanbanPage(
                              key: ValueKey('kanban_${selectedBoard.id}'),
                              board: selectedBoard,
                              isDark: false,
                            )
                          : KeyedSubtree(
                              key: ValueKey('screen_$_index'),
                              child: _screens[_index],
                            ),
                    ),
                  ),
                  const FloatingAssistantShell(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
