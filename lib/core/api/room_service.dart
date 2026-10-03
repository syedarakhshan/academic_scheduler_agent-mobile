import 'api_client.dart';
import '../../models/room_info.dart';
import '../../models/timetable_entry.dart';

/// Mirrors RoomStatusPage in TeacherDashboard.js: api.get('/office/rooms')
/// and api.get('/office/room-schedule'). Both only require `authenticate`
/// on the backend, so a teacher account can call them same as the website.
class RoomService {
  RoomService._();
  static final RoomService instance = RoomService._();

  Future<List<RoomInfo>> getRooms() async {
    final res = await ApiClient.instance.dio.get('/office/rooms');
    final data = res.data as List;
    return data.map((e) => RoomInfo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<TimetableEntry>> getRoomSchedule({required int roomId}) async {
    final res = await ApiClient.instance.dio.get('/office/room-schedule', queryParameters: {
      'room_id': roomId,
    });
    final data = res.data as List;
    return data.map((e) => TimetableEntry.fromJson(e as Map<String, dynamic>)).toList();
  }
}