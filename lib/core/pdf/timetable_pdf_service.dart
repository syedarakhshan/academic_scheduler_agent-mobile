import 'dart:math' as math;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/timetable_entry.dart';

/// Builds a 2-page PDF (weekly grid + class list), matching the look of
/// the in-app timetable: a light pastel color per subject, a colored
/// left edge on each class, and 3-hour labs spanning 3 columns.
/// The file is handed to the OS share sheet via `printing` so the user
/// can save it, send it, or print it.
class TimetablePdfService {
  TimetablePdfService._();

  static const double _dayColW = 70;
  static const double _rowH = 50;
  static const double _headerH = 22;

  static Future<void> exportAndShare({
    required String personName,
    required String department,
    required String? batchName,
    required List<TimetableEntry> entries,
  }) async {
    final doc = pw.Document();
    final now = DateTime.now();
    final generatedOn = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    final byCell = <String, TimetableEntry>{};
    for (final e in entries) {
      byCell['${e.day}_${e.timeSlot}'] = e;
    }
    final slots = TimetableEntry.slotLabels.keys.toList()..sort();

    // Same rule as the app screens: subjects sorted A-Z, color by position.
    final subjectNames = entries.map((e) => e.subjectName).toSet().toList()..sort();
    _SubjectPdfColors colorsFor(String name) => _SubjectPdfColors.of(subjectNames.indexOf(name));

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => _buildGridPage(
          personName: personName,
          department: department,
          generatedOn: generatedOn,
          slots: slots,
          byCell: byCell,
          subjectNames: subjectNames,
          colorsFor: colorsFor,
        ),
      ),
    );

    final sorted = List<TimetableEntry>.from(entries)
      ..sort((a, b) {
        final d = TimetableEntry.weekDays.indexOf(a.day).compareTo(TimetableEntry.weekDays.indexOf(b.day));
        return d != 0 ? d : a.timeSlot.compareTo(b.timeSlot);
      });

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [_buildListPage(personName: personName, entries: sorted, colorsFor: colorsFor)],
      ),
    );

    final bytes = await doc.save();
    final safeName = personName.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    await Printing.sharePdf(bytes: bytes, filename: '${safeName}_My_Timetable.pdf');
  }

  // ───────────────────────── GRID PAGE ─────────────────────────

  static pw.Widget _buildGridPage({
    required String personName,
    required String department,
    required String generatedOn,
    required List<int> slots,
    required Map<String, TimetableEntry> byCell,
    required List<String> subjectNames,
    required _SubjectPdfColors Function(String) colorsFor,
  }) {
    final navy = PdfColor.fromInt(0xFF2D4A5A);
    final lightBorder = PdfColor.fromInt(0xFFE0E8ED);

    // A4 landscape width minus the 24pt margins on both sides.
    final contentWidth = PdfPageFormat.a4.landscape.width - 48;
    final slotW = slots.isEmpty ? 100.0 : (contentWidth - _dayColW - 2) / slots.length;

    final edge = pw.BorderSide(color: lightBorder, width: 0.6);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('$personName - My Timetable', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: navy)),
        pw.SizedBox(height: 3),
        pw.Text('$department · Generated $generatedOn', style: pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF7A9AAA))),
        pw.SizedBox(height: 14),
        pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border(left: edge, top: edge)),
          child: pw.Column(
            children: [
              pw.Row(
                children: [
                  _headerCell('DAY', _dayColW, navy),
                  for (final s in slots) _headerCell(TimetableEntry.slotLabels[s]!, slotW, navy),
                ],
              ),
              for (final day in TimetableEntry.weekDays)
                _gridRow(day, slots, byCell, slotW, edge, colorsFor),
            ],
          ),
        ),
        if (subjectNames.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          _legend(subjectNames, colorsFor),
        ],
      ],
    );
  }

  static pw.Widget _headerCell(String text, double width, PdfColor navy) => pw.Container(
    width: width,
    height: _headerH,
    alignment: pw.Alignment.center,
    decoration: pw.BoxDecoration(
      color: navy,
      border: pw.Border(right: pw.BorderSide(color: PdfColor.fromInt(0xFF3D5A6A), width: 0.6)),
    ),
    child: pw.Text(
      text,
      textAlign: pw.TextAlign.center,
      style: pw.TextStyle(fontSize: 8.5, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
    ),
  );

  static pw.Widget _gridRow(
      String day,
      List<int> slots,
      Map<String, TimetableEntry> byCell,
      double slotW,
      pw.BorderSide edge,
      _SubjectPdfColors Function(String) colorsFor,
      ) {
    final cells = <pw.Widget>[];
    var i = 0;
    while (i < slots.length) {
      final entry = byCell['${day}_${slots[i]}'];

      if (entry == null) {
        cells.add(_emptyCell(slotW, edge));
        i++;
        continue;
      }

      // A 3-hour lab is one wide cell across 3 columns.
      final span = entry.isLab ? math.min(3, slots.length - i) : 1;
      cells.add(_classCell(entry, slotW * span, edge, colorsFor(entry.subjectName)));
      i += span;
    }

    return pw.Row(
      children: [
        pw.Container(
          width: _dayColW,
          height: _rowH,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF5F8FA),
            border: pw.Border(right: edge, bottom: edge),
          ),
          child: pw.Text(
            day,
            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF3D5A6A)),
          ),
        ),
        ...cells,
      ],
    );
  }

  static pw.Widget _emptyCell(double width, pw.BorderSide edge) => pw.Container(
    width: width,
    height: _rowH,
    decoration: pw.BoxDecoration(border: pw.Border(right: edge, bottom: edge)),
  );

  static pw.Widget _classCell(TimetableEntry e, double width, pw.BorderSide edge, _SubjectPdfColors c) {
    return pw.Container(
      width: width,
      height: _rowH,
      padding: const pw.EdgeInsets.all(2.5),
      decoration: pw.BoxDecoration(border: pw.Border(right: edge, bottom: edge)),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(width: 3, color: c.border),
          pw.Expanded(
            child: pw.Container(
              color: c.bg,
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    e.shortName ?? e.subjectName,
                    maxLines: 2,
                    style: pw.TextStyle(fontSize: 8, color: c.title, fontWeight: pw.FontWeight.bold),
                  ),
                  if (e.teacherName != null)
                    pw.Text(e.teacherName!, maxLines: 1, style: pw.TextStyle(fontSize: 6.8, color: c.body)),
                  pw.Text(
                    e.roomDisplay + (e.isLab ? '  (Lab 3h)' : ''),
                    maxLines: 1,
                    style: pw.TextStyle(fontSize: 6.8, color: c.body),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Small color key under the grid: one swatch per subject.
  static pw.Widget _legend(List<String> subjectNames, _SubjectPdfColors Function(String) colorsFor) {
    return pw.Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        for (final name in subjectNames)
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Container(
                width: 9,
                height: 9,
                decoration: pw.BoxDecoration(
                  color: colorsFor(name).bg,
                  border: pw.Border.all(color: colorsFor(name).border, width: 0.8),
                ),
              ),
              pw.SizedBox(width: 4),
              pw.Text(name, style: pw.TextStyle(fontSize: 7.5, color: PdfColor.fromInt(0xFF3D5A6A))),
            ],
          ),
      ],
    );
  }

  // ───────────────────────── LIST PAGE ─────────────────────────

  static pw.Widget _buildListPage({
    required String personName,
    required List<TimetableEntry> entries,
    required _SubjectPdfColors Function(String) colorsFor,
  }) {
    final navy = PdfColor.fromInt(0xFF2D4A5A);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('$personName - My Timetable - Class List', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: navy)),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFE0E8ED), width: 0.5),
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
          columnWidths: const {
            0: pw.FixedColumnWidth(24),
            1: pw.FlexColumnWidth(1.3),
            2: pw.FlexColumnWidth(1.3),
            3: pw.FlexColumnWidth(2.4),
            4: pw.FlexColumnWidth(1.8),
            5: pw.FlexColumnWidth(1),
            6: pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: navy),
              children: [
                for (final h in ['#', 'Day', 'Time', 'Subject', 'Teacher', 'Room', 'Type'])
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: pw.Text(h, style: pw.TextStyle(fontSize: 8, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                  ),
              ],
            ),
            for (var i = 0; i < entries.length; i++) _listRow(i + 1, entries[i], colorsFor(entries[i].subjectName)),
          ],
        ),
      ],
    );
  }

  static pw.TableRow _listRow(int index, TimetableEntry e, _SubjectPdfColors c) {
    pw.Widget cell(String text, {PdfColor? bg, PdfColor? color, bool bold = false}) => pw.Container(
      color: bg,
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          color: color,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );

    return pw.TableRow(children: [
      cell('$index'),
      cell(e.day),
      cell(e.slotLabel),
      cell(e.subjectName, bg: c.bg, color: c.title, bold: true),
      cell(e.teacherName ?? '-'),
      cell(e.roomDisplay),
      cell(e.isLab ? 'Lab' : 'Regular', bg: e.isLab ? c.bg : null, color: e.isLab ? c.title : null, bold: e.isLab),
    ]);
  }
}

