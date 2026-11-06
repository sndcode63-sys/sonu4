import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum ToastType {
  success,
  error,
  info,
  warning,
}

// Backward compatibility alias for any existing code using AppToastType
typedef AppToastType = ToastType;

class AppToast {
  AppToast._();

  static GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void show(
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    Color bg;
    IconData icon;
    switch (type) {
      case ToastType.success:
        bg = const Color(0xFF16A34A);
        icon = Icons.check_circle_rounded;
        break;
      case ToastType.error:
        bg = const Color(0xFFDC2626);
        icon = Icons.error_rounded;
        break;
      case ToastType.warning:
        bg = const Color(0xFFD97706);
        icon = Icons.warning_rounded;
        break;
      case ToastType.info:
        bg = const Color(0xFF1F2937);
        icon = Icons.info_rounded;
        break;
    }

    try {
      Get.rawSnackbar(
        messageText: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bg,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        borderRadius: 12,
        duration: duration,
        isDismissible: true,
      );
    } catch (_) {
      // Fallback to ScaffoldMessenger if GetX overlay isn't available
      final messenger = messengerKey.currentState ??
          (Get.context != null ? ScaffoldMessenger.maybeOf(Get.context!) : null);
      if (messenger != null) {
        messenger.removeCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: bg,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            duration: duration,
          ),
        );
      }
    }
  }

  static void showSuccess(String message) {
    show(message, type: ToastType.success);
  }

  static void showError(String message) {
    show(message, type: ToastType.error, duration: const Duration(seconds: 4));
  }

  static void showInfo(String message) {
    show(message, type: ToastType.info);
  }

  static void showWarning(String message) {
    show(message, type: ToastType.warning);
  }

  // --- Backward compatibility helpers for existing code using (context, message) ---
  static void success(dynamic contextOrMsg, [String? maybeMsg]) {
    final msg = maybeMsg ?? (contextOrMsg is String ? contextOrMsg : '');
    showSuccess(msg);
  }

  static void error(dynamic contextOrMsg, [String? maybeMsg]) {
    final msg = maybeMsg ?? (contextOrMsg is String ? contextOrMsg : '');
    showError(msg);
  }

  static void warning(dynamic contextOrMsg, [String? maybeMsg]) {
    final msg = maybeMsg ?? (contextOrMsg is String ? contextOrMsg : '');
    showWarning(msg);
  }

  static void info(dynamic contextOrMsg, [String? maybeMsg]) {
    final msg = maybeMsg ?? (contextOrMsg is String ? contextOrMsg : '');
    showInfo(msg);
  }

  static void showSnack({
    required String title,
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(message, type: type, duration: duration);
  }
}
