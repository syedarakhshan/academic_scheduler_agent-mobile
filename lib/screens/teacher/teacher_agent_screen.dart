import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/teacher_agent_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/agent_message.dart';

/// Mirrors frontend/src/pages/teacher/TeacherAgentPage.js — quick
/// prompt buttons, a scrolling chat area with structured agent
/// replies (summary, conflicts, alternatives, result rows), and an
/// input bar. Table rows render as compact cards on mobile instead
/// of a horizontally-scrolling table, matching how every other
/// screen in this app avoids wide tables on a phone.
class TeacherAgentScreen extends StatefulWidget {
  const TeacherAgentScreen({super.key});

  @override
  State<TeacherAgentScreen> createState() => _TeacherAgentScreenState();
}

class _TeacherAgentScreenState extends State<TeacherAgentScreen> {
  static const _quickPrompts = [
    "Show today's timetable",
    'Show my weekly timetable',
    'What courses are assigned to me?',
    'Find available classrooms on Monday slot 2',
    'Show my reschedule request status',
  ];

  final _messages = <ChatMessage>[
    ChatMessage.agent(AgentReplyData(
      intent: 'ready',
      summary: 'Ask me about your timetable, assigned courses, classroom availability, conflict-free alternatives, reschedule requests, or request status.',
    )),
  ];
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _loading = false;
  bool _hasUserSentMessage = false;
  String? _error;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage(String text) async {
    final prompt = text.trim();
    if (prompt.isEmpty || _loading) return;

    setState(() {
      _error = null;
      _inputController.clear();
      _messages.add(ChatMessage.user(prompt));
      _hasUserSentMessage = true;
      _loading = true;
    });
    _scrollToBottom();

    try {
      final reply = await TeacherAgentService.instance.sendMessage(prompt);
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage.agent(reply));
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiClient.messageFrom(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Quick prompts (hidden once the user has sent anything) ─
        if (!_hasUserSentMessage)
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFEEF1F4))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final p in _quickPrompts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _QuickPromptButton(label: p, enabled: !_loading, onTap: () => _sendMessage(p)),
                  ),
              ],
            ),
          ),

        // ── Chat area ────────────────────────────────────────────
        Expanded(
          child: Container(
            color: const Color(0xFFF6F9FB),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length) return const _TypingBubble();
                return _MessageBubble(message: _messages[i]);
              },
            ),
          ),
        ),

        if (_error != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              border: Border.all(color: const Color(0xFFFECACA)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12, fontWeight: FontWeight.w600)),
          ),

        // ── Input bar ────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFEEF1F4)))),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCFDDE5)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Icon(Icons.assignment_outlined, size: 16, color: Color(0xFF7A9AAA)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _inputController,
                            onSubmitted: _sendMessage,
                            style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'Example: Check Room A-301 availability on Tuesday slot 3',
                              hintStyle: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12.5, color: Color(0xFF8FA5B0)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 44,
                  height: 42,
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _inputController,
                    builder: (context, value, _) {
                      final canSend = !_loading && value.text.trim().isNotEmpty;
                      return ElevatedButton(
                        onPressed: canSend ? () => _sendMessage(_inputController.text) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          disabledBackgroundColor: const Color(0xFF9DB2BD),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Icon(Icons.send, size: 17, color: Colors.white),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickPromptButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _QuickPromptButton({required this.label, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          backgroundColor: const Color(0xFFF7FAFC),
          side: const BorderSide(color: Color(0xFFD8E4EA)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.navy),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(10)),
          child: Text(message.text ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.35)),
        ),
      );
    }

    final data = message.data;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFDDE7EC)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.smart_toy_outlined, size: 16, color: AppColors.navy),
                const SizedBox(width: 8),
                const Text('Teacher AI Agent', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.navy)),
                if (data?.intent != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFF0F5F8), borderRadius: BorderRadius.circular(999)),
                    child: Text(
                      data!.intent!.replaceAll('_', ' '),
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF6B8794)),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(data?.summary ?? '', style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF233844))),
            if (data != null && data.missing.isNotEmpty)
              _NoticeBox(title: 'Missing details', lines: data.missing, danger: false),
            if (data != null && data.conflicts.isNotEmpty)
              _NoticeBox(title: 'Conflict status', lines: data.conflicts.map((c) => c.display).toList(), danger: true),
            if (data != null && data.rows.isNotEmpty) _ResultCards(rows: data.rows),
            if (data != null && data.alternatives.isNotEmpty)
              _NoticeBox(title: 'Suggested alternatives', lines: data.alternatives.map((a) => a.display).toList(), danger: false),
          ],
        ),
      ),
    );
  }
}

