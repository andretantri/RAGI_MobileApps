import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Model item kelas mengajar dosen
class TeachingClassItem {
  final int id;
  final String courseCode;
  final String courseName;
  final int sks;
  final String className;
  final String room;
  final String roomCode;
  final String startTime;
  final String endTime;
  final int studentCount;
  final int session;
  final String status;
  final String hari;
  final bool isToday;
  final bool isOngoing;
  final bool reminderActive;
  final String peran;

  const TeachingClassItem({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.sks,
    required this.className,
    required this.room,
    required this.roomCode,
    required this.startTime,
    required this.endTime,
    required this.studentCount,
    required this.session,
    required this.status,
    required this.hari,
    required this.isToday,
    required this.isOngoing,
    required this.reminderActive,
    required this.peran,
  });

  Color get statusColor {
    if (isOngoing) return AppColors.success;
    final s = status.toLowerCase();
    if (s.contains('mulai') || s.contains('akan')) return AppColors.warning;
    if (s.contains('selesai')) return AppColors.textSecondary;
    return AppColors.primary;
  }

  factory TeachingClassItem.fromJson(Map<String, dynamic> json) {
    return TeachingClassItem(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      courseCode: json['course_code']?.toString() ??
          json['courseCode']?.toString() ??
          'MK',
      courseName: json['course_name']?.toString() ??
          json['courseName']?.toString() ??
          'Mata Kuliah',
      sks: json['sks'] is int
          ? json['sks']
          : int.tryParse(json['sks']?.toString() ?? '3') ?? 3,
      className: json['class_name']?.toString() ??
          json['className']?.toString() ??
          'Kelas',
      room: json['room']?.toString() ?? '-',
      roomCode: json['room_code']?.toString() ??
          json['roomCode']?.toString() ??
          '-',
      startTime: json['start_time']?.toString() ??
          json['startTime']?.toString() ??
          '08:00',
      endTime: json['end_time']?.toString() ??
          json['endTime']?.toString() ??
          '10:30',
      studentCount: json['student_count'] is int
          ? json['student_count']
          : int.tryParse(json['student_count']?.toString() ?? '30') ?? 30,
      session: json['session'] is int
          ? json['session']
          : int.tryParse(json['session']?.toString() ?? '10') ?? 10,
      status: json['status']?.toString() ?? 'Terjadwal',
      hari: json['hari']?.toString() ?? '-',
      isToday: json['is_today'] == true || json['isToday'] == true,
      isOngoing: json['is_ongoing'] == true || json['isOngoing'] == true,
      reminderActive:
          json['reminder_active'] != false && json['reminderActive'] != false,
      peran: json['peran']?.toString() ?? 'Pengampu Utama',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'course_code': courseCode,
        'course_name': courseName,
        'sks': sks,
        'class_name': className,
        'room': room,
        'room_code': roomCode,
        'start_time': startTime,
        'end_time': endTime,
        'student_count': studentCount,
        'session': session,
        'status': status,
        'hari': hari,
        'is_today': isToday,
        'is_ongoing': isOngoing,
        'reminder_active': reminderActive,
        'peran': peran,
      };
}

/// Hasil respon lengkap jadwal mengajar dosen dari Backend RAG SIAKAD
class TeachingScheduleResult {
  final String lecturerName;
  final String nidn;
  final String todayDay;
  final List<TeachingClassItem> todayClasses;
  final List<TeachingClassItem> allClasses;
  final int totalSks;
  final int totalClasses;

  const TeachingScheduleResult({
    required this.lecturerName,
    required this.nidn,
    required this.todayDay,
    required this.todayClasses,
    required this.allClasses,
    required this.totalSks,
    required this.totalClasses,
  });

  factory TeachingScheduleResult.fromJson(Map<String, dynamic> json) {
    final dosen = json['dosen'] as Map<String, dynamic>? ?? {};
    final todayList = (json['today_classes'] as List<dynamic>? ?? [])
        .map((e) => TeachingClassItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final allList = (json['all_classes'] as List<dynamic>? ?? [])
        .map((e) => TeachingClassItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return TeachingScheduleResult(
      lecturerName: dosen['nama_gelar']?.toString() ??
          dosen['nama_lengkap']?.toString() ??
          'Dosen Pengajar',
      nidn: dosen['nidn']?.toString() ?? '-',
      todayDay: json['today_day']?.toString() ?? '-',
      todayClasses: todayList,
      allClasses: allList,
      totalSks: json['total_sks'] is int
          ? json['total_sks']
          : int.tryParse(json['total_sks']?.toString() ?? '0') ?? 0,
      totalClasses: json['total_kelas'] is int
          ? json['total_kelas']
          : int.tryParse(json['total_kelas']?.toString() ?? '0') ?? 0,
    );
  }
}
