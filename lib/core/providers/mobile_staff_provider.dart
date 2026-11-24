import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mobile_feature_model.dart';
import '../models/mobile_staff_models.dart';
import '../services/mobile_staff_service.dart';

/// Daftar fitur mobile staff yang memakai endpoint v1 baru.
final mobileStaffPageProvider = FutureProvider.family<MobileStaffPage, String>((
  ref,
  endpoint,
) async {
  return MobileStaffService.fetchList(endpoint);
});

/// Detail satu item (contoh: e-file). [endpoint] sudah termasuk ID.
final mobileStaffDetailProvider =
    FutureProvider.family<MobileFeatureItem, String>((ref, endpoint) async {
      return MobileStaffService.fetchDetail(endpoint);
    });

/// Detail payroll milik pegawai login (beserta komponen gaji).
final mobileStaffPayrollDetailProvider =
    FutureProvider.family<MobileStaffPayrollDetail, String>((ref, id) async {
      return MobileStaffService.fetchPayrollDetail(id);
    });

/// Master SIMPEG dinamis untuk dropdown form self-service.
final mobileStaffMasterLookupsProvider = FutureProvider<MobileStaffLookups>((
  ref,
) async {
  return MobileStaffService.fetchMasterLookups();
});
