/// Mirrors one row returned by GET /api/timetable
/// (backend/controllers/timetableController.js), as consumed by
/// TeacherDashboard.js / StudentDashboard.js on the web app.
class TimetableEntry {
  final int id;
  final int? subjectId;
  final String day; // 'Monday'..'Saturday'
  final int timeSlot;
  final String slotLabel; // e.g. '10:00 - 11:00'
  final String subjectName;
  final String? shortName;
  final String? teacherName;
  final String? roomCode;
  final String? roomId;
  final String? batchName;
  final bool isLab;

  TimetableEntry({
    required this.id,
    this.subjectId,
    required this.day,
    required this.timeSlot,
    required this.slotLabel,
    required this.subjectName,
    this.shortName,
    this.teacherName,
    this.roomCode,
    this.roomId,
    this.batchName,
    this.isLab = false,
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    return TimetableEntry(
      id: json['id'] as int,
      subjectId: json['subject_id'] as int?,
      day: json['day'] as String,
      timeSlot: int.parse(json['time_slot'].toString()),
      slotLabel: json['slot_label'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? '',
      shortName: json['short_name'] as String?,
      teacherName: json['teacher_name'] as String?,
      roomCode: json['room_code'] as String?,
      roomId: json['room_id']?.toString(),
      batchName: json['batch_name'] as String?,
      isLab: json['is_lab'] == true,
    );
  }

  /// Falls back to room_id if room_code isn't present, same as
  /// `e.room_code || e.room_id` throughout the React app.
  String get roomDisplay => roomCode ?? roomId ?? '—';

  static const List<String> weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  /// Mirrors backend/controllers/timetableController.js SLOT_LABELS.
  static const Map<int, String> slotLabels = {
    1: '9:00 - 10:00',
    2: '10:00 - 11:00',
    3: '11:00 - 12:00',
    4: '12:00 - 1:00',
    5: '1:00 - 2:00',
  };

  /// Mirrors backend/controllers/timetableController.js LAB_SLOT_LABELS.
  static const Map<int, String> labSlotLabels = {
    1: '9:00 - 12:00 (Lab)',
    2: '10:00 - 1:00 (Lab)',
    3: '11:00 - 2:00 (Lab)',
    4: '12:00 - 3:00 (Lab)',
    5: '1:00 - 4:00 (Lab)',
  };
}