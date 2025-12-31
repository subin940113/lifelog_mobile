import 'package:flutter/material.dart';
import 'package:lifelog_mobile/theme/palette.dart';
import 'widgets/settings_page_header.dart';

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
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.06)
                      : p.muted.withOpacity(0.10),
                ),
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
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          if (selected)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: p.accent,
                                shape: BoxShape.circle,
                              ),
                            )
                          else
                            const SizedBox(width: 10),
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
