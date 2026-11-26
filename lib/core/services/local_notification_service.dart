import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
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
  bool _tzInitialized = false;
  bool _appReady = false;
  String? _pendingRoute;

  static const int _attendanceMorningId = 1001;
  static const int _attendanceEveningId = 1002;
  static const int _teachingReminderBaseId = 2000;

  void _ensureTimezoneInitialized() {
    if (_tzInitialized) return;
    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      _tzInitialized = true;
    } catch (e) {
      debugPrint('[LocalNotification] Gagal init timezone: $e');
    }
  }

  /// Inisialisasi plugin notifikasi lokal untuk Android, iOS, Web & Desktop.
  /// Dipanggil dari main() agar tap notifikasi saat cold start tidak hilang.
  Future<void> init() async {
    _ensureTimezoneInitialized();
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
        try {
          await androidPlatform.requestExactAlarmsPermission();
        } catch (_) {}
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

  /// Jadwalkan ulang pengingat absensi harian (15 menit sebelum masuk & saat pulang).
  /// Dipanggil saat status shift dimuat atau saat preferensi notifikasi diubah.
  Future<void> syncAttendanceReminders({
    String? shiftStartTime,
    String? shiftEndTime,
    bool isDayOffToday = false,
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) await init();

    try {
      final prefs = await SharedPreferences.getInstance();
      final morningEnabled = prefs.getBool('notif_attendance_morning') ?? true;
      final eveningEnabled = prefs.getBool('notif_attendance_evening') ?? true;
      final soundEnabled = prefs.getBool('notif_sound') ?? true;
      final vibrationEnabled = prefs.getBool('notif_vibration') ?? true;

      if (shiftStartTime != null && shiftStartTime.isNotEmpty) {
        await prefs.setString('cached_shift_start_time', shiftStartTime);
      }
      if (shiftEndTime != null && shiftEndTime.isNotEmpty) {
        await prefs.setString('cached_shift_end_time', shiftEndTime);
      }

      final startStr = shiftStartTime ??
          prefs.getString('cached_shift_start_time') ??
          '08:00:00';
      final endStr = shiftEndTime ??
          prefs.getString('cached_shift_end_time') ??
          '16:00:00';

      await _notificationsPlugin.cancel(id: _attendanceMorningId);
      await _notificationsPlugin.cancel(id: _attendanceEveningId);

      if (isDayOffToday) return;

      final startParts = _parseHourMinute(startStr, fallbackHour: 8, fallbackMinute: 0);
      final endParts = _parseHourMinute(endStr, fallbackHour: 16, fallbackMinute: 0);

      // 15 menit sebelum jam masuk
      var morningMinuteTotal = startParts[0] * 60 + startParts[1] - 15;
      if (morningMinuteTotal < 0) morningMinuteTotal += 24 * 60;
      final morningHour = morningMinuteTotal ~/ 60;
      final morningMinute = morningMinuteTotal % 60;

      if (morningEnabled) {
        await _scheduleDailyTime(
          id: _attendanceMorningId,
          hour: morningHour,
          minute: morningMinute,
          title: 'Pengingat Presensi Masuk',
          body:
              '15 menit lagi jam masuk kerja (${_fmtHm(startParts[0], startParts[1])} WIB). Jangan lupa scan presensi.',
          channel: NotificationChannelType.attendance,
          soundEnabled: soundEnabled,
          vibrationEnabled: vibrationEnabled,
        );
      }

      if (eveningEnabled) {
        await _scheduleDailyTime(
          id: _attendanceEveningId,
          hour: endParts[0],
          minute: endParts[1],
          title: 'Pengingat Presensi Pulang',
          body:
              'Jam kerja selesai (${_fmtHm(endParts[0], endParts[1])} WIB). Jangan lupa lakukan presensi pulang.',
          channel: NotificationChannelType.attendance,
          soundEnabled: soundEnabled,
          vibrationEnabled: vibrationEnabled,
        );
      }
    } catch (e) {
      debugPrint('[LocalNotification] Gagal sync attendance reminders: $e');
    }
  }

  /// Jadwalkan pengingat kelas mingguan untuk Dosen Pengajar.
  Future<void> syncTeachingReminders(
    List<({int dayOfWeek, String startTime, String courseName, String room})>
        classes,
  ) async {
    if (kIsWeb) return;
    if (!_isInitialized) await init();

    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('notif_teaching_enabled') ?? true;
      final minutesBefore = prefs.getInt('notif_teaching_minutes') ?? 15;
      final soundEnabled = prefs.getBool('notif_sound') ?? true;
      final vibrationEnabled = prefs.getBool('notif_vibration') ?? true;

      for (var i = 0; i < 40; i++) {
        await _notificationsPlugin.cancel(id: _teachingReminderBaseId + i);
      }
      if (!enabled || classes.isEmpty) return;

      final channelConfig = _getChannelConfig(NotificationChannelType.teachingSchedule);
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelConfig['id']!,
          channelConfig['name']!,
          channelDescription: channelConfig['desc']!,
          importance: Importance.max,
          priority: Priority.high,
          playSound: soundEnabled,
          enableVibration: vibrationEnabled,
          color: const Color(0xFF0B52B3),
          icon: '@drawable/ic_stat_logo',
          largeIcon: const DrawableResourceAndroidBitmap('ic_notification_large'),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: soundEnabled,
        ),
      );

      for (var i = 0; i < classes.length && i < 40; i++) {
        final item = classes[i];
        final hm = _parseHourMinute(item.startTime, fallbackHour: 8, fallbackMinute: 0);
        final scheduled = _nextWeeklyInstance(
          dayOfWeek: item.dayOfWeek,
          hour: hm[0],
          minute: hm[1],
          minutesBefore: minutesBefore,
        );
        await _zonedScheduleWithFallback(
          id: _teachingReminderBaseId + i,
          title: 'Pengingat Mengajar: ${item.courseName}',
          body:
              '$minutesBefore menit lagi kelas dimulai (${_fmtHm(hm[0], hm[1])} WIB) di ${item.room}.',
          scheduledDate: scheduled,
          details: details,
          matchComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: '/schedule',
        );
      }
    } catch (e) {
      debugPrint('[LocalNotification] Gagal sync teaching reminders: $e');
    }
  }

  Future<void> _scheduleDailyTime({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required NotificationChannelType channel,
    required bool soundEnabled,
    required bool vibrationEnabled,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final channelConfig = _getChannelConfig(channel);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelConfig['id']!,
        channelConfig['name']!,
        channelDescription: channelConfig['desc']!,
        importance: Importance.max,
        priority: Priority.high,
        playSound: soundEnabled,
        enableVibration: vibrationEnabled,
        color: const Color(0xFF0B52B3),
        icon: '@drawable/ic_stat_logo',
        largeIcon: const DrawableResourceAndroidBitmap('ic_notification_large'),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: soundEnabled,
      ),
    );

    await _zonedScheduleWithFallback(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      details: details,
      matchComponents: DateTimeComponents.time,
      payload: routeForChannel(channel),
    );
  }

  Future<void> _zonedScheduleWithFallback({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    required DateTimeComponents matchComponents,
    required String payload,
  }) async {
    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchComponents,
        payload: payload,
      );
    } catch (_) {
      // Fallback ke inexactAllowWhileIdle jika izin exact alarm ditolak OS
      try {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: matchComponents,
          payload: payload,
        );
      } catch (e) {
        debugPrint('[LocalNotification] zonedSchedule gagal: $e');
      }
    }
  }

  tz.TZDateTime _nextWeeklyInstance({
    required int dayOfWeek,
    required int hour,
    required int minute,
    required int minutesBefore,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    var target = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute)
        .subtract(Duration(minutes: minutesBefore));
    while (target.weekday != dayOfWeek || !target.isAfter(now)) {
      target = target.add(const Duration(days: 1));
    }
    return target;
  }

  List<int> _parseHourMinute(
    String raw, {
    required int fallbackHour,
    required int fallbackMinute,
  }) {
    final m = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(raw);
    if (m == null) return [fallbackHour, fallbackMinute];
    final h = int.tryParse(m.group(1)!) ?? fallbackHour;
    final min = int.tryParse(m.group(2)!) ?? fallbackMinute;
    return [h.clamp(0, 23), min.clamp(0, 59)];
  }

  String _fmtHm(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}
