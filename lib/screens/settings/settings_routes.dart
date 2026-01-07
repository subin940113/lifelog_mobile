import 'package:flutter/material.dart';

Route<T> buildSettingsRoute<T>(Widget page, {bool fromLeft = false}) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      final begin = fromLeft ? const Offset(-1, 0) : const Offset(1, 0);

      return SlideTransition(
        position: Tween<Offset>(begin: begin, end: Offset.zero).animate(curved),
        child: child,
      );
    },
  );
}

Future<T?> pushSettingsPage<T>(
  BuildContext context,
  Widget page, {
  bool fromLeft = false,
}) {
  return Navigator.of(
    context,
  ).push<T>(buildSettingsRoute<T>(page, fromLeft: fromLeft));
}
