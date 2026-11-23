import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/schedule_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../common/app_header.dart';

/// Ringkasan data diri pegawai yang bersumber dari akun SSO dan SIAKAD.
class DataDiriScreen extends ConsumerWidget {
  const DataDiriScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final schedule = ref.watch(scheduleProvider).schedule;
    final isDosen = user?.isDosen ?? false;

    final scheduleName = isDosen ? schedule?.lecturerName.trim() ?? '' : '';
    final scheduleNidn = isDosen ? schedule?.nidn.trim() ?? '' : '';

    final name = scheduleName.isNotEmpty
        ? scheduleName
        : (user?.displayName ?? 'Pegawai Indonusa');
    final id = scheduleNidn.isNotEmpty
        ? scheduleNidn
        : (user?.displayId ?? '-');
    final idLabel = scheduleNidn.isNotEmpty
        ? 'NIDN'
        : (user?.displayIdLabel ?? 'NIP');
    final role = isDosen ? 'Dosen Pengajar' : (user?.position ?? 'Pegawai');

    final rows = <MapEntry<String, String>>[
      MapEntry('Nama Lengkap', name),
      MapEntry(idLabel, id),
      MapEntry('Jabatan', user?.position ?? '-'),
      MapEntry('Unit Kerja', user?.department ?? '-'),
      MapEntry('Email', user?.email ?? '-'),
      MapEntry('Peran', role),
      MapEntry(
        'Status Akun',
        user?.isActive == false ? 'Tidak Aktif' : 'Aktif',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppHeader(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Data Diri & Biodata',
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 21,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          user?.avatarInitial ?? 'PG',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$idLabel: $id',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: rows.asMap().entries.map((entry) {
                    final isLast = entry.key == rows.length - 1;
                    final row = entry.value;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 110,
                                child: Text(
                                  row.key,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  row.value,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isLast)
                          const Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: AppColors.divider,
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                'Data kepegawaian bersumber dari SSO, SIMPEG, dan SIAKAD. '
                'Untuk perubahan data utama, silakan hubungi Admin SIMPEG.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textHint,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}
