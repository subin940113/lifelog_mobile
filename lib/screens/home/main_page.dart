import 'package:flutter/material.dart';

import 'package:lifelog_mobile/theme/palette.dart';
import '../record/record_screen.dart';
import '../settings/settings_home_page.dart';
import '../settings/settings_routes.dart';
import 'package:provider/provider.dart';
import 'package:lifelog_mobile/theme/theme_provider.dart';

class MainPage extends StatelessWidget {
  final Color bg;
  final Palette p;
  final VoidCallback onLogout;

  const MainPage({
    super.key,
    required this.bg,
    required this.p,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: p.ink),
          tooltip: '설정',
          onPressed: () {
            pushSettingsPage<void>(
  context,
  SettingsHomePage(
    onChangeTheme: (m) => context.read<ThemeProvider>().setMode(m),
    onLogout: onLogout,
  ),
  fromLeft: true,
);
          },
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '오늘의 기록',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: p.ink,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '짧게라도 괜찮아요. 오늘 있었던 일을 적어보세요.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: p.muted,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
MaterialPageRoute(builder: (_) => RecordScreen(onLogout: onLogout)),                    );
                  },
                  child: const Text('기록하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}