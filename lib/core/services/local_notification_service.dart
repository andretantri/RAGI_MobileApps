import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../router/app_router.dart';

enum NotificationChannelType {
  teachingSchedule,
  attendance,
  assignment,
  announcement,
}

class LocalNotificationService {
  static final LocalNotificationService instance =
      LocalNotificationService._internal();

  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _appReady = false;
  String? _pendingRoute;

  /// Inisialisasi plugin notifikasi lokal untuk Android, iOS, Web & Desktop.
  /// Dipanggil dari main() agar tap notifikasi saat cold start tidak hilang.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
      );

      final launchDetails =
          await _notificationsPlugin.getNotificationAppLaunchDetails();
      final launchPayload = launchDetails?.notificationResponse?.payload;
      if (launchDetails?.didNotificationLaunchApp == true &&
          launchPayload != null &&
          launchPayload.isNotEmpty) {
        _pendingRoute = launchPayload;
      }

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
      );

      _isInitialized = true;
      debugPrint('[LocalNotification] Service berhasil diinisialisasi.');
      _dispatchPendingRoute();
    } catch (e) {
      debugPrint('[LocalNotification] Gagal inisialisasi plugin: $e');
    }
  }

  /// Dipanggil setelah MaterialApp.router siap. Payload yang diterima sebelum
  /// router terpasang akan dieksekusi di sini (cold start / tap saat startup).
  void markAppReady() {
    _appReady = true;
    _dispatchPendingRoute();
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    debugPrint('[LocalNotification] Notifikasi diklik, payload: $payload');
    _pendingRoute = payload;
    _dispatchPendingRoute();
  }

  void _dispatchPendingRoute() {
    if (!_appReady) return;
    final route = _pendingRoute;
    if (route == null || route.isEmpty) return;
    if (!route.startsWith('/')) {
      _pendingRoute = null;
      return;
    }

    try {
      AppRouter.router.go(route);
      _pendingRoute = null;
    } catch (e) {
      debugPrint('[LocalNotification] Gagal membuka halaman $route: $e');
    }
  }

  /// Tampilkan notifikasi push langsung ke sistem perangkat.
  /// Satu notifikasi hanya ditampilkan sekali oleh plugin sistem — tidak ada
  /// overlay tambahan di dalam aplikasi.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    NotificationChannelType channel = NotificationChannelType.teachingSchedule,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    final channelConfig = _getChannelConfig(channel);

    final androidDetails = AndroidNotificationDetails(
      channelConfig['id']!,
      channelConfig['name']!,
      channelDescription: channelConfig['desc']!,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      color: const Color(0xFF0B52B3),
      icon: '@drawable/ic_stat_logo',
      largeIcon: const DrawableResourceAndroidBitmap('ic_notification_large'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final targetRoute =
        payload != null && payload.isNotEmpty ? payload : routeForChannel(channel);

    try {
      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: targetRoute,
      );
    } catch (e) {
      debugPrint('[LocalNotification] Gagal show notification: $e');
    }
  }

  /// Rute default ketika notifikasi lokal diklik dan API tidak mengirim URL.
  static String routeForChannel(NotificationChannelType channel) {
    switch (channel) {
      case NotificationChannelType.teachingSchedule:
        return '/schedule';
      case NotificationChannelType.attendance:
        return '/scanner';
      case NotificationChannelType.assignment:
        return '/siakad/perkuliahan';
      case NotificationChannelType.announcement:
        return '/simpeg/announcements';
    }
  }

  /// Minta izin notifikasi dari sistem OS perangkat
  Future<bool> requestPermissions() async {
    try {
      final androidPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        final granted =
            await androidPlatform.requestNotificationsPermission() ?? false;
        return granted;
      }

      final iosPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosPlatform != null) {
        final granted = await iosPlatform.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
        return granted;
      }
    } catch (e) {
      debugPrint('[LocalNotification] Error request permissions: $e');
    }
    return true;
  }

  Map<String, String> _getChannelConfig(NotificationChannelType channel) {
    switch (channel) {
      case NotificationChannelType.teachingSchedule:
        return {
          'id': 'myinu_teaching_reminders',
          'name': 'Pengingat Jadwal Mengajar',
          'desc': 'Notifikasi pengingat sebelum perkuliahan dimulai.',
        };
      case NotificationChannelType.attendance:
        return {
          'id': 'myinu_attendance_reminders',
          'name': 'Pengingat Presensi Kerja',
          'desc': 'Notifikasi pengingat presensi masuk & pulang.',
        };
      case NotificationChannelType.assignment:
        return {
          'id': 'myinu_task_reminders',
          'name': 'Pengingat Tugas & Deadline',
          'desc': 'Pengingat tenggat waktu nilai dan tugas mahasiswa.',
        };
      case NotificationChannelType.announcement:
        return {
          'id': 'myinu_announcements',
          'name': 'Pengumuman Kampus',
          'desc': 'Informasi resmi dari rektorat dan BAAK.',
        };
    }
  }
}
