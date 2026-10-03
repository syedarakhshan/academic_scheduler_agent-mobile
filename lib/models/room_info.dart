/// Mirrors one row from GET /api/office/rooms
/// (backend/routes/officeRoutes.js).
class RoomInfo {
  final int id;
  final String roomId; // room code, e.g. "B-14"
  final String? roomName;
  final int capacity;
  final String roomType; // 'classroom' | 'lab'
  final bool isAvailable;

  RoomInfo({
    required this.id,
    required this.roomId,
    this.roomName,
    required this.capacity,
    required this.roomType,
    required this.isAvailable,
  });

  factory RoomInfo.fromJson(Map<String, dynamic> json) {
    return RoomInfo(
      id: json['id'] as int,
      roomId: json['room_id'] as String? ?? '',
      roomName: json['room_name'] as String?,
      capacity: json['capacity'] as int? ?? 0,
      roomType: json['room_type'] as String? ?? 'classroom',
      isAvailable: json['is_available'] == true,
    );
  }

  String get display => '$roomId — Cap: $capacity ($roomType)';
}