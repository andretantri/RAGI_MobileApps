import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/grading_model.dart';
import '../models/advisee_model.dart';
import '../services/academic_service.dart';

// ==========================================
// 1. GRADING STATE & NOTIFIER
// ==========================================

class GradingState {
  final bool isLoading;
  final bool isSaving;
  final List<GradingClassItem> classes;
  final GradingClassDetail? selectedClassDetail;
  final String? errorMessage;
  final String? successMessage;

  const GradingState({
    this.isLoading = false,
    this.isSaving = false,
    this.classes = const [],
    this.selectedClassDetail,
    this.errorMessage,
    this.successMessage,
  });

  GradingState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<GradingClassItem>? classes,
    GradingClassDetail? selectedClassDetail,
    String? errorMessage,
    String? successMessage,
    bool clearDetail = false,
  }) {
    return GradingState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      classes: classes ?? this.classes,
      selectedClassDetail: clearDetail ? null : (selectedClassDetail ?? this.selectedClassDetail),
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class GradingNotifier extends StateNotifier<GradingState> {
  GradingNotifier() : super(const GradingState()) {
    loadClasses();
  }

  Future<void> loadClasses() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await AcademicService.fetchGradingClasses();
      state = state.copyWith(isLoading: false, classes: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Gagal memuat daftar kelas: $e');
    }
  }

  Future<void> loadClassDetail(int kelasId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final detail = await AcademicService.fetchClassGradeDetail(kelasId);
      state = state.copyWith(isLoading: false, selectedClassDetail: detail);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Gagal memuat detail kelas: $e');
    }
  }

  void updateStudentGrade({
    required int krsDetailId,
    double? nilaiHarian,
    double? nilaiUts,
    double? nilaiUas,
    double? nilaiPraktik,
  }) {
    final detail = state.selectedClassDetail;
    if (detail == null) return;

    final updatedStudents = detail.students.map((student) {
      if (student.krsDetailId == krsDetailId) {
        if (nilaiHarian != null) student.nilaiHarian = nilaiHarian;
        if (nilaiUts != null) student.nilaiUts = nilaiUts;
        if (nilaiUas != null) student.nilaiUas = nilaiUas;
        if (nilaiPraktik != null) student.nilaiPraktik = nilaiPraktik;
        student.recalculate(detail.bobot);
      }
      return student;
    }).toList();

    state = state.copyWith(
      selectedClassDetail: GradingClassDetail(
        kelasId: detail.kelasId,
        kodeKelas: detail.kodeKelas,
        namaKelas: detail.namaKelas,
        kodeMk: detail.kodeMk,
        namaMk: detail.namaMk,
        sks: detail.sks,
        prodi: detail.prodi,
        bobot: detail.bobot,
        students: updatedStudents,
      ),
    );
  }

  Future<bool> saveGrades({bool isFinal = false}) async {
    final detail = state.selectedClassDetail;
    if (detail == null) return false;

    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      if (isFinal) {
        for (final s in detail.students) {
          s.isFinal = true;
        }
      }

      final success = await AcademicService.saveClassGrades(
        kelasId: detail.kelasId,
        grades: detail.students,
      );

      if (success) {
        state = state.copyWith(
          isSaving: false,
          successMessage: isFinal
              ? 'Nilai mahasiswa berhasil difinalisasi ke SIAKAD & KHS.'
              : 'Draft nilai berhasil disimpan.',
        );
        await loadClasses();
        return true;
      } else {
        state = state.copyWith(isSaving: false, errorMessage: 'Gagal menyimpan nilai.');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: 'Error: $e');
      return false;
    }
  }
}

final gradingProvider = StateNotifierProvider<GradingNotifier, GradingState>((ref) {
  return GradingNotifier();
});

// ==========================================
// 2. ADVISEE (DPA & KRS) STATE & NOTIFIER
// ==========================================

class AdviseeState {
  final bool isLoading;
  final bool isProcessing;
  final List<AdviseeStudent> advisees;
  final KrsApprovalDetail? selectedKrsDetail;
  final List<PaConsultationNote> selectedNotes;
  final String filterStatus; // 'semua' | 'menunggu_persetujuan' | 'disetujui'
  final String? errorMessage;
  final String? successMessage;

  const AdviseeState({
    this.isLoading = false,
    this.isProcessing = false,
    this.advisees = const [],
    this.selectedKrsDetail,
    this.selectedNotes = const [],
    this.filterStatus = 'semua',
    this.errorMessage,
    this.successMessage,
  });

