import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myinu_staff/core/models/teaching_schedule_model.dart';
import 'package:myinu_staff/presentation/schedule/teaching_schedule_screen.dart';

void main() {
  group('TeachingScheduleModel Tests', () {
    test('TeachingClassItem parses correctly from json', () {
      final json = {
        'id': 7,
        'course_code': 'IF301',
        'course_name': 'Pemrograman Web & Mobile',
        'sks': 4,
        'class_name': 'Pemrograman Web & Mobile Kelas 20251',
        'room': 'Aula Utama Nusantara',
        'room_code': 'R-AULA-01',
        'start_time': '08:00',
        'end_time': '10:30',
        'student_count': 34,
        'session': 10,
        'status': 'Sedang Berlangsung',
        'hari': 'jumat',
        'is_today': true,
        'is_ongoing': true,
        'reminder_active': true,
        'peran': 'pengampu_utama',
      };

      final item = TeachingClassItem.fromJson(json);

      expect(item.id, 7);
      expect(item.courseCode, 'IF301');
      expect(item.courseName, 'Pemrograman Web & Mobile');
      expect(item.sks, 4);
      expect(item.isToday, isTrue);
      expect(item.isOngoing, isTrue);
      expect(item.reminderActive, isTrue);
    });

    test('TeachingScheduleResult parses envelope correctly', () {
      final envelope = {
        'dosen': {
          'id': 91,
          'nama_lengkap': 'DWI ISKANDAR',
          'nama_gelar': 'DWI ISKANDAR, M.Kom',
          'nidn': '0603048802',
          'nip': null,
          'is_fallback': false,
        },
        'today_day': 'jumat',
        'filter_day': null,
        'today_classes': [
          {
            'id': 7,
            'course_code': 'IF301',
            'course_name': 'Pemrograman Web & Mobile',
            'sks': 4,
            'class_name': 'Pemrograman Web & Mobile Kelas 20251',
            'room': 'Aula Utama Nusantara',
            'room_code': 'R-AULA-01',
            'start_time': '08:00',
            'end_time': '10:30',
            'student_count': 34,
            'session': 10,
            'status': 'Sedang Berlangsung',
            'hari': 'jumat',
            'is_today': true,
            'is_ongoing': true,
            'reminder_active': true,
            'peran': 'pengampu_utama',
          }
        ],
        'all_classes': [
          {
            'id': 10,
            'course_code': 'IF401',
            'course_name': 'Kecerdasan Buatan & Machine Learning',
            'sks': 3,
            'class_name': 'Kecerdasan Buatan & Machine Learning Kelas 20252',
            'room': 'Aula Utama Nusantara',
            'room_code': 'R-AULA-01',
            'start_time': '08:00',
            'end_time': '10:30',
            'student_count': 28,
            'session': 10,
            'status': 'Terjadwal',
            'hari': 'senin',
            'is_today': false,
            'is_ongoing': false,
            'reminder_active': true,
            'peran': 'pengampu_utama',
          }
        ],
        'total_sks': 7,
        'total_kelas': 2,
      };

      final result = TeachingScheduleResult.fromJson(envelope);

      expect(result.lecturerName, 'DWI ISKANDAR, M.Kom');
      expect(result.nidn, '0603048802');
      expect(result.todayDay, 'jumat');
      expect(result.todayClasses.length, 1);
      expect(result.allClasses.length, 1);
      expect(result.totalSks, 7);
      expect(result.totalClasses, 2);
    });

    testWidgets('TeachingScheduleScreen renders header, metrics, and day filters',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TeachingScheduleScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Jadwal Mengajar'), findsOneWidget);
      // Tidak ada klaim tahun/semester rekaan ketika data API belum tersedia.
      expect(find.textContaining('Semester Berjalan'), findsNothing);
      expect(find.text('Beban Mengajar'), findsOneWidget);
      expect(find.text('Total Kelas'), findsOneWidget);
      expect(find.text('Kelas Hari Ini'), findsOneWidget);
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Senin'), findsOneWidget);
      expect(find.text('Selasa'), findsOneWidget);
    });
  });
}
