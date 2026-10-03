import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/timetable_service.dart';
import '../../core/pdf/timetable_pdf_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/timetable_entry.dart';
import '../../providers/auth_provider.dart';
import 'reschedule_dialog.dart';

enum _ViewMode { list, grid }

/// My Schedule — two views you can switch between:
///  • List: grouped DAY-WISE (Monday's classes, Tuesday's classes, ...),
///    each class colored by subject, with a Reschedule button.
///  • Grid: day x time-slot grid (same as the student timetable) where a
///    3-hour lab spans 3 columns. Tap any class to request a reschedule.
/// "Export PDF" works from either view.
class TeacherScheduleScreen extends StatefulWidget {
  const TeacherScheduleScreen({super.key});

  @override
  State<TeacherScheduleScreen> createState() => _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends State<TeacherScheduleScreen> {
  List<TimetableEntry> _entries = [];
  bool _loading = true;
  bool _exporting = false;
  String? _error;
  _ViewMode _mode = _ViewMode.list;

  static const _weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
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

  Future<void> _openReschedule(TimetableEntry entry) async {
    final result = await showDialog<String>(context: context, builder: (_) => RescheduleDialog(entry: entry));
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result), backgroundColor: AppColors.navy));
      _load();
    }
  }

  Future<void> _exportPdf() async {
    if (_exporting || _entries.isEmpty) return;
    setState(() => _exporting = true);
    try {
      final user = context.read<AuthProvider>().user;
      await TimetablePdfService.exportAndShare(
        personName: user?.fullName ?? 'Teacher',
        department: user?.departmentName ?? 'CS & SE Department',
        batchName: '',
        entries: _entries,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not generate the PDF. Please try again.'), backgroundColor: Color(0xFFDC2626)),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Consistent color per subject across the whole screen.
    final subjectOrder = _entries.map((e) => e.subjectName).toSet().toList()..sort();
    int colorIndexFor(String name) => subjectOrder.indexOf(name);

    final allSorted = List<TimetableEntry>.from(_entries)
      ..sort((a, b) {
        final d = TimetableEntry.weekDays.indexOf(a.day).compareTo(TimetableEntry.weekDays.indexOf(b.day));
        return d != 0 ? d : a.timeSlot.compareTo(b.timeSlot);
      });

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.navy,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        children: [
          if (_error != null) _ErrorBanner(message: _error!, onRetry: _load),

          Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF1A2E3A)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('My Weekly Schedule', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A2E3A))),
            ),
            ElevatedButton.icon(
              onPressed: (_exporting || _loading || _entries.isEmpty) ? null : _exportPdf,
              icon: _exporting
                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.download_outlined, size: 14),
              label: Text(_exporting ? 'Preparing…' : 'Export PDF', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                disabledBackgroundColor: const Color(0xFF6B8794),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                elevation: 0,
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            _mode == _ViewMode.list
                ? 'Tap Reschedule next to any class to request a change.'
                : 'Tap any class to request a change.',
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF8FA5B0)),
          ),
          const SizedBox(height: 10),

          _ViewToggle(mode: _mode, onChanged: (m) => setState(() => _mode = m)),
          const SizedBox(height: 12),

          if (_loading)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: AppColors.navy)))
          else if (_mode == _ViewMode.list) ...[
            for (final day in TimetableEntry.weekDays)
              _DayCard(
                day: day,
                isToday: day == _today,
                entries: (allSorted.where((e) => e.day == day).toList()),
                colorIndexFor: colorIndexFor,
                onReschedule: _openReschedule,
              ),
            const SizedBox(height: 4),
          ] else
            Card(
              clipBehavior: Clip.antiAlias,
              child: _entries.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No classes scheduled yet.', style: TextStyle(fontSize: 13, color: Color(0xFFAABBC8)))),
              )
                  : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                child: _WeekGrid(
                  entries: _entries,
                  today: _today,
                  colorIndexFor: colorIndexFor,
                  onTapEntry: _openReschedule,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// List / Grid switch shown under the header.
class _ViewToggle extends StatelessWidget {
  final _ViewMode mode;
  final ValueChanged<_ViewMode> onChanged;
  const _ViewToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<_ViewMode>(
        segments: const [
          ButtonSegment(
            value: _ViewMode.list,
            icon: Icon(Icons.view_agenda_outlined, size: 16),
            label: Text('List', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          ButtonSegment(
            value: _ViewMode.grid,
            icon: Icon(Icons.grid_view_outlined, size: 16),
            label: Text('Grid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
        selected: {mode},
        showSelectedIcon: false,
        onSelectionChanged: (s) => onChanged(s.first),
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected) ? AppColors.navy : Colors.white,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected) ? Colors.white : AppColors.navy,
          ),
        ),
      ),
    );
  }
}

