import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../blood_pressure/domain/bp_reading.dart';
import '../../blood_sugar/domain/glucose_reading.dart';
import '../../sleep/domain/sleep_entry.dart';
import '../../symptoms/domain/symptom_entry.dart';
import '../../weight/domain/weight_entry.dart';
import 'health_report_builder.dart';

/// Builds a printable, shareable PDF of the mother's logged vitals (blood
/// pressure, blood sugar, sleep, weight) she can hand to her doctor. Pure: takes
/// data in, returns PDF bytes out. Uses the built-in Helvetica font (Latin
/// only), so it avoids non-Latin glyphs.
class HealthPdfBuilder {
  const HealthPdfBuilder._();

  static const int _maxRows = 30;

  static Future<Uint8List> build({
    required List<BpReading> bp,
    required List<GlucoseReading> glucose,
    required List<SleepEntry> sleep,
    required List<WeightEntry> weight,
    List<SymptomEntry> symptoms = const [],
    String? motherName,
    int? currentWeek,
    DateTime? dueDate,
    double? heightCm,
    double? baselineWeightKg,
    DateTime? generatedAt,
  }) async {
    final dateFmt = DateFormat('d MMM yyyy');
    final dtFmt = DateFormat('d MMM, HH:mm');
    final now = generatedAt ?? DateTime.now();

    final doc = pw.Document();
    const accent = PdfColor.fromInt(0xFFB84A63);
    final headerStyle = pw.TextStyle(
        fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.white);

    pw.Widget sectionTitle(String t) => pw.Container(
          width: double.infinity,
          margin: const pw.EdgeInsets.only(top: 14, bottom: 6),
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: accent,
          child: pw.Text(t, style: headerStyle),
        );

    pw.Widget table(List<String> headers, List<List<String>> rows) {
      if (rows.isEmpty) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text('No readings recorded.',
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey700)),
        );
      }
      return pw.TableHelper.fromTextArray(
        headers: headers,
        data: rows,
        headerStyle:
            pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        cellStyle: const pw.TextStyle(fontSize: 9),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        cellHeight: 18,
        cellAlignments: {0: pw.Alignment.centerLeft},
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      );
    }

    List<T> recent<T>(List<T> src, int Function(T, T) cmp) =>
        ([...src]..sort(cmp)).take(_maxRows).toList();

    final bpSorted = recent<BpReading>(bp, (a, b) => b.loggedAt.compareTo(a.loggedAt));
    final glSorted =
        recent<GlucoseReading>(glucose, (a, b) => b.loggedAt.compareTo(a.loggedAt));
    final slSorted =
        recent<SleepEntry>(sleep, (a, b) => b.loggedAt.compareTo(a.loggedAt));
    final wtSorted =
        recent<WeightEntry>(weight, (a, b) => b.loggedAt.compareTo(a.loggedAt));
    final sySorted =
        recent<SymptomEntry>(symptoms, (a, b) => b.loggedAt.compareTo(a.loggedAt));

    final flags = HealthReportBuilder.indicators(
      bpReadings: bp,
      glucoseReadings: glucose,
      sleepEntries: sleep,
      weightEntries: weight,
      symptoms: symptoms,
      heightCm: heightCm,
      baselineWeightKg: baselineWeightKg,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          // Title block
          pw.Text('Pregnancy Companion',
              style: pw.TextStyle(
                  fontSize: 20, fontWeight: pw.FontWeight.bold, color: accent)),
          pw.Text('Health Report',
              style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700)),
          pw.SizedBox(height: 8),
          pw.Wrap(spacing: 18, runSpacing: 2, children: [
            if (motherName != null && motherName.isNotEmpty)
              _kv('Name', motherName),
            if (currentWeek != null) _kv('Gestational week', '$currentWeek'),
            if (dueDate != null) _kv('Due date', dateFmt.format(dueDate)),
            if (heightCm != null && heightCm > 0)
              _kv('Height', '${heightCm.toStringAsFixed(0)} cm'),
            _kv('Generated', dtFmt.format(now)),
          ]),
          pw.Divider(color: PdfColors.grey400),

          if (flags.isNotEmpty) ...[
            sectionTitle('Assessment & Indicators'),
            table([
              'Indicator',
              'Reading',
              'Interpretation'
            ], [
              for (final f in flags)
                ['${f.marker} ${f.label}', f.value, f.note],
            ]),
            pw.SizedBox(height: 4),
            pw.Text(
              'Guidance: WHO (BMI), IOM (weight gain), ACC/AHA (BP), '
              'ADA/ACOG (glucose), NSF (sleep).',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],

          sectionTitle('Blood Pressure'),
          table([
            'Date',
            'Sys/Dia (mmHg)',
            'Pulse',
            'Category'
          ], [
            for (final r in bpSorted)
              [
                dtFmt.format(r.loggedAt),
                '${r.systolic}/${r.diastolic}',
                r.pulse?.toString() ?? '-',
                r.category.label,
              ]
          ]),

          sectionTitle('Blood Sugar'),
          table([
            'Date',
            'mg/dL',
            'Context',
            'Status'
          ], [
            for (final r in glSorted)
              [
                dtFmt.format(r.loggedAt),
                r.mgDl.toStringAsFixed(0),
                r.context.label,
                r.status,
              ]
          ]),

          sectionTitle('Sleep'),
          table([
            'Date',
            'Hours',
            'Quality (/5)'
          ], [
            for (final e in slSorted)
              [
                DateFormat('d MMM').format(e.loggedAt),
                e.hours.toStringAsFixed(1),
                '${e.quality}',
              ]
          ]),

          sectionTitle('Weight'),
          table([
            'Date',
            'Weight (kg)'
          ], [
            for (final e in wtSorted)
              [
                DateFormat('d MMM').format(e.loggedAt),
                e.weightKg.toStringAsFixed(1),
              ]
          ]),

          sectionTitle('Symptoms'),
          table([
            'Date',
            'Symptom',
            'Severity (/10)',
            'Note'
          ], [
            for (final s in sySorted)
              [
                DateFormat('d MMM').format(s.loggedAt),
                s.type,
                '${s.severity}',
                s.note ?? '-',
              ]
          ]),

          pw.SizedBox(height: 16),
          pw.Text(
            'Informational only - not a substitute for medical advice.',
            style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
                fontStyle: pw.FontStyle.italic),
          ),
        ],
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
      ),
    );

    return doc.save();
  }

  static pw.Widget _kv(String k, String v) => pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
                text: '$k: ',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.TextSpan(
                text: v,
                style: pw.TextStyle(
                    fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );
}
