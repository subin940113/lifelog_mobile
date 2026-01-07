// lib/screens/settings/theme_settings_page.dart (또는 기존 파일)
import 'package:flutter/material.dart';
import 'package:lifelog_mobile/theme/palette.dart';
import 'widgets/settings_page_header.dart';

// ✅ Glass 공통 컴포넌트
import 'package:lifelog_mobile/widgets/glass_dot.dart';

String themeLabel(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return '시스템';
    case ThemeMode.light:
      return '라이트';
    case ThemeMode.dark:
      return '다크';
  }
}

void showThemeSheet(
  BuildContext context,
  Palette p, {
  required ThemeMode value,
  required ValueChanged<ThemeMode> onChanged,
}) {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (_, __, ___) =>
          ThemeSettingsPage(bg: p.bg, p: p, value: value, onChanged: onChanged),
      transitionsBuilder: (_, animation, __, child) {
        final offset = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(position: offset, child: child);
      },
    ),
  );
}

class ThemeSettingsPage extends StatefulWidget {
  final Color bg;
  final Palette p;
  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  const ThemeSettingsPage({
    super.key,
    required this.bg,
    required this.p,
    required this.value,
    required this.onChanged,
  });

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  late ThemeMode _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.value;
  }

  List<ThemeMode> _buildDisplayModes() {
    return const <ThemeMode>[ThemeMode.system, ThemeMode.light, ThemeMode.dark];
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(Theme.of(context).colorScheme);
    final modes = _buildDisplayModes();

    return Scaffold(
      backgroundColor: p.bg,
      appBar: null,
      body: SafeArea(
        child: Column(
          children: [
            SettingsPageHeader(
              title: '테마',
              titleColor: p.ink,
              iconColor: p.ink,
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                itemCount: modes.length,
                separatorBuilder: (_, __) => const SizedBox.shrink(),
                itemBuilder: (context, index) {
                  final mode = modes[index];
                  final selected = mode == _selected;

                  return InkWell(
                    onTap: () {
                      if (_selected == mode) return;
                      setState(() => _selected = mode);
                      widget.onChanged(mode);
                    },
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: SizedBox(
                      height: 48,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              themeLabel(mode),
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: p.ink,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 18,
                                  ),
                            ),
                          ),
                          if (selected)
                            GlassDot(size: 12, color: p.accent, active: false)
                          else
                            const SizedBox(width: 12),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
