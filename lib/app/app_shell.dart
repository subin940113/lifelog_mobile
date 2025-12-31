import 'package:flutter/material.dart';

import '../screens/auth/login_page.dart';
import '../screens/home/main_page.dart';
import 'package:lifelog_mobile/theme/palette.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _loggedIn = false;

  void _onLoggedIn() => setState(() => _loggedIn = true);
  void _onLogout() => setState(() => _loggedIn = false);

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(Theme.of(context).colorScheme);
    final bg = p.bg;

    return _loggedIn
        ? MainPage(bg: bg, p: p, onLogout: _onLogout)
        : LoginPage(bg: bg, p: p, onLoggedIn: _onLoggedIn);
  }
}
