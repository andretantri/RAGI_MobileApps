import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/teaching_schedule_model.dart';
import '../services/home_widget_service.dart';
import '../services/local_notification_service.dart';
import '../services/schedule_service.dart';
import '../services/simpeg_service.dart';
import 'auth_provider.dart';

class ScheduleState {
  final bool isLoading;
  final TeachingScheduleResult? schedule;
  final String? errorMessage;

  const ScheduleState({
    this.isLoading = false,
    this.schedule,
    this.errorMessage,
  });

  ScheduleState copyWith({
    bool? isLoading,
    TeachingScheduleResult? schedule,
    String? errorMessage,
  }) {
    return ScheduleState(
      isLoading: isLoading ?? this.isLoading,
      schedule: schedule ?? this.schedule,
      errorMessage: errorMessage,
    );
  }

  List<TeachingClassItem> get todayClasses => schedule?.todayClasses ?? [];
  List<TeachingClassItem> get allClasses => schedule?.allClasses ?? [];
  int get totalSks => schedule?.totalSks ?? 0;
  int get totalClasses => schedule?.totalClasses ?? 0;
}

class ScheduleNotifier extends StateNotifier<ScheduleState> {
  final Ref ref;

  ScheduleNotifier(this.ref) : super(const ScheduleState()) {
    loadSchedule();
  }

  Future<void> loadSchedule() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // Ambil cache terlebih dahulu agar render instan
    final cached = await ScheduleService.getCachedSchedule();
    if (cached != null && mounted) {
      state = state.copyWith(schedule: cached);
    }

    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user != null && !user.isDosen) {
      await HomeWidgetService.syncTeachingSchedule(
        schedule: null,
        isDosen: false,
      );
      try {
        final announcements = await SimpegService.fetchAnnouncements();
        await HomeWidgetService.syncAnnouncements(
          announcements,
          isDosen: false,
        );
      } catch (_) {}
    }
    // SIAKAD mengenali dosen berdasarkan NIDN. Kode pegawai (NIP) tetap
    // dikirim sebagai fallback/parameter tambahan untuk backend lama.
    final nidn = (user?.nidn != null && user!.nidn.isNotEmpty)
        ? user.nidn
        : user?.nip;
    final nip = user?.nip;
    if ((nidn == null || nidn.isEmpty) && (nip == null || nip.isEmpty)) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Data dosen belum tersedia. Jadwal tidak dimuat.',
        );
      }
      return;
    }

    try {
      final fresh = await ScheduleService.fetchTeachingSchedule(
        nidn: nidn,
        nip: nip,
      );

      if (fresh != null && mounted) {
        state = state.copyWith(
          isLoading: false,
          schedule: fresh,
          errorMessage: null,
        );
        final isDosen = user?.isDosen ?? false;
        await HomeWidgetService.syncTeachingSchedule(
          schedule: fresh,
          isDosen: isDosen,
        );
        if (isDosen) {
          final reminderClasses = fresh.allClasses
              .map((c) => (
                    dayOfWeek: _hariToWeekday(c.hari),
                    startTime: c.startTime,
                    courseName: c.courseName,
                    room: c.room,
                  ))
              .toList();
          await LocalNotificationService.instance
              .syncTeachingReminders(reminderClasses);
        }
      } else if (mounted) {
        state = state.copyWith(isLoading: false);
        await HomeWidgetService.syncTeachingSchedule(
          schedule: state.schedule,
          isDosen: user?.isDosen ?? false,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Gagal memuat jadwal mengajar: $e',
        );
      }
    }
  }

  Future<void> refresh() async {
    await loadSchedule();
  }

  void reset() {
    state = const ScheduleState();
    HomeWidgetService.clearWidget();
  }

  static int _hariToWeekday(String hari) {
    switch (hari.trim().toLowerCase()) {
      case 'senin':
        return DateTime.monday;
      case 'selasa':
        return DateTime.tuesday;
      case 'rabu':
        return DateTime.wednesday;
      case 'kamis':
        return DateTime.thursday;
      case 'jumat':
      case "jum'at":
        return DateTime.friday;
      case 'sabtu':
        return DateTime.saturday;
      case 'minggu':
      case 'ahad':
        return DateTime.sunday;
      default:
        return DateTime.monday;
    }
  }
}

final scheduleProvider =
    StateNotifierProvider<ScheduleNotifier, ScheduleState>((ref) {
  return ScheduleNotifier(ref);
});
