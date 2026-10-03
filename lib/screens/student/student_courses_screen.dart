import 'package:flutter/material.dart';
import '../../core/api/timetable_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/timetable_entry.dart';

/// Mirrors StudentCourses from frontend/src/pages/student/StudentDashboard.js —
/// groups timetable entries by subject_id into course cards, each
/// showing the teacher, batch, and every scheduled slot for that
/// course. Cards stack in a single column on mobile (the website's
/// own auto-fill grid already collapses to 1 column at phone widths).
class StudentCoursesScreen extends StatefulWidget {
  const StudentCoursesScreen({super.key});

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
  List<TimetableEntry> _entries = [];
  bool _loading = true;
  String? _error;

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
        _error = 'Could not load your courses. Pull down to retry.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // One representative entry per subject_id, same as the web app's
    // `[...new Map(entries.map(e=>[e.subject_id,e])).values()]`.
    final seen = <int?>{};
    final courses = <TimetableEntry>[];
    for (final e in _entries) {
      if (seen.add(e.subjectId)) courses.add(e);
    }

    // Consistent color per course (same order as the dashboard).
    final subjectOrder = _entries.map((e) => e.subjectName).toSet().toList()..sort();
    int colorIndexFor(String name) => subjectOrder.indexOf(name);

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.navy,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          if (_error != null) _ErrorBanner(message: _error!, onRetry: _load),

          Row(
            children: [
              const Icon(Icons.menu_book_outlined, size: 17, color: Color(0xFF1A2E3A)),
              const SizedBox(width: 8),
              const Text('My Courses', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A2E3A))),
              const Spacer(),
              if (!_loading)
                Text(
                  '${courses.length} course${courses.length != 1 ? 's' : ''} enrolled',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFFAABBC8)),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (_loading)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: AppColors.navy)))
          else if (courses.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.menu_book_outlined, size: 36, color: Color(0xFFC8D8E0)),
                    SizedBox(height: 12),
                    Text('No courses found', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFAABBC8))),
                    SizedBox(height: 4),
                    Text('Contact your Office Assistant to enroll in courses.', style: TextStyle(fontSize: 11.5, color: Color(0xFFC8D8E0))),
                  ],
                ),
              ),
            )
          else
            for (final course in courses)
              _CourseCard(
                course: course,
                colors: _SubjectColors.of(colorIndexFor(course.subjectName)),
                slots: _entries.where((e) => e.subjectId == course.subjectId).toList()
                  ..sort((a, b) {
                    final d = TimetableEntry.weekDays.indexOf(a.day).compareTo(TimetableEntry.weekDays.indexOf(b.day));
                    return d != 0 ? d : a.timeSlot.compareTo(b.timeSlot);
                  }),
              ),
        ],
      ),
    );
  }
}

/// Same light pastel palette used across the app — a course keeps
/// its color on every screen.
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

class _CourseCard extends StatelessWidget {
  final TimetableEntry course;
  final List<TimetableEntry> slots;
  final _SubjectColors colors;
  const _CourseCard({required this.course, required this.slots, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border.withValues(alpha: 0.3), width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 4, color: colors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.subjectName, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: colors.title, height: 1.25)),
                const SizedBox(height: 8),
                _iconLine(Icons.person_outline, course.teacherName ?? 'No supervisor assigned'),
                const SizedBox(height: 4),
                _iconLine(Icons.grid_view_outlined, course.batchName ?? '-'),
                const SizedBox(height: 12),
                Divider(height: 1, color: colors.border.withValues(alpha: 0.2)),
                const SizedBox(height: 10),
                Text('SCHEDULE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colors.body, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Column(children: [for (final s in slots) _ScheduleLine(entry: s, colors: colors)]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconLine(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: colors.body),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: colors.body))),
      ],
    );
  }
}

class _ScheduleLine extends StatelessWidget {
  final TimetableEntry entry;
  final _SubjectColors colors;
  const _ScheduleLine({required this.entry, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 42,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: colors.border.withValues(alpha: 0.12),
              border: Border.all(color: colors.border.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              entry.day.substring(0, 3),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colors.title),
            ),
          ),
          const SizedBox(width: 8),
          Text(entry.slotLabel, style: TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: colors.title)),
          const SizedBox(width: 6),
          Expanded(
            child: Text('- ${entry.roomDisplay}', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: colors.body)),
          ),
          if (entry.isLab)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: colors.border.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(4)),
              child: Text('Lab', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: colors.title)),
            ),
        ],
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