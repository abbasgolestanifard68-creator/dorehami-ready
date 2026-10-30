import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens_admin.dart';
import 'screens_auth.dart';
import 'screens_main.dart';
import 'state.dart';
import 'updater.dart';
import 'widgets.dart';

void main() {
  runApp(const DorehamiApp());
}

class DorehamiApp extends StatefulWidget {
  const DorehamiApp({super.key});

  @override
  State<DorehamiApp> createState() => _DorehamiAppState();
}

class _DorehamiAppState extends State<DorehamiApp> {
  final AppState _state = AppState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  ThemeData _theme(Brightness b) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00897B),
        brightness: b,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: ListenableBuilder(
        listenable: _state,
        builder: (context, _) {
          return MaterialApp(
            title: 'دورهمی',
            debugShowCheckedModeBanner: false,
            locale: const Locale('fa', 'IR'),
            supportedLocales: const [Locale('fa', 'IR')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: _theme(Brightness.light),
            darkTheme: _theme(Brightness.dark),
            themeMode: _state.dark ? ThemeMode.dark : ThemeMode.light,
            home: const Root(),
          );
        },
      ),
    );
  }
}

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (state.me == null) {
      return const AuthScreen();
    }
    return const UpdateWatcher(child: MainShell());
  }
}

/// بررسی نسخه جدید پس از نمایش صفحه نخست و هنگام بازگشت برنامه از پس‌زمینه.
class UpdateWatcher extends StatefulWidget {
  const UpdateWatcher({super.key, required this.child});

  final Widget child;

  @override
  State<UpdateWatcher> createState() => _UpdateWatcherState();
}

class _UpdateWatcherState extends State<UpdateWatcher>
    with WidgetsBindingObserver {
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      _check();
    }
  }

  Future<void> _check() async {
    if (!Updater.configured || _dialogOpen) {
      return;
    }
    final info = await Updater.check();
    if (info == null || !mounted) {
      return;
    }
    _dialogOpen = true;
    await showUpdateDialog(context, info);
    _dialogOpen = false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// صفحه اصلی پس از ورود: نقشه، گفتگوها، گروه‌ها، پروفایل و (برای مدیران) مدیریت.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final staff = state.isStaff;
    final pages = <Widget>[
      const MapScreen(),
      const ChatsScreen(),
      const GroupsScreen(),
      const ProfileScreen(),
      if (staff) const AdminScreen(),
    ];
    if (_index >= pages.length) {
      _index = 0;
    }
    final reqCount = state.requests.length;
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'نقشه',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: reqCount > 0,
              label: Text('$reqCount'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: 'گفتگوها',
          ),
          const NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'گروه‌ها',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'پروفایل',
          ),
          if (staff)
            const NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: Icon(Icons.admin_panel_settings),
              label: 'مدیریت',
            ),
        ],
      ),
    );
  }
}
