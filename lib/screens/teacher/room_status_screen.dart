import 'package:flutter/material.dart';
import '../../core/api/room_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/room_info.dart';
import '../../models/timetable_entry.dart';
import 'batch_timetable_screen.dart' show SubjectColors;

/// Mirrors RoomStatusPage from frontend/src/pages/teacher/TeacherDashboard.js —
/// pick a room, see capacity/availability, and its weekly schedule grid.
///
/// The grid here has to handle two things a personal schedule doesn't:
/// a 3-hour lab must SPAN 3 time columns (not just sit in its start
/// slot), AND a single slot can have multiple different classes
/// (e.g. across different sessions) that need to STACK inside that
/// spanned cell without overflowing. Row height is computed per day
/// based on the tallest stack actually present that day.
class RoomStatusScreen extends StatefulWidget {
  const RoomStatusScreen({super.key});

  @override
  State<RoomStatusScreen> createState() => _RoomStatusScreenState();
}

class _RoomStatusScreenState extends State<RoomStatusScreen> {
  List<RoomInfo> _rooms = [];
  bool _loadingRooms = true;
  String? _roomsError;

  RoomInfo? _selectedRoom;
  List<TimetableEntry> _entries = [];
  bool _loadingEntries = false;
  String? _entriesError;

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
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _loadingRooms = true;
      _roomsError = null;
    });
    try {
      final rooms = await RoomService.instance.getRooms();
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _loadingRooms = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _roomsError = 'Could not load rooms.';
        _loadingRooms = false;
      });
    }
  }

  Future<void> _loadSchedule() async {
    if (_selectedRoom == null) return;
    setState(() {
      _loadingEntries = true;
      _entriesError = null;
    });
    try {
      final entries = await RoomService.instance.getRoomSchedule(roomId: _selectedRoom!.id);
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loadingEntries = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _entriesError = 'Could not load the schedule for this room.';
        _loadingEntries = false;
      });
    }
  }

  void _onSelectRoom(RoomInfo? r) {
    setState(() {
      _selectedRoom = r;
      _entries = [];
    });
    if (r != null) _loadSchedule();
  }

  @override
  Widget build(BuildContext context) {
    // Consistent color per course/subject across the whole grid.
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
                const Row(
                  children: [
                    Icon(Icons.apartment_outlined, size: 16, color: Color(0xFF1A2E3A)),
                    SizedBox(width: 8),
                    Text('Room Status & Schedule', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A2E3A))),
                  ],
                ),
                const SizedBox(height: 16),

                Text('SELECT ROOM', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                if (_roomsError != null)
                  _ErrorBanner(message: _roomsError!, onRetry: _loadRooms)
                else
                  _RoomDropdown(rooms: _rooms, selected: _selectedRoom, loading: _loadingRooms, onChanged: _onSelectRoom),

                if (_selectedRoom != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _StatBox(label: 'Capacity', value: '${_selectedRoom!.capacity} students')),
                      const SizedBox(width: 10),
                      Expanded(child: _StatusBox(available: _selectedRoom!.isAvailable)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        if (_selectedRoom == null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.apartment_outlined, size: 36, color: Colors.grey.shade300),
                    const SizedBox(height: 10),
                    const Text('Select a room to view its schedule', style: TextStyle(fontSize: 13, color: Color(0xFFAABBC8), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          )
        else if (_entriesError != null)
          _ErrorBanner(message: _entriesError!, onRetry: _loadSchedule)
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: [
                      const Icon(Icons.apartment_outlined, size: 15, color: Color(0xFF1A2E3A)),
                      const SizedBox(width: 8),
                      Text('${_selectedRoom!.roomId} — Weekly Schedule',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A2E3A))),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (_loadingEntries)
                  const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator(color: AppColors.navy)))
                else if (_entries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No classes scheduled in this room yet.', style: TextStyle(fontSize: 13, color: Color(0xFFAABBC8)))),
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

class _RoomDropdown extends StatelessWidget {
  final List<RoomInfo> rooms;
  final RoomInfo? selected;
  final bool loading;
  final ValueChanged<RoomInfo?> onChanged;
  const _RoomDropdown({required this.rooms, required this.selected, required this.loading, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFA9BAC4), width: 1.2),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selected?.id,
          isExpanded: true,
          hint: Text(loading ? 'Loading rooms…' : '-- Choose a room --', style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13.5, color: Color(0xFF8FA5B0))),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF5A7080)),
          style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13.5, color: Color(0xFF1A2E3A)),
          items: [
            for (final r in rooms)
              DropdownMenuItem<int>(
                value: r.id,
                child: Text(r.display, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13.5, color: Color(0xFF1A2E3A))),
              ),
          ],
          onChanged: (id) => onChanged(id == null ? null : rooms.firstWhere((r) => r.id == id)),
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

