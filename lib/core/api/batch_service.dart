import 'api_client.dart';
import '../../models/batch.dart';
import '../../models/timetable_entry.dart';

/// Mirrors the two endpoints AllBatchesPage in TeacherDashboard.js
/// uses: api.get('/office/batches') and api.get('/office/batch-timetable').
/// Both only require `authenticate` on the backend (not office-only),
/// so teacher accounts can call them too — same as the website does.
class BatchService {
  BatchService._();
  static final BatchService instance = BatchService._();

  Future<List<Batch>> getBatches() async {
    final res = await ApiClient.instance.dio.get('/office/batches');
    final data = res.data as List;
    return data.map((e) => Batch.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<TimetableEntry>> getBatchTimetable({required int batchId, required int semester}) async {
    final res = await ApiClient.instance.dio.get('/office/batch-timetable', queryParameters: {
      'batch_id': batchId,
      'semester': semester,
    });
    final data = res.data as List;
    return data.map((e) => TimetableEntry.fromJson(e as Map<String, dynamic>)).toList();
  }
}