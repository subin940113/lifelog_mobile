import 'package:flutter/material.dart';

Route<T> buildSettingsRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      final offset = Tween<Offset>(
        begin: const Offset(1, 0), // ✅ 오른쪽에서 등장
        end: Offset.zero,
      ).animate(curved);

      return SlideTransition(position: offset, child: child);
    },
  );
}

Future<T?> pushSettingsPage<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(buildSettingsRoute<T>(page));
}