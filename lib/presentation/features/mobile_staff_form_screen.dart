import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/mobile_feature_config.dart';
import '../../core/models/mobile_feature_model.dart';
import '../../core/models/mobile_feature_submission.dart';
import '../../core/models/mobile_staff_models.dart';
import '../../core/providers/mobile_feature_provider.dart';
import '../../core/providers/mobile_staff_provider.dart';
import '../../core/services/api_exception.dart';
import '../../core/services/mobile_feature_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../common/app_header.dart';

/// Pemetaan kunci master (semantic) ke nama field payload backend.
const _masterPayloadKeys = <String, String>{
  'jenis_cuti': 'master_jenis_cuti_id',
  'jenis_izin': 'master_jenis_izin_id',
  'kategori_kegiatan': 'kategori_kegiatan_id',
  'jenis_transportasi': 'jenis_transportasi_id',
  'kategori_sk': 'kategori_sk_id',
};

class _FieldSpec {
  final String key;
  final String label;
  final bool required;
  final bool numbersOnly;
  final bool isDate;
  final bool isTime;
  final bool isCurrency;
  final int maxLines;
  final int? minLength;
  final String? masterKey;
  final List<String>? options;

  const _FieldSpec(
    this.key,
    this.label, {
    this.required = false,
    this.numbersOnly = false,
    this.isDate = false,
    this.isTime = false,
    this.isCurrency = false,
    this.maxLines = 1,
    this.minLength,
    this.masterKey,
    this.options,
  });
}

/// Form self-service SIMPEG/ARSIP yang memakai endpoint v1 baru.
///
/// Semua ID master diambil dari API master SIMPEG, bukan angka hardcode.
class MobileStaffFormScreen extends ConsumerStatefulWidget {
  final String featureCode;

  const MobileStaffFormScreen({super.key, required this.featureCode});

  @override
  ConsumerState<MobileStaffFormScreen> createState() =>
      _MobileStaffFormScreenState();
}

