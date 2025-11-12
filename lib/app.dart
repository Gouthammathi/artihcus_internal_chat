import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:artihcus_internal_chat/core/routing/app_router.dart';
import 'package:artihcus_internal_chat/core/theme/app_theme.dart';

class ArtihcusApp extends ConsumerWidget {
  const ArtihcusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final theme = ref.watch(appThemeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Artihcus Internal Chat',
      theme: theme.lightTheme,
      darkTheme: theme.darkTheme,
      routerConfig: router,
    );
  }
}