class _StatusBox extends StatelessWidget {
  final bool available;
  const _StatusBox({required this.available});

  @override
  Widget build(BuildContext context) {
    final bg = available ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2);
    final border = available ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5);
    final text = available ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: bg, border: Border.all(color: border), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('STATUS', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: text.withValues(alpha: 0.8), letterSpacing: 0.4)),
          const SizedBox(height: 3),
          Text(available ? 'Available' : 'Occupied', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: text)),
        ],
      ),
    );
  }
}

/// Day x time grid with TRUE column-spanning for labs (a 3-hour lab
/// occupies one wide cell across its 3 columns, matching the
/// website), combined with vertical stacking for the rare case where
/// multiple different classes start in the very same slot. Row
/// height is computed per day from the tallest stack that day
/// actually has, so nothing overflows regardless of how many
/// entries land in one cell.
class _WeekGrid extends StatelessWidget {
  final List<TimetableEntry> entries;
  final String today;
  final int Function(String) colorIndexFor;
  const _WeekGrid({required this.entries, required this.today, required this.colorIndexFor});

  static const double dayColWidth = 64;
  static const double slotColWidth = 118;
  static const double baseRowHeight = 72;

  @override
  Widget build(BuildContext context) {
    final slots = TimetableEntry.slotLabels.keys.toList()..sort();
    final slotLabels = TimetableEntry.slotLabels;

    // (day, startSlot) -> the classes that start there. The same class
    // (same subject + teacher) taught to several batches at once comes
    // back as one row per batch, so those rows are merged into ONE
    // group that lists all its batches.
    final byCell = <String, List<_ClassGroup>>{};
    for (final e in entries) {
      final cell = byCell.putIfAbsent('${e.day}_${e.timeSlot}', () => []);
      final idx = cell.indexWhere((g) => g.matches(e));
      if (idx == -1) {
        cell.add(_ClassGroup(e));
      } else {
        cell[idx].addBatch(e.batchName);
      }
    }

    return Column(
      children: [
        Row(
          children: [
            _HeaderCell(width: dayColWidth, text: 'DAY'),
            for (final s in slots) _HeaderCell(width: slotColWidth, text: slotLabels[s]!),
          ],
        ),
        for (final day in TimetableEntry.weekDays) _DayRow(day: day, today: today, slots: slots, byCell: byCell, colorIndexFor: colorIndexFor),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  final String day;
  final String today;
  final List<int> slots;
  final Map<String, List<_ClassGroup>> byCell;
  final int Function(String) colorIndexFor;
  const _DayRow({required this.day, required this.today, required this.slots, required this.byCell, required this.colorIndexFor});

  static const double dayColWidth = _WeekGrid.dayColWidth;
  static const double slotColWidth = _WeekGrid.slotColWidth;

  @override
  Widget build(BuildContext context) {
    // Build this day's cells first (spanning groups), then size the
    // row to whichever cell has the most stacked entries.
    final cellSpecs = <({double width, List<_ClassGroup> group})>[];
    int i = 0;
    while (i < slots.length) {
      final slot = slots[i];
      final group = byCell['${day}_$slot'] ?? const <_ClassGroup>[];

      if (group.isEmpty) {
        cellSpecs.add((width: slotColWidth, group: const []));
        i++;
        continue;
      }

      final maxSpanNeeded = group.map((g) => g.entry.isLab ? 3 : 1).reduce((a, b) => a > b ? a : b);
      final span = maxSpanNeeded.clamp(1, slots.length - i);
      cellSpecs.add((width: slotColWidth * span, group: group));
      i += span;
    }

    // Row height = what the tallest cell really needs (its tiles'
    // content + padding), never less than the base height. This is
    // what stops the "bottom overflowed" error.
    final scaler = MediaQuery.textScalerOf(context);
    double tallest = 0;
    for (final c in cellSpecs) {
      final h = 6 + c.group.fold<double>(0, (sum, g) => sum + _GridCell.neededHeight(g, scaler));
      if (h > tallest) tallest = h;
    }
    final rowHeight = tallest > _WeekGrid.baseRowHeight ? tallest : _WeekGrid.baseRowHeight;

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
          child: Text(
            day.substring(0, 3),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: day == today ? AppColors.navy : const Color(0xFF5A7080)),
          ),
        ),
        for (final spec in cellSpecs) _GridCell(width: spec.width, height: rowHeight, entries: spec.group, colorIndexFor: colorIndexFor),
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
  final List<_ClassGroup> entries;
  final int Function(String) colorIndexFor;
  const _GridCell({required this.width, required this.height, required this.entries, required this.colorIndexFor});

  /// Height one tile needs: its vertical padding + margin + one line
  /// per piece of text it shows (scaled for the user's font size).
  static double neededHeight(_ClassGroup g, TextScaler scaler) {
    double line(double size, [double mult = 1.15]) => scaler.scale(size) * mult;
    double total = 8 + 2 + 2; // padding + margin + small safety gap
    total += line(10.5);
    if (g.entry.teacherName != null) total += line(9);
    total += g.batches.length * line(9); // one line per batch
    if (g.entry.isLab) total += 2 + 2 + line(8, 1.4);
    return total;
  }

  Widget _buildTile(BuildContext context, _ClassGroup g) {
    final e = g.entry;
    final colors = SubjectColors.of(colorIndexFor(e.subjectName));
    final needed = neededHeight(g, MediaQuery.textScalerOf(context));
    return Expanded(
      flex: needed.ceil(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color: colors.bg,
          borderRadius: BorderRadius.circular(6),
          border: Border(left: BorderSide(color: colors.border, width: 3)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(e.shortName ?? e.subjectName, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: colors.title, height: 1.15)),
            if (e.teacherName != null)
              Text(e.teacherName!, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9, color: colors.body, height: 1.15)),
            for (final b in g.batches)
              Text(b, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9, color: colors.body, height: 1.15)),
            if (e.isLab)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: colors.border.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(4)),
                child: Text('Lab 3h', style: TextStyle(fontSize: 8, color: colors.title, fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(border: Border(right: BorderSide(color: Color(0xFFE0E8ED)), bottom: BorderSide(color: Color(0xFFE0E8ED)))),
      child: entries.isEmpty
          ? const SizedBox.shrink()
          : Column(
        children: [
          for (final g in entries) _buildTile(context, g),
        ],
      ),
    );
  }
}

/// One class in a grid cell. If the same class (same subject and
/// teacher) is taught to several batches together, the API returns a
/// separate row per batch — this collects them so the cell shows the
/// class once, with all of its batches listed underneath.
class _ClassGroup {
  final TimetableEntry entry;
  final List<String> batches = [];

  _ClassGroup(this.entry) {
    addBatch(entry.batchName);
  }

  bool matches(TimetableEntry e) =>
      e.subjectName == entry.subjectName && e.teacherName == entry.teacherName && e.isLab == entry.isLab;

  void addBatch(String? name) {
    if (name != null && !batches.contains(name)) {
      batches.add(name);
      batches.sort();
    }
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
      child: Row(
        children: [
          Expanded(child: Text(message, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12))),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}