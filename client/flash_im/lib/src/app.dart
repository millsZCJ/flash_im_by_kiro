import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// FlashApp — MaterialApp.router 接入 GoRouter
class FlashApp extends StatelessWidget {
  final GoRouter router;

  const FlashApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flash IM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF07C160)),
      ),
      routerConfig: router,
    );
  }
}