  List<AdviseeStudent> get filteredAdvisees {
    if (filterStatus == 'semua') return advisees;
    return advisees.where((a) => a.krs?.status == filterStatus).toList();
  }

  int get pendingApprovalCount =>
      advisees.where((a) => a.krs?.status == 'menunggu_persetujuan').length;

  AdviseeState copyWith({
    bool? isLoading,
    bool? isProcessing,
    List<AdviseeStudent>? advisees,
    KrsApprovalDetail? selectedKrsDetail,
    List<PaConsultationNote>? selectedNotes,
    String? filterStatus,
    String? errorMessage,
    String? successMessage,
    bool clearKrsDetail = false,
  }) {
    return AdviseeState(
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      advisees: advisees ?? this.advisees,
      selectedKrsDetail: clearKrsDetail ? null : (selectedKrsDetail ?? this.selectedKrsDetail),
      selectedNotes: selectedNotes ?? this.selectedNotes,
      filterStatus: filterStatus ?? this.filterStatus,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class AdviseeNotifier extends StateNotifier<AdviseeState> {
  AdviseeNotifier() : super(const AdviseeState()) {
    loadAdvisees();
  }

  void setFilter(String status) {
    state = state.copyWith(filterStatus: status);
  }

  Future<void> loadAdvisees() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await AcademicService.fetchAdvisees();
      state = state.copyWith(isLoading: false, advisees: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Gagal memuat mahasiswa bimbingan: $e');
    }
  }

  Future<void> loadKrsDetail(int krsId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final detail = await AcademicService.fetchKrsDetail(krsId);
      state = state.copyWith(isLoading: false, selectedKrsDetail: detail);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Gagal memuat rincian KRS: $e');
    }
  }

  Future<bool> approveKrs(int krsId) async {
    state = state.copyWith(isProcessing: true, errorMessage: null);
    try {
      final success = await AcademicService.approveKrs(krsId);
      if (success) {
        state = state.copyWith(
          isProcessing: false,
          successMessage: 'KRS mahasiswa berhasil disetujui & divalidasi.',
        );
        // Refresh detail dan advisees
        await loadKrsDetail(krsId);
        await loadAdvisees();
        return true;
      } else {
        state = state.copyWith(isProcessing: false, errorMessage: 'Gagal menyetujui KRS.');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isProcessing: false, errorMessage: 'Error: $e');
      return false;
    }
  }

  Future<bool> rejectKrs(int krsId, String alasan) async {
    state = state.copyWith(isProcessing: true, errorMessage: null);
    try {
      final success = await AcademicService.rejectKrs(krsId, alasan);
      if (success) {
        state = state.copyWith(
          isProcessing: false,
          successMessage: 'Permintaan revisi KRS telah dikirimkan ke mahasiswa.',
        );
        await loadKrsDetail(krsId);
        await loadAdvisees();
        return true;
      } else {
        state = state.copyWith(isProcessing: false, errorMessage: 'Gagal mengirim revisi KRS.');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isProcessing: false, errorMessage: 'Error: $e');
      return false;
    }
  }

  Future<void> loadNotes(int mahasiswaId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final notes = await AcademicService.fetchConsultationNotes(mahasiswaId);
      state = state.copyWith(isLoading: false, selectedNotes: notes);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Gagal memuat catatan bimbingan: $e');
    }
  }

  Future<bool> addNote({
    required int mahasiswaId,
    required String isi,
    String kategori = 'Akademik',
    String? kesimpulan,
  }) async {
    state = state.copyWith(isProcessing: true, errorMessage: null);
    try {
      final note = await AcademicService.addConsultationNote(
        mahasiswaId: mahasiswaId,
        isi: isi,
        kategori: kategori,
        kesimpulan: kesimpulan,
      );

      if (note != null) {
        final updated = [note, ...state.selectedNotes];
        state = state.copyWith(
          isProcessing: false,
          selectedNotes: updated,
          successMessage: 'Catatan konsultasi berhasil ditambahkan.',
        );
        return true;
      }
      state = state.copyWith(isProcessing: false, errorMessage: 'Gagal menambah catatan.');
      return false;
    } catch (e) {
      state = state.copyWith(isProcessing: false, errorMessage: 'Error: $e');
      return false;
    }
  }
}

final adviseeProvider = StateNotifierProvider<AdviseeNotifier, AdviseeState>((ref) {
  return AdviseeNotifier();
});
