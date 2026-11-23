import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myinu_staff/core/providers/auth_provider.dart';
import 'package:myinu_staff/core/services/attendance_service.dart';
import 'package:myinu_staff/core/services/face_capture_preferences.dart';
import 'package:myinu_staff/presentation/profile/biometric_security_screen.dart';
import 'package:myinu_staff/presentation/profile/face_enrollment_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'biometric_fingerprint_enabled': true,
    });
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Biometric Security & 3-Pose Face Enrollment Tests', () {
    test('AttendanceService enrollFace and resetFace do not fake success when API fails',
        () async {
      // Lingkungan test tidak memiliki akses ke API produksi. Karena itu
      // service tidak boleh mengembalikan "sukses" rekaan.
      final enrollRes = await AttendanceService.enrollFace(
        photosBase64: [
          'test_pose_1_tegap',
          'test_pose_2_nunduk',
          'test_pose_3_dongak',
        ],
      );
      expect(enrollRes.success, isFalse);
      expect(enrollRes.message, isNot(contains('Wajah berhasil didaftarkan')));

      final resetRes = await AttendanceService.resetFace();
      expect(resetRes.success, isFalse);
      expect(
        resetRes.message,
        isNot(contains('Data biometrik wajah berhasil direset')),
      );
    });

    test('AuthNotifier updateFaceEnrollment updates user model state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authProvider.notifier);

      // Initially no user logged in
      expect(container.read(authProvider).user, isNull);

      // Update face enrollment
      notifier.updateFaceEnrollment(
        isEnrolled: true,
        enrolledAt: '20 Nov 2026, 21:00 WIB',
      );

      final user = container.read(authProvider).user;
      expect(user, isNotNull);
      expect(user!.isFaceEnrolled, isTrue);
      expect(user.faceEnrolledAt, '20 Nov 2026, 21:00 WIB');

      // Reset face enrollment
      notifier.updateFaceEnrollment(
        isEnrolled: false,
        enrolledAt: null,
      );
      expect(container.read(authProvider).user!.isFaceEnrolled, isFalse);
      expect(container.read(authProvider).user!.faceEnrolledAt, isNull);
    });

    testWidgets('BiometricSecurityScreen renders face card and retake button',
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
            home: BiometricSecurityScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify app bar title
      expect(find.text('Keamanan Biometrik'), findsOneWidget);

      // Verify Face Recognition Section (default: belum terdaftar, tanpa data rekaan)
      expect(find.text('Wajah Terdaftar (Maksimal 1)'), findsOneWidget);
      expect(find.text('Belum Ada'), findsOneWidget);
      expect(find.text('Daftarkan Wajah Sekarang'), findsOneWidget);

      // Mode ambil wajah default adalah auto (deteksi objek wajah).
      expect(find.text('MODE AMBIL FOTO WAJAH'), findsOneWidget);
      expect(find.text('Otomatis'), findsOneWidget);
      expect(find.text('Manual'), findsOneWidget);
      final modeSelector =
          tester.widget<SegmentedButton<FaceCaptureMode>>(find.byType(
        SegmentedButton<FaceCaptureMode>,
      ));
      expect(modeSelector.selected, <FaceCaptureMode>{FaceCaptureMode.auto});

      // Verify Fingerprint Biometric Switch & Local Security Explanation
      expect(find.text('Presensi & Login Sidik Jari'), findsOneWidget);
      expect(find.textContaining('Secure Enclave / Keystore'), findsOneWidget);
    });

    testWidgets(
        'FaceEnrollmentScreen renders 3-pose chips and rejects simulated photos',
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
            home: FaceEnrollmentScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Screen Title & 3-Pose Chips
      expect(find.text('PEREKAMAN 3 POSE WAJAH'), findsOneWidget);
      expect(find.text('Tegap'), findsOneWidget);
      expect(find.text('Nunduk'), findsOneWidget);
      expect(find.text('Mendongak'), findsOneWidget);

      // Mode default auto: kamera langsung menyala dan tombol memulai deteksi.
      const autoButton = 'Mulai Take Otomatis (Deteksi Wajah)';
      expect(find.text('📸 Pose 1/3: Tegap Hadap Depan'), findsOneWidget);
      expect(find.text(autoButton), findsOneWidget);

      // Tombol baru aktif setelah persetujuan PDP dicentang.
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, autoButton),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();

      // Tanpa kamera yang siap, tombol tidak boleh mengirim foto rekaan
      // atau mengklaim pendaftaran berhasil.
      await tester.tap(find.text(autoButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(autoButton), findsOneWidget);
      expect(find.text('Wajah Berhasil Didaftarkan'), findsNothing);
    });
  });
}
