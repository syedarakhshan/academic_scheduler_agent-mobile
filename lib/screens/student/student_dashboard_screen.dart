import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/timetable_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/timetable_entry.dart';
import '../../providers/auth_provider.dart';

/// Mirrors the Teacher Dashboard's look: profile card on top (with the
/// student's subjects as chips), light pastel stat cards, and Today's
/// classes colored per subject. No Weekly Overview section.
class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  List<TimetableEntry> _entries = [];
  bool _loading = true;
  String? _error;

  static const _weekdayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  String get _today {
    final i = DateTime.now().weekday - 1;
    return i < 6 ? _weekdayNames[i] : 'Monday';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await TimetableService.instance.getTimetable();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load your schedule. Pull down to retry.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    final todayClasses = _entries.where((e) => e.day == _today).toList()..sort((a, b) => a.timeSlot.compareTo(b.timeSlot));
    final subjects = _entries.map((e) => e.subjectName).where((s) => s.isNotEmpty).toSet().toList();
    final batchName = _entries.isNotEmpty ? (_entries.first.batchName ?? '-') : '-';

    // Consistent color per subject across the screen.
    final subjectOrder = _entries.map((e) => e.subjectName).toSet().toList()..sort();
    int colorIndexFor(String name) => subjectOrder.indexOf(name);

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.navy,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          if (_error != null) _ErrorBanner(message: _error!, onRetry: _load),

          // ── Profile card ────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.navy,
                    child: Text(user?.initials ?? 'S', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                  ),
                  const SizedBox(height: 10),
                  Text(user?.fullName ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A2E3A))),
                  const SizedBox(height: 2),
                  const Text('Student', style: TextStyle(fontSize: 12, color: Color(0xFF7A9AAA))),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4FD),
                      border: Border.all(color: const Color(0xFFB8D9F5)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(batchName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A5A7A))),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Text('STUDENT ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Text(
                    user?.juwId ?? '-',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Text('MY SUBJECTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  if (subjects.isNotEmpty)
                    Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: [for (final sub in subjects) _Chip(sub)])
                  else if (!_loading)
                    const Text('No subjects found.', style: TextStyle(fontSize: 12, color: Color(0xFFAABBC8))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Stat cards: 2x2 ──────────────────────────────────────
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.2,
            children: [
              _StatCard(label: 'Classes This Week', value: '${_entries.length}', loading: _loading, colors: _SubjectColors.of(0), icon: Icons.calendar_today_outlined),
              _StatCard(label: "Today's Classes", value: '${todayClasses.length}', loading: _loading, colors: _SubjectColors.of(2), icon: Icons.access_time),
              _StatCard(label: 'My Subjects', value: '${subjects.length}', loading: _loading, colors: _SubjectColors.of(5), icon: Icons.menu_book_outlined),
              _StatCard(label: 'My Batch', value: batchName, loading: _loading, colors: _SubjectColors.of(1), icon: Icons.groups_outlined),
            ],
          ),
          const SizedBox(height: 14),

          // ── Today's schedule ─────────────────────────────────────
          _SectionCard(
            icon: Icons.access_time,
            title: 'Today — $_today',
            child: _loading
                ? const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator(color: AppColors.navy)))
                : todayClasses.isEmpty
                ? const _EmptyRow(icon: Icons.calendar_today_outlined, text: 'No classes today', subtext: 'Enjoy your free day!')
                : Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(children: [for (final e in todayClasses) _ColoredClassRow(entry: e, colors: _SubjectColors.of(colorIndexFor(e.subjectName)))]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Same light pastel palette used across the app (teacher screens,
/// batch timetable, room status) — a subject keeps its color everywhere.
class _SubjectColors {
  final Color border;
  final Color bg;
  final Color title;
  final Color body;
  const _SubjectColors({required this.border, required this.bg, required this.title, required this.body});

  static const palette = [
    _SubjectColors(border: Color(0xFF185FA5), bg: Color(0xFFE6F1FB), title: Color(0xFF0C447C), body: Color(0xFF185FA5)),
    _SubjectColors(border: Color(0xFF854F0B), bg: Color(0xFFFAEEDA), title: Color(0xFF633806), body: Color(0xFF854F0B)),
    _SubjectColors(border: Color(0xFF3B6D11), bg: Color(0xFFEAF3DE), title: Color(0xFF27500A), body: Color(0xFF3B6D11)),
    _SubjectColors(border: Color(0xFF993C1D), bg: Color(0xFFFAECE7), title: Color(0xFF712B13), body: Color(0xFF993C1D)),
    _SubjectColors(border: Color(0xFF993556), bg: Color(0xFFFBEAF0), title: Color(0xFF72243E), body: Color(0xFF993556)),
    _SubjectColors(border: Color(0xFF534AB7), bg: Color(0xFFEEEDFE), title: Color(0xFF3C3489), body: Color(0xFF534AB7)),
    _SubjectColors(border: Color(0xFF0F6E56), bg: Color(0xFFE1F5EE), title: Color(0xFF085041), body: Color(0xFF0F6E56)),
    _SubjectColors(border: Color(0xFFA32D2D), bg: Color(0xFFFCEBEB), title: Color(0xFF791F1F), body: Color(0xFFA32D2D)),
  ];

  static _SubjectColors of(int index) => palette[index < 0 ? 0 : index % palette.length];
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool loading;
  final _SubjectColors colors;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.loading, required this.colors, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: colors.border, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), maxLines: 2, style: TextStyle(color: colors.body, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.3, height: 1.15)),
                const SizedBox(height: 4),
                Text(
                  loading ? '—' : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.title, fontSize: value.length > 6 ? 15 : 19, fontWeight: FontWeight.w800, height: 1),
                ),
              ],
            ),
          ),
          Icon(icon, color: colors.border.withValues(alpha: 0.45), size: 17),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _SectionCard({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFF1A2E3A)),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A2E3A))),
              ],
            ),
          ),
          const Divider(height: 1),
          child,
        ],
      ),
    );
  }
}

/// Colored left accent, pastel background, subject-colored text —
/// same style as the teacher's Today rows (teacher name shown instead
/// of batch, since a student's batch is always the same).
class _ColoredClassRow extends StatelessWidget {
  final TimetableEntry entry;
  final _SubjectColors colors;
  const _ColoredClassRow({required this.entry, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: colors.bg,
        border: Border(left: BorderSide(color: colors.border, width: 3)),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(7), bottomRight: Radius.circular(7)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.subjectName, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colors.title)),
          const SizedBox(height: 2),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 5,
            children: [
              Text(entry.slotLabel, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: colors.body)),
              Text('·', style: TextStyle(fontSize: 10.5, color: colors.body)),
              Text(entry.roomDisplay, style: TextStyle(fontSize: 10.5, color: colors.body)),
              if (entry.teacherName != null) ...[
                Text('·', style: TextStyle(fontSize: 10.5, color: colors.body)),
                Text(entry.teacherName!, style: TextStyle(fontSize: 10.5, color: colors.body)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: const Color(0xFFE8F4FD), border: Border.all(color: const Color(0xFFB8D9F5)), borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF1A5A7A))),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? subtext;
  const _EmptyRow({required this.icon, required this.text, this.subtext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 30, color: const Color(0xFFC8D8E0)),
            const SizedBox(height: 10),
            Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFAABBC8))),
            if (subtext != null) ...[
              const SizedBox(height: 4),
              Text(subtext!, style: const TextStyle(fontSize: 11, color: Color(0xFFC8D8E0))),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), border: Border.all(color: const Color(0xFFFECACA)), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Expanded(child: Text(message, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12))),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}