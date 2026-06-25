import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'state_managers/state_meetings.dart';
import 'state_managers/state_tasks.dart';
import 'state_managers/state_chat.dart';
import 'models/board_model.dart';
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
import 'ui/meetings/meetings_board_page.dart';
import 'ui/common/floating_assistant_shell.dart';
import 'ui/common/responsive_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  try {
    final envPath = 'assets/env';
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
        ChangeNotifierProvider(create: (_) => StateMeetings()),
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
      title: 'VaultTask',
      debugShowCheckedModeBanner: false,
      scrollBehavior: AppScrollBehavior(),
      theme: GlassAppTheme.dark(),
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
  bool _delayCompleted = false;
  bool _authResolved = false;
  User? _currentUser;
  Timer? _timeoutTimer;
  Timer? _delayTimer;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _timeoutTimer = Timer(const Duration(seconds: 12), () {
      if (mounted) setState(() => _showRetry = true);
    });
    _delayTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _delayCompleted = true;
        });
      }
    });
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _authResolved = true;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _authResolved = true;
      });
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _delayTimer?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_delayCompleted || !_authResolved) {
      return _buildLoadingState();
    }

    if (_currentUser != null) return const AppShell();
    return const LoginPage();
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
            Text(
              'AETHER INITIALIZING',
              style: GlassText.labelSM().copyWith(letterSpacing: 2.0),
            ),
            if (_showRetry) ...[
              const SizedBox(height: 48),
              Text(
                'Connection taking longer than usual.',
                style: GlassText.bodyMD().copyWith(color: Colors.white30),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  if (kIsWeb) {
                    html.window.location.reload();
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: GlassColors.gold),
                ),
                child: Text(
                  'FORCE RELOAD',
                  style: GlassText.labelSM().copyWith(color: GlassColors.gold),
                ),
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
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 24),
              Text(
                'STARTUP FAILURE',
                style: GlassText.labelSM().copyWith(color: Colors.redAccent),
              ),
              const SizedBox(height: 16),
              Text(
                error,
                textAlign: TextAlign.center,
                style: GlassText.bodyMD().copyWith(color: Colors.white60),
              ),
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
  static const _selectedTabPrefKey = 'app_selected_tab_index';
  int _index = 0;
  final Set<int> _visitedTabs = {0};
  StreamSubscription<html.Event>? _windowFocusSub;
  bool _isRestoringShellState = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _restoreShellState();
    });
    if (kIsWeb) {
      _windowFocusSub = html.window.onFocus.listen((_) {
        if (!mounted) return;
        context.read<StateTasks>().refreshReadComments();
      });
    }
  }

  @override
  void dispose() {
    _windowFocusSub?.cancel();
    super.dispose();
  }

  void _selectTab(int index, {bool clearBoard = true}) {
    setState(() {
      _index = index;
      _visitedTabs.add(index);
      if (clearBoard) {
        final selectedBoardId = context.read<StateBoards>().selectedBoard?.id;
        context.read<StateBoards>().setSelectedBoard(null);
        context.read<StateMeetings>().clearActiveBoard(selectedBoardId);
      }
    });
    if (index == 0) {
      context.read<StateTasks>().refreshReadComments();
    }
    _persistShellState();
  }

  Future<void> _restoreShellState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt(_selectedTabPrefKey) ?? 0;
    if (!mounted) return;
    setState(() {
      _index = savedIndex.clamp(0, 4);
      _visitedTabs.add(_index);
    });

    final boardsState = context.read<StateBoards>();
    await boardsState.fetchAllBoards();
    await context.read<StateMeetings>().fetchAllMeetings(
      boardsState.boards,
      silent: true,
    );
    await boardsState.restorePersistedSelectedBoard();
    if (!mounted) return;
    setState(() {
      _isRestoringShellState = false;
    });
  }

  Future<void> _persistShellState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_selectedTabPrefKey, _index);
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return DashboardPage(
          isDark: false,
          onNavigate: (i) => _selectTab(i, clearBoard: i != 1),
        );
      case 1:
        return const BoardsPage(isDark: false);
      case 2:
        return CalendarPage(
          isDark: false,
          onNavigate: (i) => _selectTab(i, clearBoard: i != 1),
        );
      case 3:
        return ChatPage(
          isDark: false,
          onNavigate: (i) => _selectTab(i, clearBoard: i != 1),
        );
      case 4:
        return const ProfilePage(isDark: false);
      default:
        return const SizedBox.shrink();
    }
  }

  List<Widget> _buildVisitedScreens() {
    return List<Widget>.generate(5, (index) {
      if (_visitedTabs.contains(index)) {
        return _buildScreen(index);
      }
      return const SizedBox.shrink();
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedBoard = context.select<StateBoards, BoardModel?>(
      (state) => state.selectedBoard,
    );
    final selectedBoardSurface = context.select<StateBoards, BoardSurfaceMode>(
      (state) => state.selectedBoardSurface,
    );
    final boardsLoading = context.select<StateBoards, bool>(
      (state) => state.isLoading,
    );
    final tasksLoading = context.select<StateTasks, bool>(
      (state) => state.isLoading,
    );
    final meetingsLoading = context.select<StateMeetings, bool>(
      (state) => state.isLoading,
    );
    final isDesktop = Responsive.isDesktop(context);
    final showLoadingOverlay =
        _isRestoringShellState ||
        boardsLoading ||
        tasksLoading ||
        meetingsLoading;

    return Scaffold(
      backgroundColor: GlassColors.background,
      bottomNavigationBar: !isDesktop && selectedBoard == null
          ? GlassBottomBar(
              selectedIndex: _index,
              onItemSelected: (index) => _selectTab(index),
              items: const [
                GlassBottomBarItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                ),
                GlassBottomBarItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Boards',
                ),
                GlassBottomBarItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Calendar',
                ),
                GlassBottomBarItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Chat',
                ),
                GlassBottomBarItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                ),
              ],
              isDark: false,
            )
          : null,
      body: Container(
        decoration: BoxDecoration(gradient: GlassGradients.background()),
        child: Row(
          children: [
            if (isDesktop)
              AetherSideNav(
                selectedIndex: _index,
                onItemSelected: (index) =>
                    _selectTab(index, clearBoard: index != 1),
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
                    child: selectedBoard != null
                        ? AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child:
                                selectedBoardSurface ==
                                    BoardSurfaceMode.meetings
                                ? MeetingsBoardPage(
                                    key: ValueKey(
                                      'meetings_${selectedBoard.id}',
                                    ),
                                    board: selectedBoard,
                                  )
                                : KanbanPage(
                                    key: ValueKey('kanban_${selectedBoard.id}'),
                                    board: selectedBoard,
                                    isDark: false,
                                  ),
                          )
                        : IndexedStack(
                            index: _index,
                            children: _buildVisitedScreens(),
                          ),
                  ),
                  if (showLoadingOverlay)
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: false,
                        child: Container(
                          color: Colors.black.withOpacity(0.26),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: GlassColors.surface.withOpacity(0.92),
                                borderRadius: BorderRadius.circular(
                                  ExecutiveRadius.m,
                                ),
                                border: Border.all(
                                  color: GlassColors.ghostBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.1,
                                      color: GlassColors.gold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Refreshing your workspace...',
                                    style: GlassText.bodyMD().copyWith(
                                      color: GlassColors.onSurface.withOpacity(
                                        0.82,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