/// Same light pastel palette used on the app screens, as PDF colors.
class _SubjectPdfColors {
  final PdfColor border;
  final PdfColor bg;
  final PdfColor title;
  final PdfColor body;
  _SubjectPdfColors(int border, int bg, int title, int body)
      : border = PdfColor.fromInt(border),
        bg = PdfColor.fromInt(bg),
        title = PdfColor.fromInt(title),
        body = PdfColor.fromInt(body);

  static final List<_SubjectPdfColors> palette = [
    _SubjectPdfColors(0xFF185FA5, 0xFFE6F1FB, 0xFF0C447C, 0xFF185FA5),
    _SubjectPdfColors(0xFF854F0B, 0xFFFAEEDA, 0xFF633806, 0xFF854F0B),
    _SubjectPdfColors(0xFF3B6D11, 0xFFEAF3DE, 0xFF27500A, 0xFF3B6D11),
    _SubjectPdfColors(0xFF993C1D, 0xFFFAECE7, 0xFF712B13, 0xFF993C1D),
    _SubjectPdfColors(0xFF993556, 0xFFFBEAF0, 0xFF72243E, 0xFF993556),
    _SubjectPdfColors(0xFF534AB7, 0xFFEEEDFE, 0xFF3C3489, 0xFF534AB7),
    _SubjectPdfColors(0xFF0F6E56, 0xFFE1F5EE, 0xFF085041, 0xFF0F6E56),
    _SubjectPdfColors(0xFFA32D2D, 0xFFFCEBEB, 0xFF791F1F, 0xFFA32D2D),
  ];

  static _SubjectPdfColors of(int index) => palette[index < 0 ? 0 : index % palette.length];
}