import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_pages.dart';
import '../../../core/routes/app_routes.dart';
import '../../auth/data/auth_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const String _splashGifPath = 'assets/splash_video.gif';
  static const Duration _splashDuration = Duration(milliseconds: 7250); // Navigates ~750ms before 8000ms ends

  bool _navigated = false;
  String? _preloadedRoute;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    _preloadNextRoute();
    _startSplashTimer();
  }

  Future<void> _preloadNextRoute() async {
    try {
      final session = await Get.find<AuthRepository>().getStoredSession();
      _preloadedRoute = session != null
          ? dashboardRouteForRole(session['role'] as String?)
          : AppRoutes.chooseRole;
    } catch (_) {
      _preloadedRoute = AppRoutes.chooseRole;
    }
  }

  void _startSplashTimer() {
    _navigationTimer = Timer(_splashDuration, () {
      _navigateToNext();
    });
  }

  Future<void> _navigateToNext() async {
    if (_navigated || !mounted) return;
    _navigated = true;
    _navigationTimer?.cancel();

    String? route = _preloadedRoute;
    if (route == null) {
      try {
        final session = await Get.find<AuthRepository>().getStoredSession();
        route = session != null
            ? dashboardRouteForRole(session['role'] as String?)
            : AppRoutes.chooseRole;
      } catch (_) {
        route = AppRoutes.chooseRole;
      }
    }

    if (!mounted) return;
    Get.offAllNamed(route);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _navigateToNext,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.expand(
          child: Image.asset(
            _splashGifPath,
            fit: BoxFit.fill,
            width: double.infinity,
            height: double.infinity,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}
