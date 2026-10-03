/// One line item inside "Conflict status" / "Suggested alternatives"
/// sections. Mirrors NoticeList's item shape in TeacherAgentPage.js:
/// either a ready-made `message`, or day/time/classroom to compose one.
class AgentNoticeItem {
  final String? message;
  final String? day;
  final String? time;
  final String? classroom;

  AgentNoticeItem({this.message, this.day, this.time, this.classroom});

  factory AgentNoticeItem.fromJson(Map<String, dynamic> json) {
    return AgentNoticeItem(
      message: json['message'] as String?,
      day: json['day'] as String?,
      time: json['time'] as String?,
      classroom: json['classroom'] as String?,
    );
  }

  String get display {
    if (message != null && message!.isNotEmpty) return message!;
    return [day, time, classroom].where((s) => s != null && s.isNotEmpty).join(' ');
  }
}

/// One row of ResultTable in TeacherAgentPage.js.
class AgentResultRow {
  final String? course;
  final String? batch;
  final String? teacher;
  final String? classroom;
  final String? day;
  final String? time;
  final String? availabilityStatus;
  final String? conflictStatus;

  AgentResultRow({
    this.course,
    this.batch,
    this.teacher,
    this.classroom,
    this.day,
    this.time,
    this.availabilityStatus,
    this.conflictStatus,
  });

  factory AgentResultRow.fromJson(Map<String, dynamic> json) {
    return AgentResultRow(
      course: json['course']?.toString(),
      batch: json['batch']?.toString(),
      teacher: json['teacher']?.toString(),
      classroom: json['classroom']?.toString(),
      day: json['day']?.toString(),
      time: json['time']?.toString(),
      availabilityStatus: json['availabilityStatus']?.toString(),
      conflictStatus: json['conflictStatus']?.toString(),
    );
  }
}

/// Mirrors the full response body of POST /api/teacher-agent/message.
class AgentReplyData {
  final String? intent;
  final String? summary;
  final List<String> missing;
  final List<AgentNoticeItem> conflicts;
  final List<AgentResultRow> rows;
  final List<AgentNoticeItem> alternatives;

  AgentReplyData({
    this.intent,
    this.summary,
    this.missing = const [],
    this.conflicts = const [],
    this.rows = const [],
    this.alternatives = const [],
  });

  factory AgentReplyData.fromJson(Map<String, dynamic> json) {
    return AgentReplyData(
      intent: json['intent'] as String?,
      summary: json['summary'] as String?,
      missing: (json['missing'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      conflicts: (json['conflicts'] as List?)?.map((e) => AgentNoticeItem.fromJson(e as Map<String, dynamic>)).toList() ?? const [],
      rows: (json['rows'] as List?)?.map((e) => AgentResultRow.fromJson(e as Map<String, dynamic>)).toList() ?? const [],
      alternatives: (json['alternatives'] as List?)?.map((e) => AgentNoticeItem.fromJson(e as Map<String, dynamic>)).toList() ?? const [],
    );
  }
}

/// One bubble in the chat — either what the user typed, or the
/// agent's structured reply. Mirrors the `messages` array shape in
/// TeacherAgentPage.js.
class ChatMessage {
  final bool isUser;
  final String? text; // set for user messages
  final AgentReplyData? data; // set for agent messages

  ChatMessage.user(this.text) : isUser = true, data = null;
  ChatMessage.agent(this.data) : isUser = false, text = null;
}