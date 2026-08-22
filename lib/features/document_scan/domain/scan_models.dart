import '../../../core/constants/enums.dart';
import '../../medicine/domain/medicine.dart';

/// True if [s] is a valid 24-hour "HH:mm" clock time (00:00–23:59).
bool isValidTime(String s) =>
    RegExp(r'^([01]?\d|2[0-3]):[0-5]\d$').hasMatch(s.trim());

/// One medicine extracted from a scanned prescription (before the mother
/// reviews/confirms it). Turns into a real [Medicine] on confirmation.
class ExtractedMedicine {
  ExtractedMedicine({
    required this.name,
    required this.dosage,
    required this.timesPerDay,
    required this.suggestedTimes,
    required this.timing,
    this.durationDays,
    this.instructions = '',
  });

  String name;
  String dosage;
  int timesPerDay;
  List<String> suggestedTimes; // "HH:mm"
  MedicineTiming timing;
  int? durationDays;
  String instructions;

  factory ExtractedMedicine.fromJson(Map<String, dynamic> json) {
    final times = (json['suggestedTimes'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where(isValidTime)
            .toList() ??
        <String>[];
    final perDay = (json['timesPerDay'] as num?)?.toInt() ?? times.length;
    return ExtractedMedicine(
      name: (json['name'] as String? ?? '').trim(),
      dosage: (json['dosage'] as String? ?? '').trim(),
      timesPerDay: perDay <= 0 ? (times.isEmpty ? 1 : times.length) : perDay,
      suggestedTimes: times.isEmpty ? _defaultTimes(perDay) : times,
      timing: MedicineTiming.values.firstWhere(
        (t) => t.name == json['timing'],
        orElse: () => MedicineTiming.anytime,
      ),
      durationDays: (json['durationDays'] as num?)?.toInt(),
      instructions: (json['instructions'] as String? ?? '').trim(),
    );
  }

  /// Sensible default clock times if the model didn't supply any.
  static List<String> _defaultTimes(int perDay) {
    switch (perDay) {
      case <= 1:
        return ['09:00'];
      case 2:
        return ['09:00', '21:00'];
      case 3:
        return ['08:00', '14:00', '20:00'];
      default:
        return ['08:00', '12:00', '16:00', '20:00'];
    }
  }

  /// Build a persistable [Medicine] from this extraction.
  Medicine toMedicine({required String id, DateTime? startDate}) {
    final start = startDate ?? DateTime.now();
    return Medicine(
      id: id,
      name: name.isEmpty ? 'Medicine' : name,
      dosage: dosage,
      timing: timing,
      times: suggestedTimes,
      startDate: start,
      endDate: durationDays != null && durationDays! > 0
          ? start.add(Duration(days: durationDays!))
          : null,
      notes: instructions.isEmpty ? null : instructions,
    );
  }
}

/// The parsed result of a prescription scan.
class PrescriptionResult {
  const PrescriptionResult({
    required this.isPrescription,
    required this.medicines,
    required this.warnings,
  });

  final bool isPrescription;
  final List<ExtractedMedicine> medicines;
  final List<String> warnings;

  factory PrescriptionResult.fromJson(Map<String, dynamic> json) {
    return PrescriptionResult(
      isPrescription: json['isPrescription'] as bool? ?? true,
      medicines: (json['medicines'] as List<dynamic>?)
              ?.map((e) => ExtractedMedicine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((s) => s.trim().isNotEmpty)
              .toList() ??
          const [],
    );
  }
}

/// A single value read from a lab report.
class LabFinding {
  const LabFinding({
    required this.name,
    required this.value,
    required this.unit,
    required this.referenceRange,
    required this.status,
    required this.note,
  });

  final String name;
  final String value;
  final String unit;
  final String referenceRange;
  final String status; // low | normal | high | borderline | unknown
  final String note;

  bool get isNormal => status == 'normal';
  bool get isAbnormal => status == 'low' || status == 'high';

  factory LabFinding.fromJson(Map<String, dynamic> json) => LabFinding(
        name: (json['name'] as String? ?? '').trim(),
        value: (json['value'] as String? ?? json['value']?.toString() ?? '').trim(),
        unit: (json['unit'] as String? ?? '').trim(),
        referenceRange: (json['referenceRange'] as String? ?? '').trim(),
        status: (json['status'] as String? ?? 'unknown').trim().toLowerCase(),
        note: (json['note'] as String? ?? '').trim(),
      );
}

/// The parsed result of a lab report analysis.
class LabAnalysis {
  const LabAnalysis({
    required this.reportType,
    required this.summary,
    required this.findings,
    required this.recommendations,
    required this.urgent,
    required this.disclaimer,
  });

  final String reportType;
  final String summary;
  final List<LabFinding> findings;
  final List<String> recommendations;
  final bool urgent;
  final String disclaimer;

  factory LabAnalysis.fromJson(Map<String, dynamic> json) => LabAnalysis(
        reportType: (json['reportType'] as String? ?? 'Report').trim(),
        summary: (json['summary'] as String? ?? '').trim(),
        findings: (json['findings'] as List<dynamic>?)
                ?.map((e) => LabFinding.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        recommendations: (json['recommendations'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .where((s) => s.trim().isNotEmpty)
                .toList() ??
            const [],
        urgent: json['urgent'] as bool? ?? false,
        disclaimer: (json['disclaimer'] as String? ??
                'This is informational only. Please confirm with your doctor.')
            .trim(),
      );
}

/// Educational information about a medicine (uses + side effects), from the AI.
class MedicineInfo {
  const MedicineInfo({
    required this.name,
    required this.uses,
    required this.howItWorks,
    required this.commonSideEffects,
    required this.pregnancyNote,
    required this.whenToCallDoctor,
    required this.disclaimer,
  });

  final String name;
  final String uses;
  final String howItWorks;
  final List<String> commonSideEffects;
  final String pregnancyNote;
  final List<String> whenToCallDoctor;
  final String disclaimer;

  static List<String> _strings(Object? v) => (v as List<dynamic>?)
          ?.map((e) => e.toString())
          .where((s) => s.trim().isNotEmpty)
          .toList() ??
      const [];

  factory MedicineInfo.fromJson(Map<String, dynamic> json) => MedicineInfo(
        name: (json['name'] as String? ?? '').trim(),
        uses: (json['uses'] as String? ?? '').trim(),
        howItWorks: (json['howItWorks'] as String? ?? '').trim(),
        commonSideEffects: _strings(json['commonSideEffects']),
        pregnancyNote: (json['pregnancyNote'] as String? ?? '').trim(),
        whenToCallDoctor: _strings(json['whenToCallDoctor']),
        disclaimer: (json['disclaimer'] as String? ??
                'Educational only. Always follow your own doctor.')
            .trim(),
      );
}

/// A lightweight, device-local record of a scan the mother made (the original
/// image is kept on the phone; nothing is uploaded to the cloud).
class ScanRecord {
  const ScanRecord({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.imagePath,
    required this.title,
    required this.summary,
  });

  final String id;
  final String type; // 'prescription' | 'lab'
  final DateTime createdAt;
  final String imagePath;
  final String title;
  final String summary;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'createdAt': createdAt.toIso8601String(),
        'imagePath': imagePath,
        'title': title,
        'summary': summary,
      };

  factory ScanRecord.fromJson(Map<String, dynamic> json) => ScanRecord(
        id: json['id'] as String,
        type: json['type'] as String? ?? 'lab',
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        imagePath: json['imagePath'] as String? ?? '',
        title: json['title'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
      );
}
