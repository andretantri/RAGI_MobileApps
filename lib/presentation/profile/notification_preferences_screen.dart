import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/local_notification_service.dart';
import '../common/app_header.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  // 1. Pengingat Jadwal Mengajar
  bool _teachingReminderEnabled = true;
  int _teachingReminderMinutes = 15; // 15, 30, atau 60 menit

  // 2. Pengingat Presensi Kerja
  bool _attendanceMorningEnabled = true;
  bool _attendanceEveningEnabled = true;

  // 3. Pengingat Tugas & Deadline
  bool _deadlineReminderEnabled = true;
  int _deadlineReminderHours = 3; // 3 jam atau 24 jam (H-1)

  // 4. Pengumuman Kampus
  bool _announcementsEnabled = true;

  // 5. Nada Dering & Getar
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    LocalNotificationService.instance.init();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _teachingReminderEnabled =
            prefs.getBool('notif_teaching_enabled') ?? true;
        _teachingReminderMinutes =
            prefs.getInt('notif_teaching_minutes') ?? 15;
        _attendanceMorningEnabled =
            prefs.getBool('notif_attendance_morning') ?? true;
        _attendanceEveningEnabled =
            prefs.getBool('notif_attendance_evening') ?? true;
        _deadlineReminderEnabled =
            prefs.getBool('notif_deadline_enabled') ?? true;
        _deadlineReminderHours = prefs.getInt('notif_deadline_hours') ?? 3;
        _announcementsEnabled = prefs.getBool('notif_announcements') ?? true;
        _soundEnabled = prefs.getBool('notif_sound') ?? true;
        _vibrationEnabled = prefs.getBool('notif_vibration') ?? true;
      });
    }
  }

  Future<void> _savePreference(String key, dynamic val) async {
    final prefs = await SharedPreferences.getInstance();
    if (val is bool) {
      await prefs.setBool(key, val);
    } else if (val is int) {
      await prefs.setInt(key, val);
    }
    if (key.startsWith('notif_attendance') ||
        key == 'notif_sound' ||
        key == 'notif_vibration') {
      await LocalNotificationService.instance.syncAttendanceReminders();
    }
  }

  void _showCustomMinutesDialog() {
    final textController =
        TextEditingController(text: '$_teachingReminderMinutes');
    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.edit_calendar_rounded,
                  color: AppColors.primary, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Atur Menit Sendiri',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tentukan berapa menit sebelum jam perkuliahan pengingat harus berdering di HP Anda:',
                style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: textController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: 'Waktu Pengingat',
                  suffixText: 'Menit Sebelum',
                  hintText: 'Contoh: 20',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.timer_outlined,
                      color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pilihan Cepat:',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [5, 10, 20, 45, 90, 120].map((m) {
                  return InkWell(
                    onTap: () {
                      setDlgState(() {
                        textController.text = '$m';
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text('$m Menit',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final val = int.tryParse(textController.text.trim());
                if (val != null && val >= 1 && val <= 360) {
                  setState(() => _teachingReminderMinutes = val);
                  _savePreference('notif_teaching_minutes', val);
                  Navigator.pop(dlgCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.primaryDark,
                      content: Text(
                          'Waktu pengingat kuliah diatur ke $val menit sebelum kelas.'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomDeadlineDialog() {
    final textController =
        TextEditingController(text: '$_deadlineReminderHours');
    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.access_time_filled_rounded,
                  color: AppColors.primary, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Atur Jam Deadline Sendiri',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tentukan berapa jam sebelum batas waktu deadline tugas/nilai pengingat harus berdering:',
                style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: textController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: 'Waktu Pengingat Deadline',
                  suffixText: 'Jam Sebelum',
                  hintText: 'Contoh: 6',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.hourglass_bottom_rounded,
                      color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pilihan Cepat:',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  {'label': '1 Jam', 'val': 1},
                  {'label': '6 Jam', 'val': 6},
                  {'label': '12 Jam', 'val': 12},
                  {'label': 'H-1 (24 Jam)', 'val': 24},
                  {'label': 'H-2 (48 Jam)', 'val': 48},
                ].map((item) {
                  return InkWell(
                    onTap: () {
                      setDlgState(() {
                        textController.text = '${item['val']}';
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(item['label'] as String,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final val = int.tryParse(textController.text.trim());
                if (val != null && val >= 1 && val <= 168) {
                  setState(() => _deadlineReminderHours = val);
                  _savePreference('notif_deadline_hours', val);
                  Navigator.pop(dlgCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.primaryDark,
                      content: Text(
                          'Waktu pengingat deadline diatur ke $val jam sebelum tenggat.'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkSystemPermissions() async {
    final granted =
        await LocalNotificationService.instance.requestPermissions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
              granted ? AppColors.success : AppColors.primaryDark,
          content: Text(
            granted
                ? 'Izin notifikasi sistem perangkat aktif & diizinkan.'
                : 'Permintaan izin notifikasi telah diajukan ke sistem HP.',
          ),
        ),
      );
    }
  }

  Future<void> _triggerTestNotification() async {
    setState(() => _isSaving = true);

    // Minta izin ke OS jika belum ada
    await LocalNotificationService.instance.requestPermissions();

    // Satu kanal saja: notifikasi sistem. Tidak ada overlay ganda di dalam UI.
    await LocalNotificationService.instance.showNotification(
      id: 999,
      title: 'Pengingat Mengajar: Pemrograman Mobile',
      body:
          'Kelas dimulai dalam $_teachingReminderMinutes menit (08:00 WIB) di Lab Komputer 2 Gedung B.',
      channel: NotificationChannelType.teachingSchedule,
      payload: LocalNotificationService.routeForChannel(
        NotificationChannelType.teachingSchedule,
      ),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: const Row(
            children: [
              Icon(Icons.notifications_active_rounded,
                  color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                    'Simulasi notifikasi pengingat berhasil ditembakkan!'),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDosen = ref.watch(authProvider).user?.isDosen ?? true;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Konsisten dengan Gambar background.jpeg
            AppHeader(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Preferensi Notifikasi',
                          style: AppTextStyles.headlineMedium
                              .copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Text(
                      isDosen
                          ? 'Atur pengingat jadwal mengajar, presensi kerja, & batas tugas.'
                          : 'Atur pengingat presensi kerja & pengumuman resmi kampus.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kartu Info Arsitektur Push Notification
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.alarm_on_rounded,
                            color: AppColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pengingat Otomatis Berjalan Lokal',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pengingat jadwal dan deadline berjalan langsung di sistem Android & iOS tanpa pihak ketiga. Ponsel akan berdering / bergetar tepat waktu meskipun aplikasi sedang tertutup.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textPrimary,
                                  height: 1.35,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SEKSI 1: JADWAL MENGAJAR (Khusus Dosen Pengajar / RBAC)
                  if (isDosen) ...[
                    _buildSectionHeader('PENGINGAT JADWAL MENGAJAR'),
                    _buildCard(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _teachingReminderEnabled,
                        activeThumbColor: AppColors.primary,
                        title: const Text('Notifikasi Sebelum Kuliah',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: const Text(
                          'Peringatan otomatis sebelum jadwal kelas Anda dimulai.',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        onChanged: (val) {
                          setState(() => _teachingReminderEnabled = val);
                          _savePreference('notif_teaching_enabled', val);
                        },
                      ),
                      if (_teachingReminderEnabled) ...[
                        const Divider(height: 20),
                        const Text(
                          'Kirim Notifikasi Pengingat:',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildChoiceChip(
                              label: '15 Menit',
                              selected: _teachingReminderMinutes == 15,
                              onSelected: () {
                                setState(() => _teachingReminderMinutes = 15);
                                _savePreference('notif_teaching_minutes', 15);
                              },
                            ),
                            _buildChoiceChip(
                              label: '30 Menit',
                              selected: _teachingReminderMinutes == 30,
                              onSelected: () {
                                setState(() => _teachingReminderMinutes = 30);
                                _savePreference('notif_teaching_minutes', 30);
                              },
                            ),
                            _buildChoiceChip(
                              label: '1 Jam Sebelum',
                              selected: _teachingReminderMinutes == 60,
                              onSelected: () {
                                setState(() => _teachingReminderMinutes = 60);
                                _savePreference('notif_teaching_minutes', 60);
                              },
                            ),
                            _buildChoiceChip(
                              label: (_teachingReminderMinutes != 15 &&
                                      _teachingReminderMinutes != 30 &&
                                      _teachingReminderMinutes != 60)
                                  ? '$_teachingReminderMinutes Menit (Kustom) ✎'
                                  : '+ Atur Sendiri...',
                              selected: _teachingReminderMinutes != 15 &&
                                  _teachingReminderMinutes != 30 &&
                                  _teachingReminderMinutes != 60,
                              onSelected: _showCustomMinutesDialog,
                            ),
                          ],
                        ),
                      ],
                    ],
                    ),
                    const SizedBox(height: 18),
                  ],

                  // SEKSI 2: PRESENSI KERJA
                  _buildSectionHeader('PENGINGAT PRESENSI KERJA'),
                  _buildCard(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _attendanceMorningEnabled,
                        activeThumbColor: AppColors.primary,
                        title: const Text('Pengingat Clock In (Pagi)',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: const Text(
                          'Pukul 07:45 WIB (15 menit sebelum batas masuk)',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        onChanged: (val) {
                          setState(() => _attendanceMorningEnabled = val);
                          _savePreference('notif_attendance_morning', val);
                        },
                      ),
                      const Divider(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _attendanceEveningEnabled,
                        activeThumbColor: AppColors.primary,
                        title: const Text('Pengingat Clock Out (Sore)',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: const Text(
                          'Pukul 16:00 WIB (Saat jam kerja berakhir)',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        onChanged: (val) {
                          setState(() => _attendanceEveningEnabled = val);
                          _savePreference('notif_attendance_evening', val);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // SEKSI 3: TUGAS & DEADLINE (Khusus Dosen Pengajar / RBAC)
                  if (isDosen) ...[
                    _buildSectionHeader('PENGINGAT TUGAS & DEADLINE'),
                    _buildCard(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _deadlineReminderEnabled,
                        activeThumbColor: AppColors.primary,
                        title: const Text('Deadline Nilai & Tugas',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: const Text(
                          'Peringatan sebelum batas waktu upload nilai/tugas berakhir.',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        onChanged: (val) {
                          setState(() => _deadlineReminderEnabled = val);
                          _savePreference('notif_deadline_enabled', val);
                        },
                      ),
                      if (_deadlineReminderEnabled) ...[
                        const Divider(height: 20),
                        const Text(
                          'Waktu Pengingat Deadline:',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildChoiceChip(
                              label: '3 Jam Sebelum',
                              selected: _deadlineReminderHours == 3,
                              onSelected: () {
                                setState(() => _deadlineReminderHours = 3);
                                _savePreference('notif_deadline_hours', 3);
                              },
                            ),
                            _buildChoiceChip(
                              label: 'H-1 (24 Jam)',
                              selected: _deadlineReminderHours == 24,
                              onSelected: () {
                                setState(() => _deadlineReminderHours = 24);
                                _savePreference('notif_deadline_hours', 24);
                              },
                            ),
                            _buildChoiceChip(
                              label: (_deadlineReminderHours != 3 &&
                                      _deadlineReminderHours != 24)
                                  ? '$_deadlineReminderHours Jam (Kustom) ✎'
                                  : '+ Atur Jam...',
                              selected: _deadlineReminderHours != 3 &&
                                  _deadlineReminderHours != 24,
                              onSelected: _showCustomDeadlineDialog,
                            ),
                          ],
                        ),
                      ],
                    ],
                    ),
                    const SizedBox(height: 18),
                  ],

                  // SEKSI 4: PENGUMUMAN KAMPUS
                  _buildSectionHeader('INFORMASI & PENGUMUMAN'),
                  _buildCard(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _announcementsEnabled,
                        activeThumbColor: AppColors.primary,
                        title: const Text('Pengumuman BAAK & Rektorat',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: const Text(
                          'Informasi kalender akademik, libur nasional, & edaran.',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        onChanged: (val) {
                          setState(() => _announcementsEnabled = val);
                          _savePreference('notif_announcements', val);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // SEKSI 5: NADA & GETAR
                  _buildSectionHeader('SUARA & GETARAN'),
                  _buildCard(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _soundEnabled,
                        activeThumbColor: AppColors.primary,
                        title: const Text('Bunyikan Suara Notifikasi',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        onChanged: (val) {
                          setState(() => _soundEnabled = val);
                          _savePreference('notif_sound', val);
                        },
                      ),
                      const Divider(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _vibrationEnabled,
                        activeThumbColor: AppColors.primary,
                        title: const Text('Getar Perangkat',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        onChanged: (val) {
                          setState(() => _vibrationEnabled = val);
                          _savePreference('notif_vibration', val);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // SEKSI 6: STATUS IZIN SISTEM OPERASI (Android & iOS)
                  _buildSectionHeader('STATUS PERIZINAN SISTEM OPERASI'),
                  _buildCard(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.infoLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.verified_user_outlined,
                                color: AppColors.info, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Perizinan Notifikasi & Alarm',
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Android 13+ (POST_NOTIFICATIONS & Exact Alarms) dan iOS (UNUserNotificationCenter) terdaftar untuk memastikan HP berdering tepat waktu.',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary,
                                      height: 1.35),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _checkSystemPermissions,
                          icon: const Icon(Icons.shield_outlined, size: 16),
                          label: const Text('Periksa Status Izin Sistem',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(
                                color: AppColors.primary, width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // TOMBOL UJI COBA NOTIFIKASI
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _triggerTestNotification,
                      icon: const Icon(Icons.send_rounded, size: 20),
                      label: Text(
                        _isSaving
                            ? 'Mengirim Notifikasi...'
                            : 'Uji Notifikasi Pengingat Sekarang',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 120), // Bottom padding agar tidak tertutup curved navigation bar
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
