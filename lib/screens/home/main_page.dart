import 'package:flutter/material.dart';

import '../record/record_screen.dart';
import 'package:lifelog_mobile/theme/palette.dart';

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Home',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: p.ink,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onLogout,
                    style: TextButton.styleFrom(foregroundColor: p.muted),
                    child: const Text(
                      '로그아웃',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: p.card.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.muted.withOpacity(0.10)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '오늘',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: p.ink,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '빠르게 기록을 시작해.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: p.muted,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RecordScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.ink,
                    foregroundColor: bg,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '기록하기',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),

              const Spacer(),
              Text(
                'v0 (minimal shell)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: p.muted.withOpacity(0.75),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}