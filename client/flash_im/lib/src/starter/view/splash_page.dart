import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flash_im/src/starter/data/repository/startup_repository.dart';

/// 闪屏页 — Logo + Flash IM 文字，最短停留 1.5 秒
class SplashPage extends StatefulWidget {
  final StartupRepository startupRepository;
  final ValueChanged<StartupResult> onStartupComplete;

  const SplashPage({super.key, required this.startupRepository, required this.onStartupComplete});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String? _errorMessage;
  bool _retrying = false;
  StreamSubscription? _subscription;
  StartupResult? _result;

  @override
  void initState() {
    super.initState();
    _startInitialization();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _startInitialization() async {
    setState(() { _errorMessage = null; _retrying = true; _result = null; });
    _subscription?.cancel();

    try {
      widget.startupRepository.initialize();

      // 等待 Stream 中首个 Ready 或 Failed
      _subscription = widget.startupRepository.stream.listen((event) {
        if (event is StartupReady) {
          _result = event.result;
          _subscription?.cancel();
          _navigate();
        } else if (event is StartupFailed) {
          setState(() { _errorMessage = event.message; _retrying = false; });
          _subscription?.cancel();
        }
      });

      // 同时等待 1.5 秒品牌露出
      await Future.delayed(const Duration(milliseconds: 1500));
      _navigate();
    } catch (e) {
      if (mounted) setState(() { _errorMessage = e.toString(); _retrying = false; });
    }
  }

  void _navigate() {
    if (_result == null || !mounted) return;
    widget.onStartupComplete(_result!);
    if (_result!.authenticated) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: const Color(0xFF07C160), borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 24),
            const Text('Flash IM', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A), letterSpacing: 2)),
            if (_errorMessage != null) ...[
              const SizedBox(height: 32),
              Text(_errorMessage!, style: const TextStyle(fontSize: 14, color: Color(0xFFE53935))),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _retrying ? null : _startInitialization,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF07C160), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _retrying
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : const Text('重试', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
