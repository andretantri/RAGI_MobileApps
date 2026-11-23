import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/attendance_service.dart';

/// Model Pengguna Riil dari Backend Project Absen & RAG
class UserModel {
  final int id;
  final String name;
  final String email;
  /// Kode kepegawaian (employee_code / NIP) yang dipakai API absensi.
  final String nip;
  /// NIDN/NIDK dosen. Bisa berbeda dengan kode pegawai di API absensi.
  final String nidn;
  final String position;
  final String department;
  final String? officeName;
  final bool isActive;
  final bool isDosen;
  final String avatarInitial;
  final String? avatarBase64;
  final String? avatarUrl;
  final bool isFaceEnrolled;
  final String? faceEnrolledAt;
  final List<String> roles;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.nip,
    this.nidn = '',
    required this.position,
    required this.department,
    this.officeName,
    this.isActive = true,
    required this.isDosen,
    required this.avatarInitial,
    this.avatarBase64,
    this.avatarUrl,
    this.isFaceEnrolled = false,
    this.faceEnrolledAt,
    this.roles = const [],
  });

  /// Cek apakah pengguna memiliki hak akses / role Admin SIMPEG
  bool get isAdminSimpeg =>
      roles.contains('admin_simpeg') ||
      roles.contains('superadmin') ||
      roles.contains('admin') ||
      roles.contains('operator_sdm') ||
      position.toLowerCase().contains('admin simpeg') ||
      position.toLowerCase().contains('administrator simpeg');

  /// Cek apakah pengguna adalah Tenaga Kependidikan / Pegawai / Staf (Non-Dosen)
  bool get isTendik => !isDosen;

  /// Nama yang aman ditampilkan di UI (tidak pernah username/NIDN).
  String get displayName => name.trim().isEmpty ? 'Pegawai Indonusa' : name.trim();

  /// Nomor identitas utama yang mengikuti format jadwal mengajar SIAKAD:
  /// dosen memakai NIDN bila tersedia, tendik memakai NIP/NIK.
  String get displayId {
    if (isDosen && nidn.trim().isNotEmpty) return nidn.trim();
    final employeeCode = nip.trim();
    if (employeeCode.isNotEmpty &&
        employeeCode != '-' &&
        !employeeCode.contains('@')) {
      return employeeCode;
    }
    if (nidn.trim().isNotEmpty) return nidn.trim();
    return '-';
  }

  /// Label untuk [displayId]. Tetap NIP bila NIDN belum tersedia.
  String get displayIdLabel => isDosen && nidn.trim().isNotEmpty ? 'NIDN' : 'NIP';

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? nip,
    String? nidn,
    String? position,
    String? department,
    String? officeName,
    bool? isActive,
    bool? isDosen,
    String? avatarInitial,
    String? avatarBase64,
    String? avatarUrl,
    bool? isFaceEnrolled,
    String? faceEnrolledAt,
    bool clearFaceEnrolledAt = false,
    List<String>? roles,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      nip: nip ?? this.nip,
      nidn: nidn ?? this.nidn,
      position: position ?? this.position,
      department: department ?? this.department,
      officeName: officeName ?? this.officeName,
      isActive: isActive ?? this.isActive,
      isDosen: isDosen ?? this.isDosen,
      avatarInitial: avatarInitial ?? this.avatarInitial,
      avatarBase64: avatarBase64 ?? this.avatarBase64,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isFaceEnrolled: isFaceEnrolled ?? this.isFaceEnrolled,
      faceEnrolledAt: clearFaceEnrolledAt
          ? null
          : (faceEnrolledAt ?? this.faceEnrolledAt),
      roles: roles ?? this.roles,
    );
  }

  factory UserModel.fromApi({
    required Map<String, dynamic> user,
    required Map<String, dynamic> employee,
    String? cachedAvatarBase64,
    String? cachedAvatarUrl,
  }) {
    final empCode = _firstText([
      employee['employee_code'],
      employee['nip'],
      employee['nidn'],
    ]);
    final rawNip = _firstText([
      employee['nip'],
      employee['employee_code'],
      user['nip'],
    ]);
    final rawNidn = _firstText([
      employee['nidn'],
      employee['nidn_baru'],
      employee['nidn_lama'],
      user['nidn'],
    ]);

    // Nilai yang bukan nama (username, NIDN, NIP, email) tidak boleh
    // dijadikan nama tampil, meskipun employee tidak mengirim field name.
    final identityValues = <String>{
      _firstText([user['username']]),
      _firstText([user['email']]),
      empCode,
      rawNip,
      rawNidn,
    }.map((e) => e.toLowerCase()).where((e) => e.isNotEmpty).toSet();

    final employeeName = _pickName(employee, identityValues);
    final accountName = _pickName(user, identityValues);
    final name = employeeName.isNotEmpty
        ? employeeName
        : (accountName.isNotEmpty ? accountName : 'Pegawai Indonusa');

    final pos = (employee['position'] ?? 'Pegawai').toString();
    final dept = (employee['department'] ??
            employee['office']?['name'] ??
            'Politeknik Indonusa Surakarta')
        .toString();

    // Parse Roles pengguna
    final rawRoles = user['roles'] ?? employee['roles'];
    final List<String> rolesList = [];
    if (rawRoles is List) {
      for (final r in rawRoles) {
        if (r is String) {
          rolesList.add(r.toLowerCase());
        } else if (r is Map && r['slug'] != null) {
          rolesList.add(r['slug'].toString().toLowerCase());
        }
      }
    }
    if (user['is_admin'] == true || user['is_superadmin'] == true) {
      if (!rolesList.contains('admin')) rolesList.add('admin');
    }

    final posLower = pos.toLowerCase();
    final jenisPegawai = (employee['jenis_pegawai'] ?? '').toString().toLowerCase();

    // Dosen jika posisi, jenis pegawai, atau role mengandung kata 'dosen' atau 'pengajar'
    final isDosen = posLower.contains('dosen') ||
        posLower.contains('pengajar') ||
        jenisPegawai.contains('dosen') ||
        rolesList.contains('dosen') ||
        rolesList.contains('pengajar');

    // Buat initial 2 huruf dari nama lengkap
    final words = name.split(' ').where((w) => w.isNotEmpty).toList();
    String initials = 'ST';
    if (words.length >= 2) {
      initials = '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty && words[0].isNotEmpty) {
      initials = words[0].substring(0, words[0].length >= 2 ? 2 : 1).toUpperCase();
    }

    final isFaceEnrolled = employee['is_face_enrolled'] == true ||
        employee['has_face_enrolled'] == true ||
        employee['face_enrolled_at'] != null;
    final faceEnrolledAt = employee['face_enrolled_at']?.toString();

    final avatarUrl = cachedAvatarUrl ??
        user['avatar_url']?.toString() ??
        user['avatar']?.toString() ??
        employee['photo_url']?.toString() ??
        employee['foto']?.toString();

    return UserModel(
      id: user['id'] is int
          ? user['id']
          : int.tryParse(user['id']?.toString() ?? '0') ?? 0,
      name: name,
      email: user['email']?.toString() ?? '',
      nip: empCode.isNotEmpty
          ? empCode
          : (rawNip.isNotEmpty ? rawNip : (user['email']?.toString() ?? '-')),
      nidn: rawNidn,
      position: pos,
      department: dept,
      officeName: employee['office']?['name']?.toString(),
      isActive: employee['is_active'] != false,
      isDosen: isDosen,
      avatarInitial: initials,
      avatarBase64: cachedAvatarBase64,
      avatarUrl: avatarUrl,
      isFaceEnrolled: isFaceEnrolled,
      faceEnrolledAt: faceEnrolledAt,
      roles: rolesList,
    );
  }

  static String _firstText(Iterable<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static String _pickName(
    Map<String, dynamic> source,
    Set<String> identityValues,
  ) {
    const nameKeys = [
      'nama_lengkap',
      'nama_gelar',
      'name',
      'nama',
      'full_name',
      'display_name',
    ];
    for (final key in nameKeys) {
      final candidate = _firstText([source[key]]);
      if (candidate.isEmpty) continue;
      if (identityValues.contains(candidate.toLowerCase())) continue;
      if (candidate.contains('@')) continue;
      if (RegExp(r'^[0-9.\-_/ ]+$').hasMatch(candidate)) continue;
      return candidate;
    }
    return '';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'nip': nip,
        'nidn': nidn,
        'position': position,
        'department': department,
        'office_name': officeName,
        'is_active': isActive,
        'is_dosen': isDosen,
        'avatar_initial': avatarInitial,
        'avatar_base64': avatarBase64,
        'avatar_url': avatarUrl,
        'is_face_enrolled': isFaceEnrolled,
        'face_enrolled_at': faceEnrolledAt,
        'roles': roles,
      };
}

