import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../services/notification_service.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final String time;
  final bool isRead;
  final String module;
  final String period; // 'Hari Ini', 'Kemarin', 'Terdahulu'
  final String route; // halaman tujuan saat notifikasi diklik

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    required this.time,
    this.isRead = false,
    required this.module,
    this.period = 'Hari Ini',
    this.route = '/notifications',
  });

  NotificationItem copyWith({
    bool? isRead,
    String? period,
    String? route,
  }) {
    return NotificationItem(
      id: id,
      title: title,
      body: body,
      icon: icon,
      color: color,
      time: time,
      isRead: isRead ?? this.isRead,
      module: module,
      period: period ?? this.period,
      route: route ?? this.route,
    );
  }

  factory NotificationItem.fromApi(Map<String, dynamic> json) {
    final title = json['title']?.toString() ?? 'Pemberitahuan Sistem';
    final message = json['message']?.toString() ?? json['body']?.toString() ?? '';
    final rawModule = json['module'];
    final moduleCode = rawModule is Map
        ? (rawModule['code'] ?? rawModule['name'] ?? '').toString().toUpperCase()
        : (rawModule ?? '').toString().toUpperCase();
    final type = (json['type'] ?? '').toString().toUpperCase();
    final entityType = (json['entity_type'] ?? '').toString().toUpperCase();
    final url = (json['url'] ?? '').toString().trim();
    final isRead = json['is_read'] == true;
    final createdAt = json['created_at']?.toString() ?? '';

    final haystack =
        [moduleCode, type, entityType, title, message].join(' ').toLowerCase();

    // Resolusi modul & ikon. Module code dari API lebih diutamakan daripada
    // teks judul agar notifikasi admin SIMPEG tidak salah dikelompokkan.
    String module = 'SISTEM';
    if (moduleCode.contains('SIAKAD') ||
        type.contains('SIAKAD') ||
        haystack.contains('jadwal') ||
        haystack.contains('nilai') ||
        haystack.contains('krs')) {
      module = 'SIAKAD';
    } else if (moduleCode.contains('SIMPEG') ||
        type.contains('SIMPEG') ||
        haystack.contains('cuti') ||
        haystack.contains('pegawai') ||
        (haystack.contains('pengumuman') && !haystack.contains('presensi'))) {
      module = 'SIMPEG';
    } else if (moduleCode.contains('PRESENSI') ||
        moduleCode.contains('ABSEN') ||
        type.contains('PRESENSI') ||
        type.contains('ATTENDANCE') ||
        haystack.contains('presensi') ||
        haystack.contains('absen') ||
        haystack.contains('clock in') ||
        haystack.contains('clock-out')) {
      module = 'PRESENSI';
    } else if (moduleCode.contains('SIPPM') ||
        type.contains('SIPPM') ||
        haystack.contains('riset') ||
        haystack.contains('penelitian')) {
      module = 'SIPPM';
    } else if (moduleCode.contains('SIKEU') ||
        type.contains('SIKEU') ||
        haystack.contains('keuangan') ||
        haystack.contains('gaji')) {
      module = 'SIKEU';
    }

    String period = 'Hari Ini';
    String timeFormatted = 'Baru saja';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        final now = DateTime.now();
        final diffDays = now.difference(dt).inDays;
        if (diffDays == 0) {
          period = 'Hari Ini';
          timeFormatted = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} WIB';
        } else if (diffDays == 1) {
          period = 'Kemarin';
          timeFormatted = 'Kemarin, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        } else {
          period = 'Terdahulu';
          timeFormatted = '${dt.day}/${dt.month}/${dt.year}';
        }
      } catch (_) {}
    }

    return NotificationItem(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      title: title,
      body: message,
      icon: _iconForModule(module),
      color: _colorForModule(module),
      time: timeFormatted,
      isRead: isRead,
      module: module,
      period: period,
      route: _routeForNotification(
        url: url,
        moduleCode: moduleCode,
        type: type,
        entityType: entityType,
        title: title,
        message: message,
      ),
    );
  }

  /// Tentukan halaman tujuan saat notifikasi diklik.
  /// URL internal dari backend diprioritaskan, lalu fallback berdasarkan
  /// modul/type/entity/judul agar notifikasi lama tanpa `url` tetap bisa
  /// membuka halaman yang relevan.
  static String _routeForNotification({
    required String url,
    required String moduleCode,
    required String type,
    required String entityType,
    required String title,
    required String message,
  }) {
    if (url.startsWith('/') && !url.startsWith('//')) {
      final path = url.split('?').first;
      if (_isSupportedRoute(path)) return url;
    }

    final text =
        [moduleCode, type, entityType, title, message].join(' ').toLowerCase();

    if (text.contains('belum absen') ||
        text.contains('absen') ||
        text.contains('presensi') ||
        text.contains('attendance') ||
        text.contains('clock in') ||
        text.contains('clock-out')) {
      return '/scanner';
    }
    if (text.contains('pengumuman') ||
        text.contains('announcement') ||
        (moduleCode.contains('SIMPEG') &&
            (text.contains('informasi') || text.contains('admin')))) {
      return '/simpeg/announcements';
    }
    if (text.contains('cuti') || text.contains('leave')) return '/simpeg/cuti';
    if (text.contains('rekap') || text.contains('recap')) return '/simpeg/rekap';
    if (text.contains('jadwal') ||
        text.contains('mengajar') ||
        text.contains('schedule')) {
      return '/schedule';
    }
    if (text.contains('nilai') ||
        text.contains('grading') ||
        text.contains('grade')) {
      return '/siakad/grading';
    }
    if (text.contains('bimbingan') ||
        text.contains('advising') ||
        text.contains('krs') ||
        text.contains('konsultasi')) {
      return '/siakad/advising';
    }
    if (text.contains('perkuliahan') ||
        text.contains('kelas') ||
        text.contains('class') ||
        text.contains('tugas')) {
      return '/siakad/perkuliahan';
    }
    if (moduleCode.contains('SIPPM') ||
        text.contains('riset') ||
        text.contains('penelitian')) {
      return '/modules';
    }
    if (moduleCode.contains('SIKEU') ||
        text.contains('gaji') ||
        text.contains('keuangan')) {
      return '/modules';
    }
    return '/notifications';
  }

  /// Hanya terima URL internal yang memang punya route di AppRouter.
  /// URL detail yang tidak terdaftar jangan sampai membuat GoRouter error;
  /// fallback ke halaman induk yang relevan lebih aman.
  static bool _isSupportedRoute(String path) {
    const staticRoutes = [
      '/scanner',
      '/schedule',
      '/siakad/grading',
      '/siakad/advising',
      '/siakad/perkuliahan',
      '/simpeg',
      '/simpeg/cuti',
      '/simpeg/rekap',
      '/simpeg/announcements',
      '/simpeg/broadcast',
      '/notifications',
      '/modules',
      '/profile/notification-preferences',
    ];
    if (staticRoutes.contains(path)) return true;
    return RegExp(r'^/siakad/grading/\d+$').hasMatch(path) ||
        RegExp(r'^/siakad/advising/(krs|notes)/\d+$').hasMatch(path) ||
        RegExp(r'^/siakad/perkuliahan/\d+$').hasMatch(path) ||
        RegExp(r'^/siakad/perkuliahan/session/\d+$').hasMatch(path);
  }

  static IconData _iconForModule(String module) {
    switch (module.toUpperCase()) {
      case 'PRESENSI':
        return Icons.fingerprint_rounded;
      case 'SIAKAD':
        return Icons.school_rounded;
      case 'SIMPEG':
        return Icons.badge_rounded;
      case 'SIPPM':
        return Icons.science_rounded;
      case 'SIKEU':
        return Icons.receipt_long_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  static Color _colorForModule(String module) {
    switch (module.toUpperCase()) {
      case 'PRESENSI':
        return AppColors.success;
      case 'SIAKAD':
        return AppColors.siakad;
      case 'SIMPEG':
        return AppColors.primaryMid;
      case 'SIPPM':
        return AppColors.sippm;
      case 'SIKEU':
        return AppColors.sikeu;
      default:
        return AppColors.primary;
    }
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final module = json['module']?.toString() ?? 'SISTEM';
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      icon: _iconForModule(module),
      color: _colorForModule(module),
      time: json['time']?.toString() ?? '',
      isRead: json['is_read'] == true,
      module: module,
      period: json['period']?.toString() ?? 'Hari Ini',
      route: json['route']?.toString() ?? '/notifications',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'time': time,
        'is_read': isRead,
        'module': module,
        'period': period,
        'route': route,
      };
}

class NotificationState {
  final List<NotificationItem> items;
  final String activeFilter; // 'semua', 'unread', 'siakad', 'simpeg', 'presensi', 'sippm'
  final bool isLoading;
  final String? errorMessage;

  const NotificationState({
    required this.items,
    this.activeFilter = 'semua',
    this.isLoading = false,
    this.errorMessage,
  });

  int get unreadCount => items.where((i) => !i.isRead).length;

  List<NotificationItem> get filteredItems {
    switch (activeFilter.toLowerCase()) {
      case 'unread':
        return items.where((i) => !i.isRead).toList();
      case 'siakad':
        return items.where((i) => i.module.toUpperCase() == 'SIAKAD').toList();
      case 'simpeg':
        return items.where((i) => i.module.toUpperCase() == 'SIMPEG').toList();
      case 'presensi':
        return items
            .where((i) =>
                i.module.toUpperCase() == 'PRESENSI' ||
                i.title.toLowerCase().contains('presensi') ||
                i.title.toLowerCase().contains('absen'))
            .toList();
      case 'sippm':
        return items.where((i) => i.module.toUpperCase() == 'SIPPM').toList();
      default:
        return items;
    }
  }

  Map<String, List<NotificationItem>> get groupedByPeriod {
    final map = <String, List<NotificationItem>>{};
    for (final item in filteredItems) {
      map.putIfAbsent(item.period, () => []).add(item);
    }
    return map;
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(const NotificationState(items: [])) {
    loadNotifications();
  }

  /// Muat notifikasi dari API server RAG. Cache lokal hanya dipakai sebagai
  /// data sementara saat loading/gagal, bukan sebagai data dummy.
  Future<void> loadNotifications() async {
    state = NotificationState(
      items: state.items,
      activeFilter: state.activeFilter,
      isLoading: true,
      errorMessage: state.errorMessage,
    );

    final cached = await NotificationService.getCachedNotifications();
    if (cached.isNotEmpty && mounted) {
      state = NotificationState(
        items: state.items.isEmpty ? cached : state.items,
        activeFilter: state.activeFilter,
        isLoading: true,
        errorMessage: state.errorMessage,
      );
    }

    final result = await NotificationService.fetchNotifications();
    if (!mounted) return;
    state = NotificationState(
      items: result.items.isNotEmpty ? result.items : state.items,
      activeFilter: state.activeFilter,
      isLoading: false,
      errorMessage: result.error,
    );
  }

  void setFilter(String filter) {
    state = NotificationState(
      items: state.items,
      activeFilter: filter,
      isLoading: state.isLoading,
      errorMessage: state.errorMessage,
    );
  }

  Future<bool> markAllAsRead() async {
    final previous = state.items;
    state = NotificationState(
      items: previous.map((i) => i.copyWith(isRead: true)).toList(),
      activeFilter: state.activeFilter,
      isLoading: state.isLoading,
      errorMessage: state.errorMessage,
    );

    final success = await NotificationService.markAllAsRead();
    if (!success && mounted) {
      state = NotificationState(
        items: previous,
        activeFilter: state.activeFilter,
        isLoading: state.isLoading,
        errorMessage: state.errorMessage ??
            'Gagal memperbarui status notifikasi di server.',
      );
    }
    return success;
  }

  Future<bool> markAsRead(String id) async {
    final previous = state.items;
    state = NotificationState(
      items: previous
          .map((i) => i.id == id ? i.copyWith(isRead: true) : i)
          .toList(),
      activeFilter: state.activeFilter,
      isLoading: state.isLoading,
      errorMessage: state.errorMessage,
    );

    final success = await NotificationService.markAsRead(id);
    if (!success && mounted) {
      state = NotificationState(
        items: previous,
        activeFilter: state.activeFilter,
        isLoading: state.isLoading,
        errorMessage: state.errorMessage ??
            'Gagal memperbarui status notifikasi di server.',
      );
    }
    return success;
  }

  /// Tambah notifikasi aktivitas pengguna baru
  void addNotification(NotificationItem item) {
    state = NotificationState(
      items: [item, ...state.items],
      activeFilter: state.activeFilter,
      isLoading: state.isLoading,
      errorMessage: state.errorMessage,
    );
    NotificationService.addLocalNotification(item);
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});