/// Shared light pastel palette used across all timetable screens.
class SubjectColors {
  final Color border;
  final Color bg;
  final Color title;
  final Color body;
  const SubjectColors({required this.border, required this.bg, required this.title, required this.body});

  static const palette = [
    SubjectColors(border: Color(0xFF185FA5), bg: Color(0xFFE6F1FB), title: Color(0xFF0C447C), body: Color(0xFF185FA5)),
    SubjectColors(border: Color(0xFF854F0B), bg: Color(0xFFFAEEDA), title: Color(0xFF633806), body: Color(0xFF854F0B)),
    SubjectColors(border: Color(0xFF3B6D11), bg: Color(0xFFEAF3DE), title: Color(0xFF27500A), body: Color(0xFF3B6D11)),
    SubjectColors(border: Color(0xFF993C1D), bg: Color(0xFFFAECE7), title: Color(0xFF712B13), body: Color(0xFF993C1D)),
    SubjectColors(border: Color(0xFF993556), bg: Color(0xFFFBEAF0), title: Color(0xFF72243E), body: Color(0xFF993556)),
    SubjectColors(border: Color(0xFF534AB7), bg: Color(0xFFEEEDFE), title: Color(0xFF3C3489), body: Color(0xFF534AB7)),
    SubjectColors(border: Color(0xFF0F6E56), bg: Color(0xFFE1F5EE), title: Color(0xFF085041), body: Color(0xFF0F6E56)),
    SubjectColors(border: Color(0xFFA32D2D), bg: Color(0xFFFCEBEB), title: Color(0xFF791F1F), body: Color(0xFFA32D2D)),
  ];

  static SubjectColors of(int index) => palette[index < 0 ? 0 : index % palette.length];
}

// ─────────────────────────── LIST VIEW ───────────────────────────

class _DayCard extends StatelessWidget {
  final String day;
  final bool isToday;
  final List<TimetableEntry> entries;
  final int Function(String) colorIndexFor;
  final ValueChanged<TimetableEntry> onReschedule;
  const _DayCard({required this.day, required this.isToday, required this.entries, required this.colorIndexFor, required this.onReschedule});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            color: isToday ? const Color(0xFFE8F4FD) : const Color(0xFFF7F9FA),
            child: Row(
              children: [
                Text(day, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isToday ? AppColors.navy : const Color(0xFF3D5A6A))),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(4)),
                    child: const Text('Today', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ],
                const Spacer(),
                Text('${entries.length} class${entries.length != 1 ? 'es' : ''}', style: const TextStyle(fontSize: 11, color: Color(0xFF8FA5B0))),
              ],
            ),
          ),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('No classes', style: TextStyle(fontSize: 12, color: Color(0xFFC8D8E0)))),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(children: [for (final e in entries) _DayEntryRow(entry: e, colors: SubjectColors.of(colorIndexFor(e.subjectName)), onReschedule: () => onReschedule(e))]),
            ),
        ],
      ),
    );
  }
}

