import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/simpeg_model.dart';
import '../models/teaching_schedule_model.dart';

/// Menyinkronkan jadwal mengajar (Dosen) dan pengumuman kampus (Semua Role)
/// ke Widget Home Screen (Android).
class HomeWidgetService {
  static const MethodChannel _channel =
      MethodChannel('com.minu.staff.myinu_staff/widget');

  static const String _keyIsDosen = 'widget_is_dosen';
  static const String _keyPayload = 'widget_teaching_schedule_json';
  static const String _keyAnnouncements = 'widget_announcements_json';

  static Future<void> syncTeachingSchedule({
    required TeachingScheduleResult? schedule,
    required bool isDosen,
  }) async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsDosen, isDosen);

      final classes = isDosen ? (schedule?.todayClasses ?? []) : <TeachingClassItem>[];
      final payload = {
        'is_dosen': isDosen,
        'day_label': _todayLabel(),
        'lecturer_name': schedule?.lecturerName ?? '',
        'classes': classes
            .take(4)
            .map((c) => {
                  'time': '${c.startTime} - ${c.endTime}',
                  'course': c.courseName,
                  'room': c.room,
                  'class_name': c.className,
                })
            .toList(),
      };

      await prefs.setString(_keyPayload, jsonEncode(payload));
      await _channel.invokeMethod('updateWidget');
    } catch (e) {
      debugPrint('[HomeWidgetService] Gagal sync widget jadwal: $e');
    }
  }

  static Future<void> syncAnnouncements(
    List<CampusAnnouncementItem> items, {
    bool? isDosen,
  }) async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (isDosen != null) {
        await prefs.setBool(_keyIsDosen, isDosen);
      }

      final payload = {
        'day_label': _todayLabel(),
        'items': items
            .take(4)
            .map((a) => {
                  'category': _formatCategory(a.category),
                  'title': a.title,
                  'subtitle': (a.eventDate != null && a.eventDate!.isNotEmpty)
                      ? a.eventDate!
                      : a.content,
                })
            .toList(),
      };

      await prefs.setString(_keyAnnouncements, jsonEncode(payload));
      await _channel.invokeMethod('updateWidget');
    } catch (e) {
      debugPrint('[HomeWidgetService] Gagal sync widget pengumuman: $e');
    }
  }

  static Future<void> clearWidget() async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyIsDosen);
      await prefs.remove(_keyPayload);
      await prefs.remove(_keyAnnouncements);
      await _channel.invokeMethod('updateWidget');
    } catch (_) {}
  }

  static String _formatCategory(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.isEmpty) return 'Kampus';
    return lower[0].toUpperCase() + lower.substring(1);
  }

  static String _todayLabel() {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final now = DateTime.now();
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }
}
