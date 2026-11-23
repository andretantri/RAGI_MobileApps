import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/models/simpeg_model.dart';
import '../../core/providers/simpeg_provider.dart';
import '../common/app_header.dart';

/// Catatan aktivitas presensi pegawai.
///
/// Hanya menampilkan baris yang benar-benar merekam scan/cuti/izin.
class ActivityLogScreen extends ConsumerWidget {
  const ActivityLogScreen({super.key});

  static const _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  void _changeMonth(WidgetRef ref, int delta) {
    final current = ref.read(attendanceRecapFilterProvider);
    var month = current.month + delta;
    var year = current.year;
    if (month < 1) {
      month = 12;
      year--;
    } else if (month > 12) {
      month = 1;
      year++;
    }
    ref.read(attendanceRecapFilterProvider.notifier).state =
        AttendanceRecapFilter(month: month, year: year);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(attendanceRecapFilterProvider);
    final recapAsync = ref.watch(attendanceRecapProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(attendanceRecapProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: AppHeader(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/simpeg');
                            }
                          },
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Log Aktivitas',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Rekaman presensi & catatan kepegawaian',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => _changeMonth(ref, -1),
                            icon: const Icon(Icons.chevron_left_rounded,
                                color: Colors.white, size: 24),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                '${_monthNames[filter.month - 1]} ${filter.year}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => _changeMonth(ref, 1),
                            icon: const Icon(Icons.chevron_right_rounded,
                                color: Colors.white, size: 24),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  recapAsync.when(
                    data: (recap) {
                      if (recap == null || recap.realRows.isEmpty) {
                        return _buildEmptyState();
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${recap.realRows.length} aktivitas tercatat',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...recap.realRows.map(_buildLogTile),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => _buildEmptyState(),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogTile(AttendanceRecapRow row) {
    final status = row.status.trim().toLowerCase();
    final color = switch (status) {
      'hadir' => const Color(0xFF2E7D32),
      'terlambat' => const Color(0xFFF57C00),
      'izin' || 'sakit' => const Color(0xFF1976D2),
      'cuti' => const Color(0xFF7B1FA2),
      'alpa' => const Color(0xFFD32F2F),
      _ => AppColors.primary,
    };

    final date = DateTime.tryParse(row.tanggal);
    final dateLabel = date != null
        ? DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(date)
        : row.tanggal;
    final timeLabel = [
      if (row.scanMasuk != null && row.scanMasuk!.isNotEmpty)
        'Masuk ${row.scanMasuk}',
      if (row.scanPulang != null && row.scanPulang!.isNotEmpty)
        'Pulang ${row.scanPulang}',
    ].join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 52,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dateLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        row.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                if (timeLabel.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    timeLabel,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (row.keterangan != null && row.keterangan!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    row.keterangan!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Column(
        children: [
          Icon(Icons.history_toggle_off_rounded,
              size: 44, color: AppColors.textHint),
          SizedBox(height: 12),
          Text(
            'Belum ada aktivitas presensi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Aktivitas akan muncul setelah Anda melakukan scan absen atau memiliki catatan cuti/izin tanggal tersebut. Baris libur dari kalender tidak ditampilkan.',
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