class _DayEntryRow extends StatelessWidget {
  final TimetableEntry entry;
  final SubjectColors colors;
  final VoidCallback onReschedule;
  const _DayEntryRow({required this.entry, required this.colors, required this.onReschedule});

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
      child: Row(
        children: [
          Expanded(
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
                    if (entry.batchName != null) ...[
                      Text('·', style: TextStyle(fontSize: 10.5, color: colors.body)),
                      Text(entry.batchName!, style: TextStyle(fontSize: 10.5, color: colors.body)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_calendar_outlined, size: 16, color: colors.border),
            onPressed: onReschedule,
            tooltip: 'Reschedule',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── GRID VIEW ───────────────────────────

/// Day x time-slot grid with true column-spanning: a 3-hour lab
/// occupies one wide cell across 3 columns instead of repeating in
/// each one. Same layout as the student timetable.
class _WeekGrid extends StatelessWidget {
  final List<TimetableEntry> entries;
  final String today;
  final int Function(String) colorIndexFor;
  final ValueChanged<TimetableEntry> onTapEntry;
  const _WeekGrid({required this.entries, required this.today, required this.colorIndexFor, required this.onTapEntry});

  static const double dayColWidth = 66;
  static const double slotColWidth = 112;
  static const double rowHeight = 78;

  @override
  Widget build(BuildContext context) {
    final slots = TimetableEntry.slotLabels.keys.toList()..sort();
    final slotLabels = TimetableEntry.slotLabels;

    final byCell = <String, TimetableEntry>{};
    for (final e in entries) {
      byCell['${e.day}_${e.timeSlot}'] = e;
    }

    return Column(
      children: [
        Row(
          children: [
            const _HeaderCell(width: dayColWidth, text: 'DAY'),
            for (final s in slots) _HeaderCell(width: slotColWidth, text: slotLabels[s]!),
          ],
        ),
        for (final day in TimetableEntry.weekDays)
          _GridDayRow(day: day, today: today, slots: slots, byCell: byCell, colorIndexFor: colorIndexFor, onTapEntry: onTapEntry),
      ],
    );
  }
}

class _GridDayRow extends StatelessWidget {
  final String day;
  final String today;
  final List<int> slots;
  final Map<String, TimetableEntry> byCell;
  final int Function(String) colorIndexFor;
  final ValueChanged<TimetableEntry> onTapEntry;
  const _GridDayRow({
    required this.day,
    required this.today,
    required this.slots,
    required this.byCell,
    required this.colorIndexFor,
    required this.onTapEntry,
  });

  static const double dayColWidth = _WeekGrid.dayColWidth;
  static const double slotColWidth = _WeekGrid.slotColWidth;
  static const double rowHeight = _WeekGrid.rowHeight;

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[];
    int i = 0;
    while (i < slots.length) {
      final slot = slots[i];
      final entry = byCell['${day}_$slot'];

      if (entry == null) {
        cells.add(const _GridCell(width: slotColWidth, height: rowHeight, entry: null, colors: null));
        i++;
        continue;
      }

      final span = entry.isLab ? (slots.length - i).clamp(1, 3) : 1;
      final colors = SubjectColors.of(colorIndexFor(entry.subjectName));
      cells.add(_GridCell(
        width: slotColWidth * span,
        height: rowHeight,
        entry: entry,
        colors: colors,
        onTap: () => onTapEntry(entry),
      ));
      i += span;
    }

    return Row(
      children: [
        Container(
          width: dayColWidth,
          height: rowHeight,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: day == today ? const Color(0xFFE8F4FD) : const Color(0xFFF5F8FA),
            border: const Border(right: BorderSide(color: Color(0xFFE0E8ED)), bottom: BorderSide(color: Color(0xFFE0E8ED))),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                day.substring(0, 3),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: day == today ? AppColors.navy : const Color(0xFF5A7080)),
              ),
              if (day == today)
                const Text('Today', style: TextStyle(fontSize: 8.5, color: AppColors.navy, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        ...cells,
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final double width;
  final String text;
  const _HeaderCell({required this.width, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 34,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.navy, border: Border(right: BorderSide(color: Color(0xFF3D5A6A)))),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }
}

class _GridCell extends StatelessWidget {
  final double width;
  final double height;
  final TimetableEntry? entry;
  final SubjectColors? colors;
  final VoidCallback? onTap;
  const _GridCell({required this.width, required this.height, required this.entry, required this.colors, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(border: Border(right: BorderSide(color: Color(0xFFE0E8ED)), bottom: BorderSide(color: Color(0xFFE0E8ED)))),
      child: entry == null
          ? const SizedBox.shrink()
          : GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: colors!.bg,
            borderRadius: BorderRadius.circular(6),
            border: Border(left: BorderSide(color: colors!.border, width: 3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry!.shortName ?? entry!.subjectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: colors!.title)),
              const SizedBox(height: 2),
              if (entry!.batchName != null)
                Text(entry!.batchName!,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: colors!.body)),
              Row(
                children: [
                  Flexible(
                      child: Text(entry!.roomDisplay,
                          overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: colors!.body))),
                  if (entry!.isLab) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: colors!.border.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(4)),
                      child: Text('Lab 3h', style: TextStyle(fontSize: 8.5, color: colors!.title, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── SHARED ───────────────────────────

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
      child: Row(children: [
        Expanded(child: Text(message, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12))),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ]),
    );
  }
}