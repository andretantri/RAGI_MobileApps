/// Modul RAG yang benar-benar dapat diakses akun yang login.
///
/// Sumber: `GET /api/modules/my-modules`, endpoint yang sama dipakai
/// App Launcher di web RAG (`http://localhost:57135/#/modules`).
class RagModule {
  final int id;
  final String code;
  final String name;
  final String description;
  final String? primaryColor;
  final bool isActive;

  const RagModule({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    this.primaryColor,
    this.isActive = true,
  });

  factory RagModule.fromJson(Map<String, dynamic> json) {
    return RagModule(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      code: (json['code'] ?? '').toString().trim().toLowerCase(),
      name: (json['name'] ?? '').toString().trim(),
      description: (json['description'] ?? '').toString().trim(),
      primaryColor: json['primary_color']?.toString().trim(),
      isActive: json['is_active'] == true ||
          json['is_active'] == 1 ||
          json['is_active'] == '1',
    );
  }
}
