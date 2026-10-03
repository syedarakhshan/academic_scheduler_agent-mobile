import 'package:flutter/material.dart';
import '../../core/api/batch_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/batch.dart';
import '../../models/timetable_entry.dart';

/// Batch Timetable grid — true 3-column spanning for labs, with a
/// light, minimal color per subject (pale tint background, dark
/// colored text) instead of solid dark fills.
class BatchTimetableScreen extends StatefulWidget {
  const BatchTimetableScreen({super.key});

  @override
  State<BatchTimetableScreen> createState() => _BatchTimetableScreenState();
}

class _BatchTimetableScreenState extends State<BatchTimetableScreen> {
  List<Batch> _batches = [];
  bool _loadingBatches = true;
  String? _batchesError;

  Batch? _selectedBatch;
  int _selectedSemester = 1;
  List<TimetableEntry> _entries = [];
  bool _loadingEntries = false;
  String? _entriesError;

  static const _weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  String get _today {
    final i = DateTime.now().weekday - 1;
    return i < 6 ? _weekdayNames[i] : 'Monday';
  }

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    setState(() {
      _loadingBatches = true;
      _batchesError = null;
    });
    try {
      final batches = await BatchService.instance.getBatches();
      if (!mounted) return;
      setState(() {
        _batches = batches;
        _loadingBatches = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _batchesError = 'Could not load batches.';
        _loadingBatches = false;
      });
    }
  }

  Future<void> _loadTimetable() async {
    if (_selectedBatch == null) return;
    setState(() {
      _loadingEntries = true;
      _entriesError = null;
    });
    try {
      final entries = await BatchService.instance.getBatchTimetable(batchId: _selectedBatch!.id, semester: _selectedSemester);
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loadingEntries = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _entriesError = 'Could not load the timetable for this batch.';
        _loadingEntries = false;
      });
    }
  }

  void _onSelectBatch(Batch? b) {
    setState(() {
      _selectedBatch = b;
      _entries = [];
    });
    if (b != null) _loadTimetable();
  }

  void _onSelectSemester(int s) {
    if (s == _selectedSemester) return;
    setState(() => _selectedSemester = s);
    _loadTimetable();
  }

  @override
  Widget build(BuildContext context) {
    final subjectOrder = _entries.map((e) => e.subjectName).toSet().toList()..sort();
    int colorIndexFor(String name) => subjectOrder.indexOf(name);

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.groups_outlined, size: 16, color: Color(0xFF1A2E3A)),
                  SizedBox(width: 8),
                  Text('Batch Timetable', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A2E3A))),
                ]),
                const SizedBox(height: 16),
                Text('SELECT BATCH', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                if (_batchesError != null)
                  _ErrorBanner(message: _batchesError!, onRetry: _loadBatches)
                else
                  _BatchDropdown(batches: _batches, selected: _selectedBatch, loading: _loadingBatches, onChanged: _onSelectBatch),
                if (_selectedBatch != null) ...[
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _StatBox(label: 'Batch', value: _selectedBatch!.batchName)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatBox(label: 'Total Classes', value: '${_entries.length}')),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Text('SESSION', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5)),
                    const SizedBox(width: 10),
                    _SessionButton(label: 'Session 1', selected: _selectedSemester == 1, onTap: () => _onSelectSemester(1)),
                    const SizedBox(width: 6),
                    _SessionButton(label: 'Session 2', selected: _selectedSemester == 2, onTap: () => _onSelectSemester(2)),
                  ]),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_selectedBatch == null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(children: [
                  Icon(Icons.groups_outlined, size: 36, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  const Text('Select a batch to view its timetable', style: TextStyle(fontSize: 13, color: Color(0xFFAABBC8), fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          )
        else if (_entriesError != null)
          _ErrorBanner(message: _entriesError!, onRetry: _loadTimetable)
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF1A2E3A)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${_selectedBatch!.batchName} — Session $_selectedSemester Schedule',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A2E3A))),
                    ),
                  ]),
                ),
                const Divider(height: 1),
                if (_loadingEntries)
                  const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator(color: AppColors.navy)))
                else if (_entries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No classes scheduled for this batch yet.', style: TextStyle(fontSize: 13, color: Color(0xFFAABBC8)))),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                    child: _WeekGrid(entries: _entries, today: _today, colorIndexFor: colorIndexFor),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Same light pastel palette used across the app now.
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

class _WeekGrid extends StatelessWidget {
  final List<TimetableEntry> entries;
  final String today;
  final int Function(String) colorIndexFor;
  const _WeekGrid({required this.entries, required this.today, required this.colorIndexFor});

  static const double dayColWidth = 64;
  static const double slotColWidth = 116;
  static const double rowHeight = 80;

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
        Row(children: [
          _HeaderCell(width: dayColWidth, text: 'DAY'),
          for (final s in slots) _HeaderCell(width: slotColWidth, text: slotLabels[s]!),
        ]),
        for (final day in TimetableEntry.weekDays) _DayRow(day: day, today: today, slots: slots, byCell: byCell, colorIndexFor: colorIndexFor),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  final String day;
  final String today;
  final List<int> slots;
  final Map<String, TimetableEntry> byCell;
  final int Function(String) colorIndexFor;
  const _DayRow({required this.day, required this.today, required this.slots, required this.byCell, required this.colorIndexFor});

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
        cells.add(_GridCell(width: slotColWidth, height: rowHeight, entry: null, colors: null));
        i++;
        continue;
      }
      final span = entry.isLab ? (slots.length - i).clamp(1, 3) : 1;
      final colors = SubjectColors.of(colorIndexFor(entry.subjectName));
      cells.add(_GridCell(width: slotColWidth * span, height: rowHeight, entry: entry, colors: colors));
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
          child: Text(day.substring(0, 3), textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: day == today ? AppColors.navy : const Color(0xFF5A7080))),
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
  const _GridCell({required this.width, required this.height, required this.entry, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(border: Border(right: BorderSide(color: Color(0xFFE0E8ED)), bottom: BorderSide(color: Color(0xFFE0E8ED)))),
      child: entry == null
          ? const SizedBox.shrink()
          : Container(
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
            Text(entry!.shortName ?? entry!.subjectName, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: colors!.title)),
            const SizedBox(height: 2),
            if (entry!.teacherName != null)
              Text(entry!.teacherName!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: colors!.body)),
            Row(children: [
              Flexible(child: Text(entry!.roomDisplay, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: colors!.body))),
              if (entry!.isLab) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: colors!.border.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(4)),
                  child: Text('Lab 3h', style: TextStyle(fontSize: 8.5, color: colors!.title, fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
          ],
        ),
      ),
    );
  }
}

