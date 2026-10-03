import 'api_client.dart';
import '../../models/agent_message.dart';

/// Mirrors api.post('/teacher-agent/message', { message: prompt })
/// from TeacherAgentPage.js.
class TeacherAgentService {
  TeacherAgentService._();
  static final TeacherAgentService instance = TeacherAgentService._();

  Future<AgentReplyData> sendMessage(String message) async {
    final res = await ApiClient.instance.dio.post('/teacher-agent/message', data: {'message': message});
    return AgentReplyData.fromJson(res.data as Map<String, dynamic>);
  }
}