class _MobileStaffFormScreenState extends ConsumerState<MobileStaffFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _masterIds = <String, int>{};
  PlatformFile? _file;
  MobileFeatureItem? _result;
  bool _submitting = false;

  MobileFeature? get _feature =>
      AppMobileFeatures.findByCode(widget.featureCode);

  static const _cutiFields = <_FieldSpec>[
    _FieldSpec(
      'master_jenis_cuti_id',
      'Jenis cuti',
      required: true,
      masterKey: 'jenis_cuti',
    ),
    _FieldSpec('tanggal_mulai', 'Tanggal mulai', required: true, isDate: true),
    _FieldSpec(
      'tanggal_selesai',
      'Tanggal selesai',
      required: true,
      isDate: true,
    ),
    _FieldSpec('jumlah_hari', 'Jumlah hari', numbersOnly: true),
    _FieldSpec(
      'alasan',
      'Alasan cuti',
      required: true,
      maxLines: 3,
      minLength: 5,
    ),
  ];

  static const _izinFields = <_FieldSpec>[
    _FieldSpec(
      'master_jenis_izin_id',
      'Jenis izin jam kerja',
      required: true,
      masterKey: 'jenis_izin',
    ),
    _FieldSpec('tanggal', 'Tanggal izin', required: true, isDate: true),
    _FieldSpec('jam_mulai', 'Jam mulai', required: true, isTime: true),
    _FieldSpec('jam_selesai', 'Jam selesai', required: true, isTime: true),
    _FieldSpec(
      'alasan',
      'Alasan izin',
      required: true,
      maxLines: 3,
      minLength: 5,
    ),
  ];

  static const _suratTugasFields = <_FieldSpec>[
    _FieldSpec(
      'kategori_kegiatan_id',
      'Kategori kegiatan',
      required: true,
      masterKey: 'kategori_kegiatan',
    ),
    _FieldSpec(
      'jenis_transportasi_id',
      'Jenis transportasi',
      required: true,
      masterKey: 'jenis_transportasi',
    ),
    _FieldSpec('nama_kegiatan', 'Nama kegiatan', required: true),
    _FieldSpec('jam_pelaksanaan', 'Jam pelaksanaan'),
    _FieldSpec('penyelenggara', 'Penyelenggara'),
    _FieldSpec('tempat_berangkat', 'Tempat berangkat', required: true),
    _FieldSpec('lokasi_tujuan', 'Lokasi tujuan', required: true),
    _FieldSpec(
      'tanggal_berangkat',
      'Tanggal berangkat',
      required: true,
      isDate: true,
    ),
    _FieldSpec(
      'tanggal_kembali',
      'Tanggal kembali',
      required: true,
      isDate: true,
    ),
    _FieldSpec(
      'tanggal_mulai',
      'Tanggal mulai kegiatan',
      required: true,
      isDate: true,
    ),
    _FieldSpec(
      'tanggal_selesai',
      'Tanggal selesai kegiatan',
      required: true,
      isDate: true,
    ),
    _FieldSpec(
      'maksud_tujuan',
      'Maksud dan tujuan',
      required: true,
      maxLines: 3,
    ),
    _FieldSpec('estimasi_biaya', 'Estimasi biaya (Rp)', isCurrency: true),
    _FieldSpec('keterangan', 'Keterangan', maxLines: 2),
  ];

  static const _skFields = <_FieldSpec>[
    _FieldSpec(
      'kategori_sk_id',
      'Kategori SK',
      required: true,
      masterKey: 'kategori_sk',
    ),
    _FieldSpec('nomor_sk', 'Nomor SK', required: true),
    _FieldSpec('judul_sk', 'Judul SK', required: true),
    _FieldSpec('tanggal_sk', 'Tanggal SK', required: true, isDate: true),
    _FieldSpec('tmt_sk', 'TMT SK', required: true, isDate: true),
    _FieldSpec('tmt_selesai', 'TMT selesai', isDate: true),
    _FieldSpec('pejabat_penetap', 'Pejabat penetap', required: true),
    _FieldSpec('keterangan', 'Keterangan', maxLines: 2),
  ];

  static const _eFileFields = <_FieldSpec>[
    _FieldSpec('nama_dokumen', 'Nama dokumen', required: true),
    _FieldSpec(
      'jenis_dokumen',
      'Jenis dokumen',
      required: true,
      options: mobileEfileJenisDokumen,
    ),
  ];

  List<_FieldSpec> get _fields => switch (_feature?.formType) {
    MobileFeatureFormType.cutiSimpeg => _cutiFields,
    MobileFeatureFormType.izinKerjaSimpeg => _izinFields,
    MobileFeatureFormType.suratTugasSimpeg => _suratTugasFields,
    MobileFeatureFormType.skPegawaiSimpeg => _skFields,
    MobileFeatureFormType.eFileArsip => _eFileFields,
    _ => const <_FieldSpec>[],
  };

  List<String> get _fileExtensions => switch (_feature?.formType) {
    MobileFeatureFormType.suratTugasSimpeg ||
    MobileFeatureFormType.skPegawaiSimpeg => const ['pdf'],
    _ => const ['pdf', 'jpg', 'jpeg', 'png'],
  };

  bool get _fileRequired => switch (_feature?.formType) {
    MobileFeatureFormType.skPegawaiSimpeg ||
    MobileFeatureFormType.eFileArsip => true,
    _ => false,
  };

  String get _fileHint => switch (_feature?.formType) {
    MobileFeatureFormType.cutiSimpeg => 'Berkas pendukung (PDF/JPG/PNG)',
    MobileFeatureFormType.izinKerjaSimpeg => 'Bukti izin (PDF/JPG/PNG)',
    MobileFeatureFormType.suratTugasSimpeg => 'Surat tugas PDF (opsional)',
    MobileFeatureFormType.skPegawaiSimpeg => 'Berkas SK PDF *',
    MobileFeatureFormType.eFileArsip => 'Berkas dokumen (PDF/JPG/PNG) *',
    _ => 'Lampiran',
  };

  TextEditingController _controller(String key) =>
      _controllers.putIfAbsent(key, () => TextEditingController());

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _fileExtensions,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() => _file = result.files.first);
  }

  Future<void> _pickDate(String key) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    _controller(key).text = DateFormat('yyyy-MM-dd').format(picked);
    if (key == 'tanggal_mulai') _applyFixedCutiDuration();
    setState(() {});
  }

  Future<void> _pickTime(String key) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null) return;
    _controller(key).text =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {});
  }

  /// Master jenis cuti "ditetapkan" mengisi tanggal selesai & jumlah hari
  /// otomatis, mengikuti perilaku CutiScreen yang sudah ada.
  void _applyFixedCutiDuration() {
    final feature = _feature;
    if (feature?.formType != MobileFeatureFormType.cutiSimpeg) return;
    final lookups = ref.read(mobileStaffMasterLookupsProvider).valueOrNull;
    final masterId = _masterIds['jenis_cuti'];
    final matches =
        lookups?.jenisCuti.where((item) => item.id == masterId) ??
        const <MobileStaffMasterOption>[];
    final option = matches.isEmpty ? null : matches.first;
    final days = option?.fixedDurationDays;
    if (option == null || !option.isFixedDuration || days == null || days < 1) {
      return;
    }

    final startText = _controller('tanggal_mulai').text.trim();
    final start = DateTime.tryParse(startText);
    if (start == null) return;

    _controller('tanggal_selesai').text = DateFormat(
      'yyyy-MM-dd',
    ).format(start.add(Duration(days: days - 1)));
    _controller('jumlah_hari').text = days.toString();
  }

  bool get _fixedCutiSelected {
    if (_feature?.formType != MobileFeatureFormType.cutiSimpeg) return false;
    final masterId = _masterIds['jenis_cuti'];
    final matches =
        ref
            .watch(mobileStaffMasterLookupsProvider)
            .valueOrNull
            ?.jenisCuti
            .where((item) => item.id == masterId) ??
        const <MobileStaffMasterOption>[];
    final option = matches.isEmpty ? null : matches.first;
    return option != null &&
        option.isFixedDuration &&
        option.fixedDurationDays != null;
  }

  Future<void> _submit() async {
    final feature = _feature;
    if (feature == null || !feature.isSubmittable) return;
    if (!_formKey.currentState!.validate()) return;

    for (final key in feature.masterKeys) {
      if (_masterIds[key] == null) {
        _showMessage('Pilih ${_masterLabel(key)} terlebih dahulu.');
        return;
      }
    }
    if (_fileRequired && _file == null) {
      _showMessage('Berkas wajib diunggah.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final values = <String, dynamic>{
        for (final entry in _controllers.entries)
          entry.key: entry.value.text.trim(),
        for (final entry in _masterIds.entries)
          _masterPayloadKeys[entry.key] ?? entry.key: entry.value,
      };
      final submission = MobileFeatureSubmission(
        type: feature.formType,
        values: values,
      );
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
    } on ApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Periksa koneksi lalu coba lagi.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _masterLabel(String key) {
    final lookups = ref.read(mobileStaffMasterLookupsProvider).valueOrNull;
    return lookups?.labelFor(key) ?? key;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _field(_FieldSpec spec, MobileStaffLookups? lookups) {
    if (spec.masterKey != null) {
      final items =
          lookups?.optionsFor(spec.masterKey!) ??
          const <MobileStaffMasterOption>[];
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<int>(
          initialValue: _masterIds[spec.masterKey],
          decoration: InputDecoration(
            labelText: spec.required ? '${spec.label} *' : spec.label,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<int>(
                  value: item.id,
                  child: Text(
                    item.subtitle.isEmpty
                        ? item.name
                        : '${item.name} (${item.subtitle})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: items.isEmpty
              ? null
              : (value) {
                  if (value == null) return;
                  setState(() => _masterIds[spec.masterKey!] = value);
                  if (spec.masterKey == 'jenis_cuti') {
                    _applyFixedCutiDuration();
                  }
                },
        ),
      );
    }

    if (spec.options != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          initialValue: spec.options!.contains(_controller(spec.key).text)
              ? _controller(spec.key).text
              : null,
          decoration: InputDecoration(
            labelText: spec.required ? '${spec.label} *' : spec.label,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          items: spec.options!
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (value) =>
              setState(() => _controller(spec.key).text = value ?? ''),
        ),
      );
    }

    final readOnly = spec.isDate || spec.isTime;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _controller(spec.key),
        maxLines: spec.maxLines,
        readOnly: readOnly,
        enabled:
            !(spec.key == 'tanggal_selesai' || spec.key == 'jumlah_hari') ||
            !_fixedCutiSelected,
        keyboardType: spec.numbersOnly || spec.isCurrency
            ? TextInputType.number
            : TextInputType.text,
        onTap: spec.isDate
            ? () => _pickDate(spec.key)
            : (spec.isTime ? () => _pickTime(spec.key) : null),
        decoration: InputDecoration(
          labelText: spec.required ? '${spec.label} *' : spec.label,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: readOnly
              ? Icon(
                  spec.isDate ? Icons.calendar_today : Icons.access_time,
                  size: 18,
                )
              : null,
        ),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (spec.required && text.isEmpty) {
            return '${spec.label} wajib diisi.';
          }
          if (spec.minLength != null &&
              text.isNotEmpty &&
              text.length < spec.minLength!) {
            return '${spec.label} minimal ${spec.minLength} karakter.';
          }
          return null;
        },
      ),
    );
  }

  Widget _attachmentCard() {
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
              _file?.name ?? _fileHint,
              style: AppTextStyles.caption.copyWith(
                color: _file == null
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          TextButton(onPressed: _pickFile, child: const Text('Pilih')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feature = _feature;
    final color = feature?.color ?? AppColors.primary;
    final icon = feature?.icon ?? Icons.edit_document;

    if (feature == null || !feature.usesDedicatedForm) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Form fitur ini tidak tersedia.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ),
      );
    }

    final lookupsAsync = feature.masterKeys.isEmpty
        ? null
        : ref.watch(mobileStaffMasterLookupsProvider);

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
                              context.go('/features/${feature.code}');
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
                      if (lookupsAsync?.hasError == true) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Master SIMPEG belum dapat dimuat.',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => ref.invalidate(
                                  mobileStaffMasterLookupsProvider,
                                ),
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 16,
                                ),
                                label: const Text('Muat Ulang'),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (lookupsAsync?.valueOrNull?.errors.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Sebagian master gagal dimuat: ${lookupsAsync!.valueOrNull!.errors.values.join(', ')}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      for (final spec in _fields)
                        _field(spec, lookupsAsync?.valueOrNull),
                      _attachmentCard(),
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
      child: Text(
        item.title.isNotEmpty ? item.title : 'Data berhasil dibuat',
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
