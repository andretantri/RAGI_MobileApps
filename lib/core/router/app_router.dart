import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/auth/splash_screen.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/dashboard/main_shell.dart';
import '../../presentation/dashboard/home_screen.dart';
import '../../presentation/modules/modules_screen.dart';
import '../../presentation/scanner/scanner_screen.dart';
import '../../presentation/notifications/notifications_screen.dart';
import '../../presentation/profile/profile_screen.dart';
import '../../presentation/profile/biometric_security_screen.dart';
import '../../presentation/profile/face_enrollment_screen.dart';
import '../../presentation/profile/face_capture_screen.dart';
import '../../presentation/profile/about_app_screen.dart';
import '../../presentation/profile/notification_preferences_screen.dart';
import '../../presentation/profile/data_diri_screen.dart';
import '../../presentation/features/module_feature_hub_screen.dart';
import '../../presentation/features/mobile_feature_list_screen.dart';
import '../../presentation/features/mobile_feature_form_screen.dart';
import '../../presentation/features/mobile_staff_form_screen.dart';
import '../../presentation/features/mobile_staff_detail_screen.dart';
import '../../core/constants/mobile_feature_config.dart';
import '../../core/models/mobile_feature_model.dart';
import '../../presentation/schedule/teaching_schedule_screen.dart';
import '../../presentation/siakad/grading/grading_classes_screen.dart';
import '../../presentation/siakad/grading/class_grading_screen.dart';
import '../../presentation/siakad/advising/advisees_list_screen.dart';
import '../../presentation/siakad/advising/krs_approval_screen.dart';
import '../../presentation/siakad/advising/consultation_notes_screen.dart';
import '../../presentation/siakad/perkuliahan/perkuliahan_classes_screen.dart';
import '../../presentation/siakad/perkuliahan/class_journal_screen.dart';
import '../../presentation/siakad/perkuliahan/class_session_screen.dart';
import '../../presentation/simpeg/simpeg_dashboard_screen.dart';
import '../../presentation/simpeg/cuti_screen.dart';
import '../../presentation/simpeg/attendance_recap_screen.dart';
import '../../presentation/simpeg/activity_log_screen.dart';
import '../../presentation/simpeg/announcements_screen.dart';
import '../../presentation/simpeg/announcement_broadcast_screen.dart';
import '../../presentation/common/under_construction_screen.dart';

class AppRouter {
  static final _rootKey = GlobalKey<NavigatorState>();
  static final _shellKey = GlobalKey<NavigatorState>();

  /// Gunakan satu instance GoRouter agar service notifikasi dan UI
  /// menavigasi router yang sama dengan MaterialApp.router.
  static final GoRouter router = _createRouter();

  /// Form generik dipakai fitur lama; fitur self-service v1 baru memakai
  /// [MobileStaffFormScreen] yang mengambil ID master secara dinamis.
  static NoTransitionPage _formPage(String featureCode) {
    final feature = AppMobileFeatures.findByCode(featureCode);
    if (feature?.usesDedicatedForm ?? false) {
      return NoTransitionPage(
        child: MobileStaffFormScreen(featureCode: featureCode),
      );
    }
    return NoTransitionPage(
      child: MobileFeatureFormScreen(featureCode: featureCode),
    );
  }

