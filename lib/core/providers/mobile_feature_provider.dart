import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/mobile_feature_config.dart';
import '../models/mobile_feature_model.dart';
import '../models/sippm_lookup_model.dart';
import '../services/mobile_feature_service.dart';
import '../services/sippm_master_service.dart';
import 'auth_provider.dart';

/// Data fitur mobile berdasarkan kode fitur.
///
/// Fitur bertanda `dosenOnly` sengaja dikembalikan kosong untuk tendik agar
/// tidak membocorkan/menampilkan menu yang memang tidak relevan.
final mobileFeatureItemsProvider =
    FutureProvider.family<List<MobileFeatureItem>, String>((ref, code) async {
  final feature = AppMobileFeatures.findByCode(code);
  if (feature == null) return const <MobileFeatureItem>[];

  final user = ref.read(authProvider).user;
  if (feature.dosenOnly && user?.isDosen != true) {
    return const <MobileFeatureItem>[];
  }

  return MobileFeatureService.fetchItems(feature);
});

/// Master skema & periode yang dibutuhkan form proposal SIPPM.
final sippmLookupsProvider = FutureProvider<SippmLookups>((ref) async {
  return SippmMasterService.fetchLookups();
});
