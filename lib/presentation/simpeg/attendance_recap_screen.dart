import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/models/simpeg_model.dart';
import '../../core/providers/simpeg_provider.dart';
import '../common/app_header.dart';

class AttendanceRecapScreen extends ConsumerWidget {
  const AttendanceRecapScreen({super.key});

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
    var newMonth = current.month + delta;
    var newYear = current.year;

    if (newMonth < 1) {
      newMonth = 12;
      newYear -= 1;
    } else if (newMonth > 12) {
      newMonth = 1;
      newYear += 1;
    }

    ref.read(attendanceRecapFilterProvider.notifier).state =
        AttendanceRecapFilter(month: newMonth, year: newYear);
  }

  static int _countStatus(
    List<AttendanceRecapRow> rows,
    Set<String> statuses,
  ) {
    return rows
        .where((row) => statuses.contains(row.status.trim().toLowerCase()))
        .length;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(attendanceRecapFilterProvider);
    final recapAsync = ref.watch(attendanceRecapProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(attendanceRecapProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // App Header
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Laporan Kehadiran',
                                style: AppTextStyles.headlineSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Rekap bulanan, kedisiplinan, & log presensi',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Selector Bulan & Tahun
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => _changeMonth(ref, -1),
                            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 24),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 18),
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
                            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24),
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

            // Content
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  recapAsync.when(
                    data: (recap) {
                      if (recap == null) {
                        return _buildEmptyState();
                      }

                      // Hitung dari rincian yang benar-benar tampil agar angka
                      // tidak memasukkan tanggal masa depan yang dikirim server.
                      final rows = recap.realRows;
                      final hadirCount = _countStatus(rows, const {'hadir'});
                      final terlambatCount =
                          _countStatus(rows, const {'terlambat'});
                      final izinSakitCount =
                          _countStatus(rows, const {'izin', 'sakit'});
                      final cutiCount = _countStatus(rows, const {'cuti'});
                      final alpaCount = _countStatus(rows, const {'alpa'});
                      final percentage = rows.isNotEmpty
                          ? (((hadirCount + terlambatCount) / rows.length) * 100)
                              .clamp(0, 100)
                              .toInt()
                          : 0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Ringkasan Tingkat Kehadiran
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.divider),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Tingkat Kehadiran Bulan Ini',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '$percentage%',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: percentage >= 85
                                            ? const Color(0xFF2E7D32)
                                            : const Color(0xFFF57C00),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: percentage / 100.0,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      percentage >= 85
                                          ? const Color(0xFF2E7D32)
                                          : const Color(0xFFF57C00),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Periode: ${recap.startDate} s/d ${recap.endDate} (${recap.totalDays} hari kalender)',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Ringkasan dan rincian dihitung hanya dari tanggal yang sudah berlalu.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 2. Metric Grid
                          Row(
                            children: [
                              Expanded(
                                child: _buildKpiCard(
                                  title: 'Tepat Waktu',
                                  value: '$hadirCount',
                                  unit: 'Hari',
                                  color: const Color(0xFF2E7D32),
                                  icon: Icons.check_circle_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildKpiCard(
                                  title: 'Terlambat',
                                  value: '$terlambatCount',
                                  unit: 'Hari',
                                  color: const Color(0xFFF57C00),
                                  icon: Icons.access_time_filled_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildKpiCard(
                                  title: 'Izin / Sakit',
                                  value: '$izinSakitCount',
                                  unit: 'Hari',
                                  color: const Color(0xFF1976D2),
                                  icon: Icons.medical_services_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: _buildKpiCard(
                                  title: 'Cuti Resmi',
                                  value: '$cutiCount',
                                  unit: 'Hari',
                                  color: const Color(0xFF7B1FA2),
                                  icon: Icons.beach_access_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildKpiCard(
                                  title: 'Alpa / Tanpa Ket',
                                  value: '$alpaCount',
                                  unit: 'Hari',
                                  color: const Color(0xFFD32F2F),
                                  icon: Icons.cancel_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildKpiCard(
                                  title: 'Libur / Akhir Pkn',
                                  value: '${recap.totalLibur}',
                                  unit: 'Hari',
                                  color: const Color(0xFF607D8B),
                                  icon: Icons.weekend_rounded,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // 3. Section Log Kehadiran Harian
                          const Text(
                            'Rincian Log Presensi Harian',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (recap.realRows.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.history_toggle_off_rounded,
                                      size: 34, color: AppColors.textHint),
                                  SizedBox(height: 10),
                                  Text(
                                    'Belum ada rekaman scan presensi pada bulan ini',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Baris libur/akhir pekan dan tanggal yang belum dilewati tidak ditampilkan sebagai presensi.',
                                    style: TextStyle(
                                      color: AppColors.textHint,
                                      fontSize: 11,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          else
                            ...recap.realRows.map((row) => _buildRowCard(row)),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Gagal memuat rekap presensi: $e',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String unit,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRowCard(AttendanceRecapRow row) {
    Color statusColor;
    String statusText;

    switch (row.status.toLowerCase()) {
      case 'hadir':
        statusColor = const Color(0xFF2E7D32);
        statusText = 'Hadir';
        break;
      case 'terlambat':
        statusColor = const Color(0xFFF57C00);
        statusText = 'Terlambat';
        break;
      case 'izin':
      case 'sakit':
        statusColor = const Color(0xFF1976D2);
        statusText = row.status.toUpperCase();
        break;
      case 'cuti':
        statusColor = const Color(0xFF7B1FA2);
        statusText = 'Cuti';
        break;
      case 'libur':
        statusColor = const Color(0xFF607D8B);
        statusText = 'Libur';
        break;
      default:
        final rawStatus = row.status.trim();
        if (rawStatus.isEmpty) {
          statusColor = const Color(0xFF607D8B);
          statusText = 'Tanpa Keterangan';
        } else {
          statusColor = const Color(0xFFD32F2F);
          statusText = rawStatus.toUpperCase();
        }
    }

    // Format tanggal memakai field `date` (ISO) bila tersedia dari server.
    String formattedDate = row.tanggal;
    final dateSource = row.date.isNotEmpty ? row.date : row.tanggal;
    try {
      final parsed = DateTime.parse(dateSource);
      formattedDate = DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(parsed);
    } catch (_) {
      try {
        final parsed = DateTime.parse(dateSource);
        formattedDate = DateFormat('EEEE, dd MMM yyyy').format(parsed);
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.login_rounded, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Masuk: ${row.scanMasuk ?? "-"}',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.logout_rounded, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Pulang: ${row.scanPulang ?? "-"}',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                    ),
                  ],
                ),
                if (row.keterangan != null && row.keterangan!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Catatan: ${row.keterangan}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
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
          Icon(Icons.event_busy_rounded, size: 42, color: AppColors.textHint),
          SizedBox(height: 12),
          Text(
            'Belum ada data kehadiran pada bulan ini',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Rekap akan muncul setelah Anda melakukan absen wajah atau memiliki catatan cuti/izin. Kalender libur tidak dihitung sebagai presensi.',
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
