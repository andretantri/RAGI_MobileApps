import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/mobile_feature_config.dart';
import '../../core/models/mobile_feature_model.dart';
import '../../core/models/mobile_feature_submission.dart';
import '../../core/models/sippm_lookup_model.dart';
import '../../core/providers/mobile_feature_provider.dart';
import '../../core/services/api_exception.dart';
import '../../core/services/mobile_feature_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../common/app_header.dart';

/// Form aksi tulis untuk fitur mobile yang memiliki endpoint POST.
class MobileFeatureFormScreen extends ConsumerStatefulWidget {
  final String featureCode;

  const MobileFeatureFormScreen({super.key, required this.featureCode});

  @override
  ConsumerState<MobileFeatureFormScreen> createState() =>
      _MobileFeatureFormScreenState();
}

class _MobileFeatureFormScreenState
    extends ConsumerState<MobileFeatureFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  int? _skemaId;
  int? _periodeId;
  String? _jenisPengajuan = 'reimbursement';
  String? _prioritas = 'sedang';
  PlatformFile? _file;
  MobileFeatureItem? _result;
  bool _submitting = false;

  MobileFeature? get _feature => AppMobileFeatures.findByCode(widget.featureCode);

  @override
  void initState() {
    super.initState();
    final type = _feature?.formType ?? MobileFeatureFormType.none;
    final defaults = switch (type) {
      MobileFeatureFormType.proposalSippm => {
          'judul': '',
          'abstrak': '',
          'rumpun_ilmu': '',
          'target_tkt': '',
          'anggaran_diajukan': '',
        },
      MobileFeatureFormType.pengajuanSikeu => {
          'judul_pengajuan': '',
          'deskripsi': '',
          'nominal_diajukan': '',
          'nama_bank_penerima': '',
          'nomor_rekening_penerima': '',
          'nama_rekening_penerima': '',
          'unit_kas_id': '',
        },
      MobileFeatureFormType.tiketSinapra => {
          'judul': '',
          'deskripsi_kerusakan': '',
          'ruangan_id': '',
          'aset_id': '',
        },
      MobileFeatureFormType.referralSpmb ||
      MobileFeatureFormType.none =>
        <String, String>{},
    };
    for (final entry in defaults.entries) {
      _controllers[entry.key] = TextEditingController(text: entry.value);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controller(String key) =>
      _controllers.putIfAbsent(key, () => TextEditingController());

  Future<void> _pickFile({required bool pdfOnly}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: pdfOnly ? ['pdf'] : ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.isEmpty) return;
    setState(() => _file = result.files.first);
  }

  Future<void> _submit() async {
    final feature = _feature;
    if (feature == null || !feature.isSubmittable) return;
    if (!_formKey.currentState!.validate()) return;

    final type = feature.formType;
    if (type == MobileFeatureFormType.proposalSippm) {
      if (_skemaId == null || _periodeId == null) {
        _showMessage('Pilih skema dan periode hibah terlebih dahulu.');
        return;
      }
      if (_file == null) {
        _showMessage('Berkas proposal PDF wajib diunggah.');
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      final values = <String, dynamic>{
        for (final entry in _controllers.entries) entry.key: entry.value.text,
        'skema_id': _skemaId,
        'periode_id': _periodeId,
        'jenis_pengajuan': _jenisPengajuan,
        'prioritas': _prioritas,
      };
      final submission = MobileFeatureSubmission(type: type, values: values);
      final created = await MobileFeatureService.submit(
        feature,
        submission,
        file: _file?.xFile,
      );

      ref.invalidate(mobileFeatureItemsProvider(feature.code));
      if (!mounted) return;
      setState(() => _result = created);
      _showMessage(
        created == null
            ? '${feature.title} berhasil dikirim.'
            : '${created.title.isEmpty ? feature.title : created.title} berhasil dikirim.',
      );
      _formKey.currentState!.reset();
      for (final controller in _controllers.values) {
        controller.clear();
      }
    } on ApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Periksa koneksi lalu coba lagi.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _field(
    String key,
    String label, {
    bool required = false,
    bool numbersOnly = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _controller(key),
        maxLines: maxLines,
        keyboardType: numbersOnly ? TextInputType.number : TextInputType.text,
        inputFormatters: numbersOnly
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        validator: (value) {
          if (!required) return null;
          if (value == null || value.trim().isEmpty) {
            return '$label wajib diisi.';
          }
          return null;
        },
      ),
    );
  }

  Widget _attachmentCard({required bool pdfOnly}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_file_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _file == null
                  ? (pdfOnly
                      ? 'Berkas proposal PDF *'
                      : 'Lampiran opsional (PDF/JPG/PNG)')
                  : _file!.name,
              style: AppTextStyles.caption.copyWith(
                color: _file == null
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _pickFile(pdfOnly: pdfOnly),
            child: const Text('Pilih'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feature = _feature;
    final color = feature?.color ?? AppColors.primary;
    final icon = feature?.icon ?? Icons.edit_document;

    if (feature == null || !feature.isSubmittable) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Fitur ini tidak tersedia.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ),
      );
    }

    final lookupsAsync = feature.formType == MobileFeatureFormType.proposalSippm
        ? ref.watch(sippmLookupsProvider)
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
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
                              context.go(
                                '/features/${feature.code}',
                              );
                            }
                          },
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature.submitLabel,
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
                            feature.description,
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
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (feature.formType ==
                          MobileFeatureFormType.proposalSippm) ...[
                        _field('judul', 'Judul proposal', required: true),
                        _field('abstrak', 'Abstrak', maxLines: 4),
                        _field('rumpun_ilmu', 'Rumpun ilmu', required: true),
                        _lookupDropdown(
                          label: 'Skema hibah',
                          value: _skemaId,
                          items: lookupsAsync?.valueOrNull?.skema ?? [],
                          onChanged: (value) =>
                              setState(() => _skemaId = value),
                        ),
                        _lookupDropdown(
                          label: 'Periode hibah',
                          value: _periodeId,
                          items: lookupsAsync?.valueOrNull?.periode ?? [],
                          onChanged: (value) =>
                              setState(() => _periodeId = value),
                        ),
                        if (lookupsAsync?.hasError ?? false)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Master skema/periode belum dapat dimuat.',
                                  style: AppTextStyles.caption
                                      .copyWith(color: AppColors.error),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      ref.invalidate(sippmLookupsProvider),
                                  icon: const Icon(Icons.refresh_rounded,
                                      size: 16),
                                  label: const Text('Muat Ulang'),
                                ),
                              ],
                            ),
                          ),
                        _field('target_tkt', 'Target TKT (1-9)', numbersOnly: true),
                        _field(
                          'anggaran_diajukan',
                          'Anggaran diajukan (Rp)',
                          required: true,
                          numbersOnly: true,
                        ),
                        _attachmentCard(pdfOnly: true),
                      ],
                      if (feature.formType ==
                          MobileFeatureFormType.pengajuanSikeu) ...[
                        _field('judul_pengajuan', 'Judul pengajuan',
                            required: true),
                        _field('deskripsi', 'Deskripsi', maxLines: 3),
                        _dropdown(
                          label: 'Jenis pengajuan',
                          value: _jenisPengajuan,
                          items: const [
                            'reimbursement',
                            'operasional',
                            'kegiatan',
                            'sarpras',
                            'lainnya',
                          ],
                          onChanged: (value) =>
                              setState(() => _jenisPengajuan = value),
                        ),
                        _field(
                          'nominal_diajukan',
                          'Nominal diajukan (Rp)',
                          required: true,
                          numbersOnly: true,
                        ),
                        _field('nama_bank_penerima', 'Bank penerima'),
                        _field('nomor_rekening_penerima', 'Nomor rekening'),
                        _field('nama_rekening_penerima', 'Nama pemegang rekening'),
                        _field('unit_kas_id', 'Unit kas ID', numbersOnly: true),
                        _attachmentCard(pdfOnly: false),
                      ],
                      if (feature.formType ==
                          MobileFeatureFormType.tiketSinapra) ...[
                        _field('judul', 'Judul kerusakan', required: true),
                        _field('deskripsi_kerusakan', 'Deskripsi kerusakan',
                            required: true, maxLines: 4),
                        _dropdown(
                          label: 'Prioritas',
                          value: _prioritas,
                          items: const ['rendah', 'sedang', 'tinggi', 'darurat'],
                          onChanged: (value) =>
                              setState(() => _prioritas = value),
                        ),
                        _field('ruangan_id', 'Ruangan ID', numbersOnly: true),
                        _field('aset_id', 'Aset ID', numbersOnly: true),
                        _attachmentCard(pdfOnly: false),
                      ],
                      if (feature.formType ==
                          MobileFeatureFormType.referralSpmb)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Backend akan membuat atau memperbarui kode, tautan, dan QR referral akun Anda. Tidak ada data yang diisi manual.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      if (_result != null) ...[
                        const SizedBox(height: 8),
                        _ResultCard(item: _result!),
                      ],
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: _submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          _submitting ? 'Mengirim...' : feature.submitLabel,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: color,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _lookupDropdown({
    required String label,
    required int? value,
    required List<SippmLookup> items,
    required ValueChanged<int?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: '$label *',
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: items.map((lookup) {
          return DropdownMenuItem<int>(
            value: lookup.id,
            child: Text(
              lookup.subtitle.isEmpty
                  ? lookup.name
                  : '${lookup.name} (${lookup.subtitle})',
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final MobileFeatureItem item;

  const _ResultCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title.isNotEmpty ? item.title : 'Data berhasil dibuat',
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w700),
          ),
          if (item.referralCode.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Kode: ${item.referralCode}',
                style: AppTextStyles.caption),
          ],
          if (item.shareUrl.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Tautan: ${item.shareUrl}',
                style: AppTextStyles.caption),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: item.shareUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tautan referral disalin.')),
                );
              },
              icon: const Icon(Icons.copy_all_rounded, size: 16),
              label: const Text('Salin Tautan'),
            ),
          ],
        ],
      ),
    );
  }
}