class _NoticeBox extends StatelessWidget {
  final String title;
  final List<String> lines;
  final bool danger;
  const _NoticeBox({required this.title, required this.lines, required this.danger});

  @override
  Widget build(BuildContext context) {
    final bg = danger ? const Color(0xFFFEF2F2) : const Color(0xFFEEF7FF);
    final border = danger ? const Color(0xFFFECACA) : const Color(0xFFB8D9F5);
    final titleColor = danger ? const Color(0xFFB91C1C) : const Color(0xFF1A5A7A);
    final textColor = danger ? const Color(0xFF7F1D1D) : const Color(0xFF1D4F68);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, border: Border.all(color: border), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(danger ? Icons.warning_amber_rounded : Icons.check_circle_outline, size: 15, color: titleColor),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: titleColor)),
            ],
          ),
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(line, style: TextStyle(fontSize: 12, color: textColor, height: 1.4)),
            ),
        ],
      ),
    );
  }
}

/// Table rows from ResultTable in TeacherAgentPage.js, rendered as
/// compact cards instead of a wide table so nothing needs horizontal
/// scrolling inside a chat bubble.
class _ResultCards extends StatelessWidget {
  final List<AgentResultRow> rows;
  const _ResultCards({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          for (final r in rows)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8FA),
                border: Border.all(color: const Color(0xFFE0E8ED)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.course ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A2E3A))),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 10,
                    runSpacing: 3,
                    children: [
                      if (r.batch != null) _kv('Batch', r.batch!),
                      if (r.teacher != null) _kv('Teacher', r.teacher!),
                      if (r.classroom != null) _kv('Room', r.classroom!),
                      if (r.day != null) _kv('Day', r.day!),
                      if (r.time != null) _kv('Time', r.time!),
                    ],
                  ),
                  if (r.availabilityStatus != null || r.conflictStatus != null) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (r.availabilityStatus != null) _statusChip(r.availabilityStatus!, const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
                        if (r.conflictStatus != null) _statusChip(r.conflictStatus!, const Color(0xFFDC2626), const Color(0xFFFEF2F2)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Text.rich(
    TextSpan(children: [
      TextSpan(text: '$k: ', style: const TextStyle(fontSize: 10.5, color: Color(0xFF7A9AAA), fontWeight: FontWeight.w600)),
      TextSpan(text: v, style: const TextStyle(fontSize: 10.5, color: Color(0xFF526B78), fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _statusChip(String text, Color fg, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
    child: Text(text, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: fg)),
  );
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFDDE7EC)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.smart_toy_outlined, size: 14, color: AppColors.navy),
                SizedBox(width: 7),
                Text('Agent', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.navy)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 10,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Row(
                    children: List.generate(3, (i) {
                      final t = (_controller.value + i * 0.15) % 1.0;
                      final opacity = 0.35 + 0.65 * (t < 0.4 ? (t / 0.4) : (t < 0.8 ? (1 - (t - 0.4) / 0.4) : 0));
                      return Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: Opacity(
                          opacity: opacity.clamp(0.35, 1.0),
                          child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF7A9AAA), shape: BoxShape.circle)),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}