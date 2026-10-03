/// Mirrors one row from GET /api/office/batches
/// (backend/routes/officeRoutes.js).
class Batch {
  final int id;
  final String batchName;
  final String? major;
  final String? majorCode;
  final int? year;

  Batch({required this.id, required this.batchName, this.major, this.majorCode, this.year});

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: json['id'] as int,
      batchName: json['batch_name'] as String? ?? '',
      major: json['major'] as String?,
      majorCode: json['major_code'] as String?,
      year: json['year'] as int?,
    );
  }
}

/// Mirrors the MAJORS grouping used in TeacherDashboard.js's
/// AllBatchesPage, so the batch picker groups the same way the
/// website's dropdown <optgroup>s do.
class Major {
  final String label;
  final String code;
  const Major(this.label, this.code);

  static const all = [
    Major('Computer Science', 'CS'),
    Major('Software Engineering', 'SE'),
    Major('Data Science', 'DS'),
  ];

  bool matches(Batch b) {
    if (b.majorCode == code) return true;
    if (b.major != null && b.major!.contains(label.split(' ').first)) return true;
    return false;
  }
}