import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myinu_staff/core/models/grading_model.dart';
import 'package:myinu_staff/core/models/advisee_model.dart';
import 'package:myinu_staff/presentation/siakad/grading/grading_classes_screen.dart';
import 'package:myinu_staff/presentation/siakad/advising/advisees_list_screen.dart';
import 'package:myinu_staff/presentation/siakad/advising/krs_approval_screen.dart';
import 'package:myinu_staff/presentation/siakad/advising/consultation_notes_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SIAKAD Fitur 3 (Input Nilai OBE/KHS) Model & Logic Tests', () {
    test('GradingClassItem parses correctly from JSON', () {
      final json = {
        'kelas_id': 101,
        'kode_kelas': 'IF301-A',
        'nama_kelas': 'Pemrograman Mobile (Kelas A)',
        'kode_mk': 'IF301',
        'nama_mk': 'Pemrograman Mobile',
        'sks': 4,
        'prodi': 'Teknologi Informasi',
        'hari': 'Senin',
        'jam': '08:00 - 10:30',
        'total_mahasiswa': 30,
        'jumlah_dinilai': 25,
        'status_penilaian': 'draft',
        'bobot': {
          'harian': 0.20,
          'uts': 0.25,
          'uas': 0.35,
          'praktik': 0.20,
        },
      };

      final item = GradingClassItem.fromJson(json);
      expect(item.kelasId, 101);
      expect(item.kodeKelas, 'IF301-A');
      expect(item.namaMk, 'Pemrograman Mobile');
      expect(item.totalMahasiswa, 30);
      expect(item.jumlahDinilai, 25);
      expect(item.isCompleted, isFalse);
    });

    test('StudentGradeItem recalculate computes OBE formula and grades correctly',
        () {
      final item = StudentGradeItem(
        krsDetailId: 1,
        mahasiswaId: 1,
        nim: '202301001',
        nama: 'Ahmad Faiz',
        nilaiHarian: 85,
        nilaiUts: 80,
        nilaiUas: 90,
        nilaiPraktik: 85,
      );

      // formula: 85*0.2 + 80*0.25 + 90*0.35 + 85*0.2 = 17 + 20 + 31.5 + 17 = 85.5 -> 'A' (4.0)
      final bobot = {'harian': 0.20, 'uts': 0.25, 'uas': 0.35, 'praktik': 0.20};
      item.recalculate(bobot);

      expect(item.nilaiAkhir, closeTo(85.5, 0.01));
      expect(item.nilaiHuruf, 'A');
      expect(item.bobotMutu, 4.0);
    });

    test('StudentGradeItem handles failing grades below 55 (D/E)', () {
      final item = StudentGradeItem(
        krsDetailId: 2,
        mahasiswaId: 2,
        nim: '202301002',
        nama: 'Mahasiswa Uji',
        nilaiHarian: 40,
        nilaiUts: 45,
        nilaiUas: 50,
        nilaiPraktik: 40,
      );

      final bobot = {'harian': 0.20, 'uts': 0.25, 'uas': 0.35, 'praktik': 0.20};
      item.recalculate(bobot);

      expect(item.nilaiAkhir, lessThan(55.0));
      expect(['D', 'E'], contains(item.nilaiHuruf));
    });
  });

  group('SIAKAD Fitur 4 (Bimbingan Akademik DPA & KRS) Model Tests', () {
    test('AdviseeStudent parses advisee and KRS status properly', () {
      final json = {
        'mahasiswa_id': 1,
        'nim': '202301001',
        'nama': 'Ahmad Faiz',
        'prodi': 'D3 Teknik Informatika',
        'angkatan': '2023',
        'ipk': 3.75,
        'sks_total': 68,
        'krs': {
          'krs_id': 10,
          'status': 'menunggu_persetujuan',
          'total_sks': 21,
          'jumlah_mk': 7,
          'catatan_revisi': null,
        },
      };

      final student = AdviseeStudent.fromJson(json);
      expect(student.nim, '202301001');
      expect(student.ipk, 3.75);
      expect(student.krs?.status, 'menunggu_persetujuan');
      expect(student.krs?.totalSks, 21);
    });

    test('PaConsultationNote parses consultation log properly', () {
      final json = {
        'id': 5,
        'mahasiswa_id': 1,
        'tanggal': '2026-11-20',
        'kategori': 'Konsultasi KRS',
        'isi': 'Konsultasi pengambilan mata kuliah semester 5.',
        'kesimpulan': 'Disetujui mengambil 22 SKS.',
        'dosen': 'Dr. Randhi Yuansyah',
      };

      final note = PaConsultationNote.fromJson(json);
      expect(note.id, 5);
      expect(note.kategori, 'Konsultasi KRS');
      expect(note.dosen, 'Dr. Randhi Yuansyah');
    });
  });

  group('SIAKAD Widget Screens Rendering Tests', () {
    testWidgets('GradingClassesScreen renders headers and structure',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GradingClassesScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Penilaian Mahasiswa'), findsOneWidget);
      expect(find.textContaining('OBE & KHS'), findsOneWidget);
      expect(find.text('Total Kelas'), findsOneWidget);
    });

    testWidgets('AdviseesListScreen renders header, DPA badge, and metrics',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AdviseesListScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Bimbingan Akademik (DPA)'), findsOneWidget);
      expect(find.text('DPA Aktif'), findsOneWidget);
      expect(find.text('Total Binaan'), findsOneWidget);
    });

    testWidgets('ConsultationNotesScreen renders logbook header and add button',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ConsultationNotesScreen(mahasiswaId: 1),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Catatan Bimbingan PA'), findsWidgets);
      expect(find.text('Tambah Catatan Konsultasi Baru'), findsOneWidget);
    });

    testWidgets('KrsApprovalScreen renders header and approval structure',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: KrsApprovalScreen(krsId: 1),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Persetujuan Rencana Studi'), findsOneWidget);
      expect(find.text('Minta Revisi'), findsOneWidget);
    });
  });
}