/// State Autentikasi Pengguna
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserModel? user;
  final String? errorMessage;
  final String? token;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.errorMessage,
    this.token,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserModel? user,
    String? errorMessage,
    String? token,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      token: token ?? this.token,
    );
  }
}

/// Provider State Notifier Autentikasi
class AuthNotifier extends StateNotifier<AuthState> {
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  AuthNotifier() : super(const AuthState()) {
    checkSession();
  }

  /// Cek hak akses kepegawaian (Dosen & Tendik / Staff diizinkan; Mahasiswa ditolak)
  static bool isAllowedStaffRole({
    Map<String, dynamic>? user,
    Map<String, dynamic>? employee,
  }) {
    // 1. Akun wajib memiliki entitas employee aktif
    if (employee == null || employee['is_active'] == false) {
      return false;
    }

    final pos = (employee['position'] ?? '').toString().toLowerCase();
    final jenis = (employee['jenis_pegawai'] ?? '').toString().toLowerCase();

    // Dilarang keras untuk Mahasiswa / Calon Mahasiswa
    if (pos.contains('mahasiswa') || jenis.contains('mahasiswa') || pos.contains('student')) {
      return false;
    }

    // Role yang diizinkan: Dosen, Tendik, Staff, Karyawan, dsb.
    return true;
  }

