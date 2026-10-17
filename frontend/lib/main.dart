import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';

void main() {
  runApp(const ProviderScope(child: BidwaanApp()));
}

/// Root application widget — wires the global theme to the GoRouter config.
class BidwaanApp extends StatelessWidget {
  const BidwaanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Bidwaan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
