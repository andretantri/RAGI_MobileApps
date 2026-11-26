import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/mobile_feature_config.dart';
import '../../core/models/mobile_feature_model.dart';
import '../../core/models/mobile_staff_models.dart';
import '../../core/providers/mobile_feature_provider.dart';
import '../../core/services/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../common/app_header.dart';

/// Daftar data generik untuk satu fitur mobile (payroll, pengajuan, referral,
/// e-file, proposal, bahan ajar, dan sejenisnya).
class MobileFeatureListScreen extends ConsumerWidget {
  final String featureCode;

  const MobileFeatureListScreen({super.key, required this.featureCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feature = AppMobileFeatures.findByCode(featureCode);
    final itemsAsync = ref.watch(mobileFeatureItemsProvider(featureCode));

    final title = feature?.title ?? 'Layanan Mobile';
    final subtitle = feature?.description ?? 'Fitur ini belum tersedia.';
    final color = feature?.color ?? AppColors.primary;
    final icon = feature?.icon ?? Icons.article_outlined;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(mobileFeatureItemsProvider(featureCode)),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: AppHeader(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
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
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
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
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(icon, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            subtitle,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (feature == null || !feature.hasEndpoint)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: _InfoCard(
                    color: color,
                    title: 'Menunggu integrasi backend',
                    message:
                        'Fitur ini sudah disiapkan di mobile. Data akan muncul setelah endpoint RAG tersedia.',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                sliver: itemsAsync.when(
                  loading: () => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (error, _) => SliverToBoxAdapter(
                    child: _InfoCard(
                      color: AppColors.error,
                      title: 'Data belum dapat dimuat',
                      message: error is ApiException
                          ? error.message
                          : 'Periksa koneksi lalu coba lagi.',
                      actionLabel: 'Coba Lagi',
                      onAction: () => ref.invalidate(
                        mobileFeatureItemsProvider(featureCode),
                      ),
                    ),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return SliverToBoxAdapter(
                        child: _InfoCard(
                          color: color,
                          title: 'Belum ada data',
                          message:
                              'Data $title akan tampil di sini setelah tersedia di server RAG.',
                          actionLabel: 'Muat Ulang',
                          onAction: () => ref.invalidate(
                            mobileFeatureItemsProvider(featureCode),
                          ),
                        ),
                      );
                    }

                    // Backend mengirim statistik referral pada kartu pertama.
                    final rawStats =
                        featureCode == 'referral-spmb' && items.isNotEmpty
                        ? items.first.raw['stats']
                        : null;
                    final stats = rawStats is Map
                        ? MobileStaffReferralStats.fromJson(rawStats)
                        : null;
                    final shouldGroupByStatus =
                        feature.isSubmittable &&
                        items.any((item) => item.hasStatus);
                    final statusGroups = shouldGroupByStatus
                        ? _groupItemsByStatus(items)
                        : const <_StatusGroup>[];

                    return SliverMainAxisGroup(
                      slivers: [
                        if (stats != null)
                          SliverToBoxAdapter(
                            child: _ReferralStatsCard(stats: stats),
                          ),
                        if (shouldGroupByStatus)
                          SliverList.separated(
                            itemCount: statusGroups.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, groupIndex) {
                              final group = statusGroups[groupIndex];
                              return Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: Material(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      dividerColor: Colors.transparent,
                                    ),
                                    child: ExpansionTile(
                                      initiallyExpanded: group.isPending,
                                      tilePadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      childrenPadding:
                                          const EdgeInsets.fromLTRB(
                                            12,
                                            0,
                                            12,
                                            12,
                                          ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              group.label,
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 9,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: group.color.withValues(
                                                alpha: 0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '${group.items.length}',
                                              style: TextStyle(
                                                color: group.color,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      children: [
                                        for (
                                          var index = 0;
                                          index < group.items.length;
                                          index++
                                        ) ...[
                                          if (index > 0)
                                            const SizedBox(height: 8),
                                          _FeatureItemCard(
                                            item: group.items[index],
                                            feature: feature,
                                            amountColor: color,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        else
                          SliverList.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) => _FeatureItemCard(
                              item: items[index],
                              feature: feature,
                              amountColor: color,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
      floatingActionButton: _buildActions(context, feature, itemsAsync),
    );
  }

  Widget? _buildActions(
    BuildContext context,
    MobileFeature? feature,
    AsyncValue<List<MobileFeatureItem>> itemsAsync,
  ) {
    final actions = <Widget>[];

    if (featureCode == 'referral-spmb' &&
        (itemsAsync.valueOrNull?.isNotEmpty ?? false)) {
      actions.add(
        FloatingActionButton(
          heroTag: 'copy-referral',
          tooltip: 'Salin Kode',
          onPressed: () {
            final code = itemsAsync.valueOrNull!.first.referralCode;
            if (code.isEmpty) return;
            Clipboard.setData(ClipboardData(text: code));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Kode referral disalin: $code')),
            );
          },
          child: const Icon(Icons.copy_all_rounded),
        ),
      );
    }

    if (feature != null &&
        feature.isSubmittable &&
        featureCode != 'referral-spmb') {
      actions.add(
        FloatingActionButton.extended(
          heroTag: 'submit-$featureCode',
          onPressed: () => feature.usesDedicatedForm
              ? context.push('/mobile-staff/form/$featureCode')
              : context.push('/features/$featureCode/form'),
          icon: const Icon(Icons.add_rounded),
          label: Text(feature.submitLabel),
        ),
      );
    }

    if (actions.isEmpty) return null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final action in actions) ...[action, const SizedBox(height: 10)],
      ],
    );
  }
}

List<_StatusGroup> _groupItemsByStatus(List<MobileFeatureItem> items) {
  const statuses = <String, (String, Color)>{
    'pending': ('Menunggu', AppColors.warning),
    'draft': ('Draft', AppColors.textSecondary),
    'approved': ('Disetujui', AppColors.success),
    'rejected': ('Ditolak', AppColors.error),
    'other': ('Status lainnya', AppColors.textHint),
  };
  final groups = <String, List<MobileFeatureItem>>{};

  for (final item in items) {
    final normalized = item.status.trim().toLowerCase().replaceAll('_', ' ');
    final key = switch (normalized) {
      'pending' ||
      'menunggu' ||
      'menunggu persetujuan' ||
      'diajukan' => 'pending',
      'draft' || 'konsep' => 'draft',
      'disetujui' || 'approved' || 'setuju' => 'approved',
      'ditolak' || 'rejected' => 'rejected',
      _ => 'other',
    };
    groups.putIfAbsent(key, () => <MobileFeatureItem>[]).add(item);
  }

  return [
    for (final key in statuses.keys)
      if (groups.containsKey(key))
        _StatusGroup(
          label: statuses[key]!.$1,
          color: statuses[key]!.$2,
          items: groups[key]!,
          isPending: key == 'pending',
        ),
  ];
}

class _StatusGroup {
  final String label;
  final Color color;
  final List<MobileFeatureItem> items;
  final bool isPending;

  const _StatusGroup({
    required this.label,
    required this.color,
    required this.items,
    required this.isPending,
  });
}

class _FeatureItemCard extends StatelessWidget {
  final MobileFeatureItem item;
  final MobileFeature feature;
  final Color amountColor;

  const _FeatureItemCard({
    required this.item,
    required this.feature,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item.status);
    return InkWell(
      onTap: feature.hasDetail
          ? () => context.push(
              '/mobile-staff/detail/${feature.code}/${item.id}',
              extra: item,
            )
          : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title.isNotEmpty ? item.title : 'Data ${feature.title}',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (item.subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (item.hasAmount || item.hasStatus) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (item.hasAmount)
                    _ItemBadge(label: item.amount, color: amountColor),
                  if (item.hasStatus)
                    _ItemBadge(label: item.status, color: statusColor),
                ],
              ),
            ],
            if (item.hasDate) ...[
              const SizedBox(height: 10),
              Text(
                item.date,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textHint,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ItemBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _ItemBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _statusColor(String status) {
  final normalized = status.trim().toLowerCase();
  if (const {
    'pending',
    'menunggu',
    'menunggu_persetujuan',
    'diajukan',
  }.contains(normalized)) {
    return AppColors.warning;
  }
  if (const {'disetujui', 'approved', 'setuju'}.contains(normalized)) {
    return AppColors.success;
  }
  if (const {'ditolak', 'rejected'}.contains(normalized)) {
    return AppColors.error;
  }
  if (const {'draft', 'konsep'}.contains(normalized)) {
    return AppColors.textSecondary;
  }
  return AppColors.textHint;
}

class _ReferralStatsCard extends StatelessWidget {
  final MobileStaffReferralStats stats;

  const _ReferralStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ringkasan Referral',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final row in stats.rows)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${row.$1}: ${row.$2}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Color color;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _InfoCard({
    required this.color,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 40,
            color: color.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
