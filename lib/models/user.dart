/// Mirrors the `user` object returned by POST /api/auth/login
/// and GET /api/auth/me (backend/controllers/authController.js).
class AppUser {
  final int id;
  final String juwId;
  final String fullName;
  final String role; // 'teacher' | 'student' (office_assistant unused in this app)
  final int? departmentId;
  final String? departmentName; // only present from /auth/me

  AppUser({
    required this.id,
    required this.juwId,
    required this.fullName,
    required this.role,
    this.departmentId,
    this.departmentName,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      juwId: json['juw_id'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      departmentId: json['department_id'] as int?,
      departmentName: json['department_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'juw_id': juwId,
    'full_name': fullName,
    'role': role,
    'department_id': departmentId,
    'department_name': departmentName,
  };

  static const _titles = {'mr', 'mrs', 'ms', 'miss', 'dr', 'sir', 'prof', 'professor'};

  /// e.g. "Ms. Ummay Faseeha" -> "UF" (skips the "Ms." title, uses the
  /// first letter of the first name and the first letter of the last
  /// name — not just the first two words, so a middle name like
  /// "Ms. Hafiza Anisa Ahmed" still correctly gives "HA", not "HA"
  /// from the wrong pair of words).
  String get initials {
    final rawParts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final parts = rawParts.where((p) {
      final cleaned = p.replaceAll('.', '').toLowerCase();
      return !_titles.contains(cleaned);
    }).toList();

    if (parts.isEmpty) return role == 'teacher' ? 'T' : 'S';
    if (parts.length == 1) return parts.first[0].toUpperCase();

    final first = parts.first[0];
    final last = parts.last[0];
    return (first + last).toUpperCase();
  }

  bool get isTeacher => role == 'teacher';
  bool get isStudent => role == 'student';
}