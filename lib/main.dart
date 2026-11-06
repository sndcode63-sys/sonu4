import 'dart:io';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/utils/app_logger.dart';

class AppHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = AppHttpOverrides();
  AppLogger.i('🚀 App started');

  // Initialize Push Notifications (Firebase, channels, sound, foreground/background handlers)
  try {
    await NotificationService.instance.initialize();
  } catch (e, stack) {
    AppLogger.e('Failed to initialize NotificationService in main()', e, stack);
  }

  runApp(const MyApp());
}
