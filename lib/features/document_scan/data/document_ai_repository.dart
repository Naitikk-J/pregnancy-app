import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../ai_tools/domain/ai_models.dart';
import '../domain/scan_models.dart';

/// Sends a prescription or lab-report image/PDF to the AI proxy (the same
/// Cloudflare Worker as "Ask Mira", extended with a multimodal vision path) and
/// returns structured data. The document is analysed in transit and never
/// stored server-side; the caller keeps the original file on the device.
class DocumentAiRepository {
  DocumentAiRepository(
    this._auth, {
    required this.endpoint,
    this.lang = 'en',
    this.userKey = '',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final FirebaseAuth _auth;
  final String endpoint;

  /// The user's language code ('en'/'hi'); the Worker replies in this language.
  final String lang;

  /// The user's OWN Gemini API key (optional), for per-user free quota.
  final String userKey;
  final http.Client _client;

  Future<PrescriptionResult> scanPrescription({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final result = await _post(task: 'prescription', bytes: bytes, mimeType: mimeType);
    return PrescriptionResult.fromJson(result);
  }

  Future<LabAnalysis> analyzeLab({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final result = await _post(task: 'lab', bytes: bytes, mimeType: mimeType);
    return LabAnalysis.fromJson(result);
  }

  /// Educational info (uses + side effects) for a named medicine. Text-only.
  Future<MedicineInfo> medicineInfo({
    required String name,
    String? dosage,
  }) async {
    final result = await _postJson({
      'task': 'medicine_info',
      'name': name,
      if (dosage != null && dosage.isNotEmpty) 'dosage': dosage,
    });
    return MedicineInfo.fromJson(result);
  }

  // ---- AI health tools ----

  Future<SymptomCheck> symptomCheck({
    required String symptom,
    Map<String, dynamic> context = const {},
  }) async {
    final r = await _postJson(
        {'task': 'symptom_check', 'symptom': symptom, 'context': context});
    return SymptomCheck.fromJson(r);
  }

  Future<MealPlan> mealPlan({
    required String diet,
    Map<String, dynamic> context = const {},
  }) async {
    final r =
        await _postJson({'task': 'meal_plan', 'diet': diet, 'context': context});
    return MealPlan.fromJson(r);
  }

  Future<WellnessPlan> wellnessPlan({
    Map<String, dynamic> context = const {},
  }) async {
    final r = await _postJson({'task': 'wellness_plan', 'context': context});
    return WellnessPlan.fromJson(r);
  }

  Future<WeeklySummary> weeklySummary({
    required Map<String, dynamic> stats,
    Map<String, dynamic> context = const {},
  }) async {
    final r = await _postJson(
        {'task': 'weekly_summary', 'stats': stats, 'context': context});
    return WeeklySummary.fromJson(r);
  }

  Future<InteractionReport> interactions({
    required List<String> medicines,
  }) async {
    final r =
        await _postJson({'task': 'interactions', 'medicines': medicines});
    return InteractionReport.fromJson(r);
  }

  /// AI wellbeing/therapy suggestions for how the mother is feeling.
  Future<WellbeingPlan> wellbeing({
    required String feeling,
    Map<String, dynamic> context = const {},
  }) async {
    final r = await _postJson(
        {'task': 'wellbeing', 'feeling': feeling, 'context': context});
    return WellbeingPlan.fromJson(r);
  }

  /// A stage-aware pregnancy myth (myth + fact + origin + takeaway), tailored to
  /// the mother's current trimester/condition via [context].
  Future<DailyMyth> mythOfDay({
    Map<String, dynamic> context = const {},
  }) async {
    final r = await _postJson({'task': 'myth_of_day', 'context': context});
    return DailyMyth.fromJson(r);
  }

  /// AI explanation of where a pregnancy myth likely came from + the truth.
  Future<MythExplanation> explainMyth({
    required String myth,
    String fact = '',
  }) async {
    final r = await _postJson({
      'task': 'myth_explain',
      'myth': myth,
      if (fact.isNotEmpty) 'fact': fact,
    });
    return MythExplanation.fromJson(r);
  }

  /// AI baby-name suggestions from freeform parent preferences.
  Future<NameIdeas> babyNames({
    String gender = 'any',
    String startsWith = '',
    String origin = '',
    String theme = '',
  }) async {
    final r = await _postJson({
      'task': 'baby_names',
      'gender': gender,
      if (startsWith.isNotEmpty) 'startsWith': startsWith,
      if (origin.isNotEmpty) 'origin': origin,
      if (theme.isNotEmpty) 'theme': theme,
    });
    return NameIdeas.fromJson(r);
  }

  Future<Map<String, dynamic>> _post({
    required String task,
    required Uint8List bytes,
    required String mimeType,
  }) {
    return _postJson({
      'task': task,
      'image': {'mimeType': mimeType, 'data': base64Encode(bytes)},
    });
  }

  Future<Map<String, dynamic>> _postJson(Map<String, dynamic> payload) async {
    if (endpoint.isEmpty || endpoint.contains('REPLACE_ME')) {
      throw StateError('AI endpoint is not configured (see worker/README.md).');
    }
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to use this feature.');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Could not obtain an auth token.');
    }

    final res = await _client
        .post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            ...payload,
            'lang': lang,
            if (userKey.isNotEmpty) 'userKey': userKey,
          }),
        )
        .timeout(const Duration(seconds: 90));

    final data = _decode(res.body);
    if (res.statusCode != 200) {
      throw StateError(
        (data?['error'] as String?) ?? 'Analysis failed (${res.statusCode}).',
      );
    }
    if (data == null) throw StateError('Empty response from the analyzer.');
    if (data['refused'] == true) {
      throw StateError(
        (data['error'] as String?) ??
            'I could not analyze that safely. Please consult your doctor.',
      );
    }
    final result = data['result'];
    if (result is Map<String, dynamic>) return result;
    throw StateError('The analyzer returned an unexpected result.');
  }

  Map<String, dynamic>? _decode(String body) {
    try {
      final v = jsonDecode(body);
      return v is Map<String, dynamic> ? v : null;
    } catch (_) {
      return null;
    }
  }
}
