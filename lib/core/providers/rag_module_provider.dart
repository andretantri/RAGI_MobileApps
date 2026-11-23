import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rag_module.dart';
import '../services/rag_module_service.dart';

/// Modul RAG yang diizinkan untuk akun login (sumber: `/modules/my-modules`).
///
/// Provider ini di-key oleh token SSO. Bila akun berganti, token berubah dan
/// Riverpod otomatis mengambil ulang daftar modul — sama seperti web RAG yang
/// me-refetch saat `authToken` berubah.
final myRagModulesProvider =
    FutureProvider.family<List<RagModule>, String?>((ref, token) async {
  return RagModuleService.fetchMyModules(tokenOverride: token);
});
