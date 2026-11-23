import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      );
    } catch (_) {}
  }

  // Inisialisasi lebih awal supaya payload notifikasi yang membuka aplikasi
  // (cold start) tetap tersimpan sampai router siap.
  await LocalNotificationService.instance.init();

  runApp(const ProviderScope(child: MyInUStaffApp()));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    LocalNotificationService.instance.markAppReady();
  });
}

class MyInUStaffApp extends StatelessWidget {
  const MyInUStaffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MyIn-U Staff',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}