  static GoRouter _createRouter() => GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: LoginScreen()),
      ),
      GoRoute(
        path: '/scanner',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const ScannerScreen(),
            transitionDuration: const Duration(milliseconds: 380),
            reverseTransitionDuration: const Duration(milliseconds: 320),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // Animasi membuka membesar dari tombol presensi di tengah bawah (Alignment.bottomCenter),
              // dan saat kembali / back-swipe, mengecil dan melingkar kembali masuk ke tombol tengah bawah.
              final curvedAnimation = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInOutCubic,
              );

              final scaleAnimation = Tween<double>(
                begin: 0.08,
                end: 1.0,
              ).animate(curvedAnimation);

              final radiusAnimation = Tween<double>(
                begin: 100.0,
                end: 0.0,
              ).animate(curvedAnimation);

              final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
                  reverseCurve: const Interval(0.25, 1.0, curve: Curves.easeIn),
                ),
              );

              return AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  return Transform.scale(
                    scale: scaleAnimation.value,
                    alignment: const Alignment(
                      0.0,
                      0.95,
                    ), // Posisi tombol absen tengah bawah
                    child: FadeTransition(
                      opacity: fadeAnimation,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          radiusAnimation.value,
                        ),
                        child: child,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/profile/biometric',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) =>
            const MaterialPage(child: BiometricSecurityScreen()),
      ),
      GoRoute(
        path: '/profile/about',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) =>
            const MaterialPage(child: AboutAppScreen()),
      ),
      GoRoute(
        path: '/profile/notification-preferences',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) =>
            const MaterialPage(child: NotificationPreferencesScreen()),
      ),
      GoRoute(
        path: '/profile/face-enrollment',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: FaceEnrollmentScreen()),
      ),
      GoRoute(
        path: '/face-capture',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: FaceCaptureScreen()),
      ),
      GoRoute(
        path: '/schedule',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: TeachingScheduleScreen()),
      ),
      GoRoute(
        path: '/siakad/grading',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: GradingClassesScreen()),
      ),
      GoRoute(
        path: '/siakad/grading/:kelasId',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) {
          final kelasId =
              int.tryParse(state.pathParameters['kelasId'] ?? '') ?? 1;
          return NoTransitionPage(child: ClassGradingScreen(kelasId: kelasId));
        },
      ),
      GoRoute(
        path: '/siakad/advising',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: AdviseesListScreen()),
      ),
      GoRoute(
        path: '/siakad/advising/krs/:krsId',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) {
          final krsId = int.tryParse(state.pathParameters['krsId'] ?? '') ?? 1;
          return NoTransitionPage(child: KrsApprovalScreen(krsId: krsId));
        },
      ),
      GoRoute(
        path: '/siakad/advising/notes/:mahasiswaId',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) {
          final mhsId =
              int.tryParse(state.pathParameters['mahasiswaId'] ?? '') ?? 1;
          return NoTransitionPage(
            child: ConsultationNotesScreen(mahasiswaId: mhsId),
          );
        },
      ),
      GoRoute(
        path: '/siakad/perkuliahan',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: PerkuliahanClassesScreen()),
      ),
      GoRoute(
        path: '/siakad/perkuliahan/:kelasId',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) {
          final kelasId =
              int.tryParse(state.pathParameters['kelasId'] ?? '') ?? 13;
          return NoTransitionPage(child: ClassJournalScreen(kelasId: kelasId));
        },
      ),
      GoRoute(
        path: '/siakad/perkuliahan/session/:pertemuanId',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) {
          final pertemuanId =
              int.tryParse(state.pathParameters['pertemuanId'] ?? '') ?? 1;
          return NoTransitionPage(
            child: ClassSessionScreen(pertemuanId: pertemuanId),
          );
        },
      ),
      GoRoute(
        path: '/simpeg',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: SimpegDashboardScreen()),
      ),
      GoRoute(
        path: '/simpeg/cuti',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: CutiScreen()),
      ),
      GoRoute(
        path: '/simpeg/rekap',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: AttendanceRecapScreen()),
      ),
      GoRoute(
        path: '/simpeg/log-aktivitas',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: ActivityLogScreen()),
      ),
      GoRoute(
        path: '/simpeg/announcements',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: AnnouncementsScreen()),
      ),
      GoRoute(
        path: '/simpeg/broadcast',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: AnnouncementBroadcastScreen()),
      ),
      GoRoute(
        path: '/profile/data-diri',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) =>
            const NoTransitionPage(child: DataDiriScreen()),
      ),
      GoRoute(
        path: '/modules/:moduleCode',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) => NoTransitionPage(
          child: ModuleFeatureHubScreen(
            moduleCode: state.pathParameters['moduleCode'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/features/:featureCode',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) => NoTransitionPage(
          child: MobileFeatureListScreen(
            featureCode: state.pathParameters['featureCode'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/features/:featureCode/form',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) =>
            _formPage(state.pathParameters['featureCode'] ?? ''),
      ),
      GoRoute(
        path: '/mobile-staff/form/:featureCode',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) =>
            _formPage(state.pathParameters['featureCode'] ?? ''),
      ),
      GoRoute(
        path: '/mobile-staff/detail/:featureCode/:id',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) => NoTransitionPage(
          child: MobileStaffDetailScreen(
            featureCode: state.pathParameters['featureCode'] ?? '',
            id: state.pathParameters['id'] ?? '',
            initialItem: state.extra is MobileFeatureItem
                ? state.extra as MobileFeatureItem
                : null,
          ),
        ),
      ),
      GoRoute(
        path: '/under-construction',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final query = state.uri.queryParameters;
          return NoTransitionPage(
            child: UnderConstructionScreen(
              title:
                  extra['title']?.toString() ??
                  query['title'] ??
                  'Layanan Modul',
              subtitle: extra['subtitle']?.toString() ?? query['subtitle'],
              category: extra['category']?.toString() ?? query['category'],
              icon: extra['icon'] as IconData?,
              color: extra['color'] as Color?,
            ),
          );
        },
      ),
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (ctx, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (ctx, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/modules',
            pageBuilder: (ctx, state) =>
                const NoTransitionPage(child: ModulesScreen()),
          ),
          GoRoute(
            path: '/notifications',
            pageBuilder: (ctx, state) =>
                const NoTransitionPage(child: NotificationsScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (ctx, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
    ],
  );
}