  /// Memeriksa sesi login tersimpan dari SharedPreferences saat aplikasi dibuka
  Future<bool> checkSession() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final token = await AttendanceService.getToken();
      if (token == null || token.isEmpty) {
        state = state.copyWith(isLoading: false, isAuthenticated: false);
        return false;
      }

      final userStr = await _secureStorage.read(key: 'user_data');
      final empStr = await _secureStorage.read(key: 'employee_data');
      // Avatar cache tetap di SharedPreferences (non-sensitif)
      final prefs = await SharedPreferences.getInstance();
      final cachedAvatarBase64 = prefs.getString('user_avatar_base64');
      final cachedAvatarUrl = prefs.getString('user_avatar_url');

      if (userStr != null && empStr != null) {
        final userMap = jsonDecode(userStr) as Map<String, dynamic>;
        final empMap = jsonDecode(empStr) as Map<String, dynamic>;

        if (!isAllowedStaffRole(user: userMap, employee: empMap)) {
          await logout();
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: false,
            errorMessage:
                'Akses ditolak: Aplikasi ini hanya diperuntukkan bagi Dosen dan Pegawai / Tenaga Kependidikan.',
          );
          return false;
        }

        if (!mounted) return true;
        final userModel = UserModel.fromApi(
          user: userMap,
          employee: empMap,
          cachedAvatarBase64: cachedAvatarBase64,
          cachedAvatarUrl: cachedAvatarUrl,
        );
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: userModel,
          token: token,
        );

        // Segarkan profil di latar belakang
        _refreshProfile();
        return true;
      }
    } catch (e) {
      debugPrint('[AuthNotifier] checkSession error: $e');
    }
    state = state.copyWith(isLoading: false, isAuthenticated: false);
    return false;
  }

  /// Login melalui API backend absensi / SSO
  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final res = await AttendanceService.login(
        login: username,
        password: password,
      );

      if (!res.success || res.data == null) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          errorMessage: res.message,
        );
        return false;
      }

      final data = res.data!;
      final userMap = data['user'] as Map<String, dynamic>? ?? {};
      final empMap = data['employee'] as Map<String, dynamic>? ?? {};
      final token = data['token']?.toString() ?? '';

      // VALIDASI HAK AKSES: Hanya Dosen dan Tenaga Kependidikan (Staff) yang boleh masuk!
      if (!isAllowedStaffRole(user: userMap, employee: empMap)) {
        await AttendanceService.logout();
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          errorMessage:
              'Akses ditolak: Aplikasi ini hanya diperuntukkan bagi Dosen dan Pegawai / Tenaga Kependidikan.',
        );
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final cachedAvatarBase64 = prefs.getString('user_avatar_base64');
      final cachedAvatarUrl = prefs.getString('user_avatar_url');

      final userModel = UserModel.fromApi(
        user: userMap,
        employee: empMap,
        cachedAvatarBase64: cachedAvatarBase64,
        cachedAvatarUrl: cachedAvatarUrl,
      );

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: userModel,
        token: token,
        clearError: true,
      );

      return true;
    } catch (e) {
      debugPrint('[AuthNotifier] login error: $e');
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: 'Terjadi kesalahan: $e',
      );
      return false;
    }
  }

  /// Update data pendaftaran wajah di state lokal
  void updateFaceEnrollment({
    required bool isEnrolled,
    String? enrolledAt,
  }) {
    if (state.user == null) {
      state = state.copyWith(
        user: UserModel(
          id: 0,
          name: 'Pegawai Indonusa',
          email: '',
          nip: '',
          position: 'Pegawai',
          department: '',
          isDosen: false,
          avatarInitial: 'PI',
          isFaceEnrolled: isEnrolled,
          faceEnrolledAt: enrolledAt,
        ),
      );
      return;
    }
    final updatedUser = state.user!.copyWith(
      isFaceEnrolled: isEnrolled,
      faceEnrolledAt: enrolledAt,
      clearFaceEnrolledAt: !isEnrolled,
    );
    state = state.copyWith(user: updatedUser);

    // Perbarui juga data employee_data di secure storage
    _secureStorage.read(key: 'employee_data').then((empStr) {
      if (empStr != null) {
        try {
          final emp = jsonDecode(empStr) as Map<String, dynamic>;
          emp['is_face_enrolled'] = isEnrolled;
          emp['has_face_enrolled'] = isEnrolled;
          emp['face_enrolled_at'] = enrolledAt;
          _secureStorage.write(key: 'employee_data', value: jsonEncode(emp));
        } catch (_) {}
      }
    });
  }

  /// Update foto profil (avatar) dan sinkronisasi ke server RAG.
  /// Perubahan lokal hanya dipertahankan jika API merespons sukses.
  Future<bool> updateAvatar({
    String? avatarBase64,
    bool removeAvatar = false,
  }) async {
    final previousUser = state.user;
    if (previousUser == null) return false;
    if (!removeAvatar && (avatarBase64 == null || avatarBase64.isEmpty)) {
      return false;
    }

    final updatedUser = previousUser.copyWith(
      avatarBase64: removeAvatar ? '' : avatarBase64,
      avatarUrl: removeAvatar ? '' : previousUser.avatarUrl,
    );
    state = state.copyWith(user: updatedUser);

    final res = await AttendanceService.updateProfileAvatar(
      avatarBase64: avatarBase64,
      removeAvatar: removeAvatar,
    );
    if (!res.success) {
      state = state.copyWith(user: previousUser);
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    if (removeAvatar) {
      await prefs.remove('user_avatar_base64');
      await prefs.remove('user_avatar_url');
    } else {
      await prefs.setString('user_avatar_base64', avatarBase64!);
    }
    return true;
  }

  /// Segarkan profil dari server di latar belakang
  Future<void> _refreshProfile() async {
    final res = await AttendanceService.getProfile();
    if (res.message == 'UNAUTHORIZED_401') {
      // Sesi token di server RAG telah kedaluwarsa atau dicabut -> logout bersih
      await logout();
      return;
    }
    if (res.success && res.data != null && mounted) {
      final data = res.data!;
      final userMap = data['user'] as Map<String, dynamic>? ?? {};
      final empMap = data['employee'] as Map<String, dynamic>? ?? {};

      if (userMap.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final cachedAvatarBase64 = prefs.getString('user_avatar_base64');
        final cachedAvatarUrl = prefs.getString('user_avatar_url');

        final refreshed = UserModel.fromApi(
          user: userMap,
          employee: empMap,
          cachedAvatarBase64: cachedAvatarBase64,
          cachedAvatarUrl: cachedAvatarUrl,
        );
        state = state.copyWith(user: refreshed);
      }
    }
  }

  /// Logout pengguna
  Future<void> logout() async {
    await AttendanceService.logout();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