class _BatchDropdown extends StatelessWidget {
  final List<Batch> batches;
  final Batch? selected;
  final bool loading;
  final ValueChanged<Batch?> onChanged;
  const _BatchDropdown({required this.batches, required this.selected, required this.loading, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFA9BAC4), width: 1.2), borderRadius: BorderRadius.circular(8), color: Colors.white),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selected?.id,
          isExpanded: true,
          hint: Text(loading ? 'Loading batches…' : '-- Choose a batch --', style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13.5, color: Color(0xFF8FA5B0))),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF5A7080)),
          style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13.5, color: Color(0xFF1A2E3A)),
          items: [
            for (final major in Major.all) ...[
              if (batches.any(major.matches))
                DropdownMenuItem<int>(
                  enabled: false,
                  child: Text(major.label, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF5A7080))),
                ),
              for (final b in batches.where(major.matches))
                DropdownMenuItem<int>(
                  value: b.id,
                  child: Padding(padding: const EdgeInsets.only(left: 10), child: Text(b.batchName, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13.5, color: Color(0xFF1A2E3A)))),
                ),
            ],
          ],
          onChanged: (id) => onChanged(id == null ? null : batches.firstWhere((b) => b.id == id)),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFF5F8FA), border: Border.all(color: const Color(0xFFE0E8ED)), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.4)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A2E3A))),
        ],
      ),
    );
  }
}

class _SessionButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SessionButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : Colors.white,
          border: Border.all(color: selected ? AppColors.navy : const Color(0xFFC8D8E0)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: selected ? Colors.white : const Color(0xFF4A6070))),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), border: Border.all(color: const Color(0xFFFECACA)), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Expanded(child: Text(message, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12))),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ]),
    );
  }
}