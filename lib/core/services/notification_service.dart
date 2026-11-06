import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../../firebase_options.dart';
import '../routes/app_routes.dart';
import '../storage/secure_storage_service.dart';
import '../storage/storage_service.dart';
import '../utils/app_logger.dart';
import '../../features/buyer/controllers/buyer_home_controller.dart';
import '../../features/partner/controllers/partner_home_controller.dart';
import '../../features/seller/controllers/seller_controller.dart';

/// Top-level background message handler required by FirebaseMessaging.
/// Must be outside of any class and annotated with @pragma('vm:entry-point').
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.i('Handling background FCM message: ${message.messageId}');
    await NotificationService.showNotificationFromRemoteMessage(message);
  } catch (e, stack) {
    AppLogger.e('Background message handler failed', e, stack);
  }
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const String channelId = 'diginiwas_housing_channel_v3';
  static const String channelName = 'DigiNiwas Property Alerts';
  static const String channelDescription =
      'High-priority alerts for property updates, leads, site visits, and transactions with sound.';

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final Int64List _vibrationPattern =
      Int64List.fromList([0, 250, 150, 250]);

  static final AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    channelId,
    channelName,
    description: channelDescription,
    importance: Importance.max,
    playSound: true,
    sound: const RawResourceAndroidNotificationSound('notification_sound'),
    enableVibration: true,
    vibrationPattern: _vibrationPattern,
    showBadge: true,
  );

  /// Initializes Firebase, FCM listeners, local notification channels, and permissions.
  Future<void> initialize() async {
    try {
      // 1. Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 2. Set background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. Request permissions (Android 13+ & iOS)
      await _requestPermissions();

      // 4. Setup Local Notifications (Channel + Icons)
      await _setupLocalNotifications();

      // 5. Configure Foreground Presentation Options for iOS
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 6. Setup Foreground & Opened listeners
      _setupListeners();

      // 7. Fetch and save initial FCM token
      unawaited(_fetchAndSyncToken());

      // 8. Auto-subscribe to new property alerts and buyer topic
      unawaited(subscribeToPropertyAlerts());

      // 9. Check for notification that opened the app from terminated state
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        AppLogger.i('App launched from terminated state via notification: ${initialMessage.data}');
        Future.delayed(const Duration(milliseconds: 600), () {
          handleNotificationTap(initialMessage.data);
        });
      }

      // 10. Start foreground periodic poller for real-time notifications
      startNotificationPolling();

      AppLogger.i('🔔 NotificationService successfully initialized');
    } catch (e, stack) {
      AppLogger.e('Failed to initialize NotificationService', e, stack);
    }
  }

  /// Request permissions for iOS and Android 13+
  Future<void> _requestPermissions() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      AppLogger.i('FCM Notification permission status: ${settings.authorizationStatus}');

      if (Platform.isAndroid) {
        final androidImplementation = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidImplementation?.requestNotificationsPermission();
      }
    } catch (e) {
      AppLogger.w('Error requesting notification permissions: $e');
    }
  }

  /// Sets up Android notification channels and local notification settings
  Future<void> _setupLocalNotifications() async {
    const androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInitSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    const initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: darwinInitSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            handleNotificationTap(data);
          } catch (e) {
            AppLogger.w('Failed to parse notification payload: $e');
          }
        }
      },
    );

    // Create high importance channel on Android
    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      try {
        await androidImplementation.deleteNotificationChannel('diginiwas_housing_channel_v2');
      } catch (_) {}
      await androidImplementation.createNotificationChannel(_androidChannel);
    }
  }

  /// Setup listeners for foreground messages and taps
  void _setupListeners() {
    // 0. Configure iOS foreground presentation
    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 1. Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.i('Received foreground FCM message: ${message.messageId}');
      showNotificationFromRemoteMessage(message);
    });

    // 2. Notification opened when app was running in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppLogger.i('App opened from background via notification: ${message.data}');
      handleNotificationTap(message.data);
    });

    // 3. Token refresh handler
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      AppLogger.i('FCM Token refreshed: $newToken');
      _saveAndSyncToken(newToken);
    });
  }

  /// Downloads a remote image URL to a local temporary file for rich notifications
  static Future<String?> _downloadAndSaveFile(String url, String fileName) async {
    if (url.trim().isEmpty || !url.startsWith('http')) return null;
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        client.close();
        return null;
      }
      final bytesList = <int>[];
      await for (var chunk in response) {
        bytesList.addAll(chunk);
      }
      client.close();
      if (bytesList.isEmpty) return null;
      final filePath = '${Directory.systemTemp.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytesList);
      return filePath;
    } catch (e) {
      AppLogger.w('Failed to download notification image from $url: $e');
      return null;
    }
  }

  /// Displays a heads-up notification with custom sound and optional property image
  static Future<void> showNotificationFromRemoteMessage(
      RemoteMessage message) async {
    try {
      final notification = message.notification;
      final data = message.data;

      // Extract title and body from notification or data
      final title = notification?.title ??
          data['title']?.toString() ??
          data['notificationTitle']?.toString() ??
          'DigiNiwas';

      final body = notification?.body ??
          data['body']?.toString() ??
          data['message']?.toString() ??
          '';

      if (title.isEmpty && body.isEmpty) return;

      final imageUrl = notification?.android?.imageUrl ??
          notification?.apple?.imageUrl ??
          data['image']?.toString() ??
          data['imageUrl']?.toString() ??
          data['propertyImage']?.toString() ??
          data['picture']?.toString();

      await showHousingStyleNotification(
        title: title,
        body: body,
        summaryText: data['role'] != null ? 'DigiNiwas ${data['role']}' : 'DigiNiwas Housing',
        imageUrl: imageUrl,
        data: data,
      );
    } catch (e, stack) {
      AppLogger.e('Failed to display local notification from remote message', e, stack);
    }
  }

  /// Displays a rich Housing.com style heads-up push notification with custom chime sound, vibration,
  /// and full Big Picture property photos for Buyers, Agents, and Sellers.
  static Future<void> showHousingStyleNotification({
    required String title,
    required String body,
    String? summaryText,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      String? localImagePath;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        final safeName = 'prop_${DateTime.now().millisecondsSinceEpoch}.jpg';
        localImagePath = await _downloadAndSaveFile(imageUrl, safeName);
      }

      StyleInformation styleInformation;
      if (localImagePath != null && File(localImagePath).existsSync()) {
        styleInformation = BigPictureStyleInformation(
          FilePathAndroidBitmap(localImagePath),
          largeIcon: FilePathAndroidBitmap(localImagePath),
          contentTitle: title,
          summaryText: summaryText ?? 'DigiNiwas Housing',
          htmlFormatContent: false,
          htmlFormatTitle: false,
          hideExpandedLargeIcon: true,
        );
      } else {
        styleInformation = BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: summaryText ?? 'DigiNiwas Housing',
          htmlFormatContent: false,
          htmlFormatTitle: false,
        );
      }

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('notification_sound'),
        enableVibration: true,
        vibrationPattern: _vibrationPattern,
        color: const Color(0xFF007A5E),
        styleInformation: styleInformation,
        largeIcon: (localImagePath != null && File(localImagePath).existsSync())
            ? FilePathAndroidBitmap(localImagePath)
            : null,
        subText: summaryText ?? 'DigiNiwas Housing',
        category: AndroidNotificationCategory.recommendation,
        icon: '@mipmap/ic_launcher',
        audioAttributesUsage: AudioAttributesUsage.notification,
      );

      final darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification_sound.wav',
        attachments: (localImagePath != null && File(localImagePath).existsSync())
            ? [DarwinNotificationAttachment(localImagePath)]
            : null,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _localNotifications.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: data != null ? jsonEncode(data) : null,
      );
    } catch (e, stack) {
      AppLogger.e('Failed to display housing style notification', e, stack);
    }
  }

  /// Deep link and navigation handler for notification taps
  static Future<void> handleNotificationTap(Map<String, dynamic> data) async {
    AppLogger.i('Handling notification navigation for data: $data');

    try {
      final type = data['type']?.toString().toLowerCase() ?? '';
      final deepLink = data['deepLink']?.toString().toLowerCase() ?? '';
      final propertyId = data['propertyId']?.toString();
      final targetRoute = data['route']?.toString();

      // Explicit route provided
      if (targetRoute != null && targetRoute.isNotEmpty) {
        Get.toNamed(targetRoute, arguments: data);
        return;
      }

      // Check Deep Link or Type
      if (deepLink.contains('property') ||
          type.contains('property') ||
          propertyId != null) {
        if (propertyId != null && propertyId.isNotEmpty) {
          Get.toNamed(AppRoutes.propertyDetails, arguments: propertyId);
          return;
        }
      }

      if (deepLink.contains('wallet') || type.contains('wallet') || type.contains('credit')) {
        Get.toNamed(AppRoutes.creditWallet);
        return;
      }

      if (deepLink.contains('niwas_ai') || type.contains('ai')) {
        Get.toNamed(AppRoutes.niwasAi);
        return;
      }

      if (deepLink.contains('add_property') || type.contains('add_property')) {
        Get.toNamed(AppRoutes.addProperty);
        return;
      }

      if (deepLink.contains('insights')) {
        Get.toNamed(AppRoutes.sellerInsights);
        return;
      }

      if (deepLink.contains('lead') || deepLink.contains('assignment')) {
        Get.toNamed(AppRoutes.partnerNotifications);
        return;
      }

      // Fallback based on user role or general notification screen
      final role = (await StorageService.instance.role)?.toLowerCase() ?? '';
      if (role == 'partner' || role == 'agent') {
        Get.toNamed(AppRoutes.partnerNotifications);
      } else if (role == 'buyer') {
        Get.toNamed(AppRoutes.buyerNotifications);
      } else if (role == 'seller') {
        Get.toNamed(AppRoutes.sellerNotifications);
      } else {
        Get.toNamed(AppRoutes.buyerNotifications);
      }
    } catch (e) {
      AppLogger.w('Failed to navigate from notification: $e');
    }
  }

  /// Fetches FCM token and persists/syncs it
  Future<String?> _fetchAndSyncToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        AppLogger.i('🔑 Device FCM Token: $token');
        await _saveAndSyncToken(token);
        return token;
      }
    } catch (e) {
      AppLogger.w('Could not fetch FCM token: $e');
    }
    return null;
  }

  /// Saves FCM token locally and sends to backend if user is authenticated
  Future<void> _saveAndSyncToken(String token) async {
    try {
      await SecureStorageService.instance.saveFcmToken(token);
    } catch (e) {
      AppLogger.w('Failed to save FCM token: $e');
    }
  }

  /// Public method to get the current FCM token
  Future<String?> getFcmToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  /// Subscribes buyer to global and city-level property alert topics
  Future<void> subscribeToPropertyAlerts({String? city}) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic('new_properties');
      await FirebaseMessaging.instance.subscribeToTopic('all_buyers');
      if (city != null && city.trim().isNotEmpty) {
        final cleanCity = city.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
        await FirebaseMessaging.instance.subscribeToTopic('city_$cleanCity');
        AppLogger.i('Subscribed to topic: city_$cleanCity');
      }
      AppLogger.i('Subscribed to new_properties and all_buyers topics');
    } catch (e) {
      AppLogger.w('Failed to subscribe to property topics: $e');
    }
  }

  /// Subscribes current user to specific FCM topics based on their active role (Buyer, Partner, Seller)
  Future<void> syncRoleTopics({
    required String role,
    String? userId,
    String? city,
  }) async {
    try {
      final cleanRole = role.trim().toLowerCase();
      if (cleanRole == 'buyer') {
        await FirebaseMessaging.instance.subscribeToTopic('all_buyers');
        await FirebaseMessaging.instance.subscribeToTopic('new_properties');
        if (userId != null && userId.isNotEmpty) {
          await FirebaseMessaging.instance.subscribeToTopic('buyer_$userId');
        }
      } else if (cleanRole == 'partner' || cleanRole == 'agent') {
        await FirebaseMessaging.instance.subscribeToTopic('all_partners');
        await FirebaseMessaging.instance.subscribeToTopic('new_leads');
        if (userId != null && userId.isNotEmpty) {
          await FirebaseMessaging.instance.subscribeToTopic('partner_$userId');
        }
      } else if (cleanRole == 'seller') {
        await FirebaseMessaging.instance.subscribeToTopic('all_sellers');
        await FirebaseMessaging.instance.subscribeToTopic('seller_properties');
        if (userId != null && userId.isNotEmpty) {
          await FirebaseMessaging.instance.subscribeToTopic('seller_$userId');
        }
      }
      if (city != null && city.trim().isNotEmpty) {
        final cleanCity = city.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
        await FirebaseMessaging.instance.subscribeToTopic('city_$cleanCity');
      }
      AppLogger.i('🔔 Synced role topics for: $cleanRole (user: $userId, city: $city)');
    } catch (e) {
      AppLogger.w('Failed to sync role topics: $e');
    }
  }

  /// Converts an in-app notification to a real heads-up system push notification with custom sound and vibration.
  static Future<void> triggerPushForInAppNotification({
    required String id,
    required String title,
    required String body,
    String? role,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (id.isEmpty) return;
      final alreadyPushed = await StorageService.instance.isPushNotificationShown(id);
      if (alreadyPushed) return;
      await StorageService.instance.markPushNotificationShown(id);

      final roleTag = (role != null && role.isNotEmpty)
          ? 'DigiNiwas ${role[0].toUpperCase()}${role.substring(1).toLowerCase()}'
          : 'DigiNiwas Alerts';

      await showHousingStyleNotification(
        title: title,
        body: body,
        summaryText: roleTag,
        imageUrl: imageUrl,
        data: {
          'id': id,
          'role': role ?? '',
          if (imageUrl != null) 'imageUrl': imageUrl,
          ...?data,
        },
      );
      AppLogger.i('🔔 Push notification fired with sound and image for: $title (ID: $id)');
    } catch (e, stack) {
      AppLogger.e('Failed to fire push notification for in-app item', e, stack);
    }
  }

  /// Batch syncs an in-app notification list to push notifications.
  /// Shows the newest unpushed items so the user hears the notification sound, sees the property image and heads-up banner.
  static Future<void> syncInAppNotificationsToPush({
    required List<Map<String, dynamic>> notifications,
    required String role,
    int maxNewToPush = 2,
  }) async {
    try {
      int pushedCount = 0;
      for (final item in notifications) {
        final isRead = item['isRead'] == true || item['read'] == true;
        if (isRead) continue;

        final id = item['_id']?.toString() ??
            item['id']?.toString() ??
            item['notificationId']?.toString() ??
            '';
        if (id.isEmpty) continue;

        final alreadyPushed = await StorageService.instance.isPushNotificationShown(id);
        if (alreadyPushed) continue;

        final title = item['title']?.toString() ??
            item['notificationTitle']?.toString() ??
            'DigiNiwas Update';
        final body = item['message']?.toString() ??
            item['body']?.toString() ??
            item['description']?.toString() ??
            '';

        // Extract image URL from various potential nested structures
        String? imageUrl = item['image']?.toString() ??
            item['imageUrl']?.toString() ??
            item['propertyImage']?.toString() ??
            item['picture']?.toString();

        if (imageUrl == null && item['property'] is Map) {
          final prop = item['property'] as Map;
          imageUrl = prop['image']?.toString() ??
              (prop['images'] is List && (prop['images'] as List).isNotEmpty
                  ? prop['images'][0]?.toString()
                  : null);
        }

        if (imageUrl == null && item['propertySnapshot'] is Map) {
          final snap = item['propertySnapshot'] as Map;
          imageUrl = snap['image']?.toString() ??
              (snap['images'] is List && (snap['images'] as List).isNotEmpty
                  ? snap['images'][0]?.toString()
                  : null);
        }

        if (imageUrl == null && item['data'] is Map) {
          final d = item['data'] as Map;
          imageUrl = d['imageUrl']?.toString() ?? d['image']?.toString();
        }

        if (title.isNotEmpty || body.isNotEmpty) {
          await triggerPushForInAppNotification(
            id: id,
            title: title,
            body: body,
            role: role,
            imageUrl: imageUrl,
            data: item,
          );
          pushedCount++;
          if (pushedCount >= maxNewToPush) break;
        }
      }
    } catch (e) {
      AppLogger.w('Failed to sync in-app notifications to push: $e');
    }
  }

  static Timer? _pollingTimer;

  /// Starts a periodic foreground poller (every 45 seconds) to fetch fresh notifications
  /// for whichever role is currently active and fire push notifications with sound.
  void startNotificationPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 45), (_) async {
      try {
        final role = (await StorageService.instance.role)?.toLowerCase() ?? '';
        if (role == 'buyer') {
          if (Get.isRegistered<BuyerHomeController>()) {
            await Get.find<BuyerHomeController>().fetchNotifications();
          }
        } else if (role == 'partner' || role == 'agent') {
          if (Get.isRegistered<PartnerHomeController>()) {
            await Get.find<PartnerHomeController>().fetchNotifications();
          }
        } else if (role == 'seller') {
          if (Get.isRegistered<SellerController>()) {
            await Get.find<SellerController>().fetchNotifications();
          }
        }
      } catch (_) {}
    });
  }

  /// Stops the periodic foreground poller
  void stopNotificationPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Helper to test and verify that push notification with sound and property image is working
  static Future<void> fireTestNotification({String? role, bool withImage = true}) async {
    final roleName = role ?? 'User';
    final isBuyer = roleName.toLowerCase() == 'buyer';
    
    // Luxury property photo for visual testing on device
    final testImageUrl = withImage
        ? 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&auto=format&fit=crop&q=80'
        : null;

    final title = isBuyer
        ? '🏡 New Match: 3 BHK Luxury Villa in Gurugram'
        : 'DigiNiwas $roleName Alert 🔔';

    final body = isBuyer
        ? '₹1.25 Cr • Sector 57, Gurugram. 100% Verified by DigiNiwas Partner. Tap to view floor plan & schedule visit.'
        : 'Push notification with custom sound is 100% active and working!';

    await showHousingStyleNotification(
      title: title,
      body: body,
      summaryText: 'DigiNiwas Housing',
      imageUrl: testImageUrl,
      data: {
        'type': isBuyer ? 'property' : 'test',
        'propertyId': 'test_prop_123',
        'role': roleName,
        'title': title,
        'body': body,
      },
    );
  }
}
