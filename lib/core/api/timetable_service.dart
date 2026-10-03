import 'api_client.dart';
import '../../models/timetable_entry.dart';

/// Mirrors `api.get('/timetable')` used throughout the web app.
/// The backend already scopes results to the logged-in user's role
/// (a teacher gets their own classes, a student gets their batch's),
/// so this one call serves both panels — same as the website.
class TimetableService {
  TimetableService._();
  static final TimetableService instance = TimetableService._();

  Future<List<TimetableEntry>> getTimetable() async {
    final res = await ApiClient.instance.dio.get('/timetable');
    final data = res.data as List;
    return data.map((e) => TimetableEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Mirrors POST /api/timetable/reschedule-request
  /// (backend/controllers/timetableController.js: teacherRescheduleRequest).
  /// Goes to the Office Assistant for approval — same as the web app's
  /// "Request Reschedule" modal on My Schedule.
  Future<String> submitRescheduleRequest({
    required int timetableId,
    required String newDay,
    required int newTimeSlot,
    String? reason,
  }) async {
    final res = await ApiClient.instance.dio.post('/timetable/reschedule-request', data: {
      'timetable_id': timetableId,
      'new_day': newDay,
      'new_time_slot': newTimeSlot,
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    });
    return res.data['message'] as String? ?? 'Reschedule request submitted.';
  }
}