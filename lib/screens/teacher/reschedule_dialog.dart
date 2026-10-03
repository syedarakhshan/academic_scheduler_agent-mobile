import 'package:flutter/material.dart';
import '../../core/api/timetable_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/timetable_entry.dart';

/// Mirrors the "Request Reschedule" modal shown on the web app's
/// My Schedule page. Submits to the same endpoint (goes to the
/// Office Assistant for approval — nothing changes immediately).
class RescheduleDialog extends StatefulWidget {
  final TimetableEntry entry;
  const RescheduleDialog({super.key, required this.entry});

  @override
  State<RescheduleDialog> createState() => _RescheduleDialogState();
}

class _RescheduleDialogState extends State<RescheduleDialog> {
  late String _newDay;
  late int _newSlot;
  final _reasonController = TextEditingController();
  bool _submitting = false;
  String? _error;

  Map<int, String> get _slotLabels =>
      widget.entry.isLab ? TimetableEntry.labSlotLabels : TimetableEntry.slotLabels;

  @override
  void initState() {
    super.initState();
    _newDay = widget.entry.day;
    _newSlot = widget.entry.timeSlot;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final message = await TimetableService.instance.submitRescheduleRequest(
        timetableId: widget.entry.id,
        newDay: _newDay,
        newTimeSlot: _newSlot,
        reason: _reasonController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not submit the request. Please try again.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                decoration: const BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request Reschedule',
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Sent to Office Assistant for approval',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Current schedule ─────────────────────────
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F8FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CURRENT SCHEDULE',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.entry.subjectName,
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF1A2E3A)),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${widget.entry.day}   ${widget.entry.slotLabel}   ${widget.entry.roomDisplay}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _Label('New Day'),
                    const SizedBox(height: 5),
                    _Dropdown<String>(
                      value: _newDay,
                      items: TimetableEntry.weekDays,
                      labelOf: (d) => d,
                      onChanged: (v) => setState(() => _newDay = v!),
                    ),
                    const SizedBox(height: 14),

                    _Label('New Time'),
                    const SizedBox(height: 5),
                    _Dropdown<int>(
                      value: _newSlot,
                      items: _slotLabels.keys.toList(),
                      labelOf: (s) => _slotLabels[s] ?? 'Slot $s',
                      onChanged: (v) => setState(() => _newSlot = v!),
                    ),
                    const SizedBox(height: 14),

                    _Label('Reason (optional)'),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _reasonController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. Departmental meeting conflict...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF8FA5B0)),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFA9BAC4), width: 1.2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFA9BAC4), width: 1.2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF4A90D9), width: 1.6),
                        ),
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(_error!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12)),
                    ],

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: _submitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.navy,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                                  : const Text('Submit Request', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF5A7080),
                              side: const BorderSide(color: Color(0xFFDDE3E8)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14),
                              child: Text('Cancel', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF5A7080), letterSpacing: 0.4),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;

  const _Dropdown({required this.value, required this.items, required this.labelOf, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFA9BAC4), width: 1.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF5A7080)),
          style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13.5, color: Color(0xFF1A2E3A)),
          items: [
            for (final item in items)
              DropdownMenuItem(
                value: item,
                child: Text(labelOf(item), style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13.5, color: Color(0xFF1A2E3A))),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}