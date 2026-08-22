// Parsed results for the AI health tools (symptom check, meal plan, weekly
// summary, interaction check, wellness/yoga plan). All are educational only.

List<String> _strs(Object? v) =>
    (v as List<dynamic>?)?.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList() ??
    const [];

String _s(Object? v, [String fallback = '']) =>
    (v is String && v.trim().isNotEmpty) ? v.trim() : fallback;

const _kDisclaimer = 'Educational only — always confirm with your own doctor.';

/// AI explanation of a pregnancy myth: where it likely came from, the truth,
/// and a gentle takeaway. Educational only.
class MythExplanation {
  const MythExplanation({
    required this.origin,
    required this.truth,
    required this.takeaway,
    required this.disclaimer,
  });

  final String origin;
  final String truth;
  final String takeaway;
  final String disclaimer;

  factory MythExplanation.fromJson(Map<String, dynamic> j) => MythExplanation(
        origin: _s(j['origin']),
        truth: _s(j['truth']),
        takeaway: _s(j['takeaway']),
        disclaimer: _s(j['disclaimer'], _kDisclaimer),
      );
}

/// A stage-aware "myth of the day": the myth, the fact, where it came from and
/// a takeaway — generated for the mother's current trimester/condition.
class DailyMyth {
  const DailyMyth({
    required this.myth,
    required this.fact,
    required this.origin,
    required this.takeaway,
    required this.disclaimer,
  });

  final String myth;
  final String fact;
  final String origin;
  final String takeaway;
  final String disclaimer;

  factory DailyMyth.fromJson(Map<String, dynamic> j) => DailyMyth(
        myth: _s(j['myth']),
        fact: _s(j['fact']),
        origin: _s(j['origin']),
        takeaway: _s(j['takeaway']),
        disclaimer: _s(j['disclaimer'], _kDisclaimer),
      );

  Map<String, dynamic> toJson() => {
        'myth': myth,
        'fact': fact,
        'origin': origin,
        'takeaway': takeaway,
        'disclaimer': disclaimer,
      };
}

class BookRef {
  const BookRef({required this.title, required this.author});
  final String title;
  final String author;
  factory BookRef.fromJson(Map<String, dynamic> j) =>
      BookRef(title: _s(j['title']), author: _s(j['author']));
}

/// AI wellbeing/therapy suggestions for how the mother is feeling — calming
/// activities, music (YouTube search phrases), books, meditation/yoga, and a
/// safety note. Educational and supportive only.
class WellbeingPlan {
  const WellbeingPlan({
    required this.supportive,
    required this.activities,
    required this.music,
    required this.books,
    required this.meditationYoga,
    required this.seekHelp,
    required this.urgent,
    required this.disclaimer,
  });

  final String supportive;
  final List<String> activities;
  final List<String> music; // YouTube search phrases
  final List<BookRef> books;
  final List<String> meditationYoga;
  final String seekHelp;
  final bool urgent;
  final String disclaimer;

  factory WellbeingPlan.fromJson(Map<String, dynamic> j) => WellbeingPlan(
        supportive: _s(j['supportive']),
        activities: _strs(j['activities']),
        music: _strs(j['music']),
        books: ((j['books'] as List<dynamic>?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(BookRef.fromJson)
            .where((b) => b.title.isNotEmpty)
            .toList(),
        meditationYoga: _strs(j['meditationYoga']),
        seekHelp: _s(j['seekHelp']),
        urgent: j['urgent'] as bool? ?? false,
        disclaimer: _s(j['disclaimer'], _kDisclaimer),
      );
}

class SymptomCheck {
  const SymptomCheck({
    required this.isCommon,
    required this.whatItMeans,
    required this.urgency,
    required this.selfCare,
    required this.seekCareIf,
    required this.disclaimer,
  });

  final bool isCommon;
  final String whatItMeans;
  final String urgency; // routine | call_soon | urgent
  final List<String> selfCare;
  final List<String> seekCareIf;
  final String disclaimer;

  bool get isUrgent => urgency == 'urgent';
  bool get callSoon => urgency == 'call_soon';

  factory SymptomCheck.fromJson(Map<String, dynamic> j) => SymptomCheck(
        isCommon: j['isCommon'] as bool? ?? false,
        whatItMeans: _s(j['whatItMeans']),
        urgency: _s(j['urgency'], 'routine'),
        selfCare: _strs(j['selfCare']),
        seekCareIf: _strs(j['seekCareIf']),
        disclaimer: _s(j['disclaimer'], _kDisclaimer),
      );
}

class MealDay {
  const MealDay({
    required this.day,
    required this.breakfast,
    required this.lunch,
    required this.snack,
    required this.dinner,
  });

  final String day;
  final String breakfast;
  final String lunch;
  final String snack;
  final String dinner;

  factory MealDay.fromJson(Map<String, dynamic> j) => MealDay(
        day: _s(j['day']),
        breakfast: _s(j['breakfast']),
        lunch: _s(j['lunch']),
        snack: _s(j['snack']),
        dinner: _s(j['dinner']),
      );
}

class MealPlan {
  const MealPlan({
    required this.days,
    required this.keyNutrients,
    required this.tips,
    required this.disclaimer,
  });

  final List<MealDay> days;
  final List<String> keyNutrients;
  final List<String> tips;
  final String disclaimer;

  factory MealPlan.fromJson(Map<String, dynamic> j) => MealPlan(
        days: (j['days'] as List<dynamic>?)
                ?.map((e) => MealDay.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        keyNutrients: _strs(j['keyNutrients']),
        tips: _strs(j['tips']),
        disclaimer: _s(j['disclaimer'], _kDisclaimer),
      );
}

class WeeklySummary {
  const WeeklySummary({
    required this.summary,
    required this.highlights,
    required this.watchOuts,
    required this.disclaimer,
  });

  final String summary;
  final List<String> highlights;
  final List<String> watchOuts;
  final String disclaimer;

  factory WeeklySummary.fromJson(Map<String, dynamic> j) => WeeklySummary(
        summary: _s(j['summary']),
        highlights: _strs(j['highlights']),
        watchOuts: _strs(j['watchOuts']),
        disclaimer: _s(j['disclaimer'], _kDisclaimer),
      );
}

class InteractionPair {
  const InteractionPair({
    required this.a,
    required this.b,
    required this.severity,
    required this.note,
  });

  final String a;
  final String b;
  final String severity; // low | moderate | high
  final String note;

  factory InteractionPair.fromJson(Map<String, dynamic> j) => InteractionPair(
        a: _s(j['a']),
        b: _s(j['b']),
        severity: _s(j['severity'], 'low').toLowerCase(),
        note: _s(j['note']),
      );
}

class InteractionReport {
  const InteractionReport({
    required this.pairs,
    required this.generalNotes,
    required this.disclaimer,
  });

  final List<InteractionPair> pairs;
  final List<String> generalNotes;
  final String disclaimer;

  factory InteractionReport.fromJson(Map<String, dynamic> j) => InteractionReport(
        pairs: (j['pairs'] as List<dynamic>?)
                ?.map((e) => InteractionPair.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        generalNotes: _strs(j['generalNotes']),
        disclaimer: _s(j['disclaimer'], _kDisclaimer),
      );
}

class NameIdea {
  const NameIdea({
    required this.name,
    required this.gender,
    required this.origin,
    required this.meaning,
  });

  final String name;
  final String gender; // boy | girl | unisex
  final String origin;
  final String meaning;

  factory NameIdea.fromJson(Map<String, dynamic> j) => NameIdea(
        name: _s(j['name']),
        gender: _s(j['gender'], 'unisex').toLowerCase(),
        origin: _s(j['origin']),
        meaning: _s(j['meaning']),
      );
}

class NameIdeas {
  const NameIdeas({required this.suggestions, required this.note});

  final List<NameIdea> suggestions;
  final String note;

  factory NameIdeas.fromJson(Map<String, dynamic> j) => NameIdeas(
        suggestions: (j['suggestions'] as List<dynamic>?)
                ?.map((e) => NameIdea.fromJson(e as Map<String, dynamic>))
                .where((n) => n.name.isNotEmpty)
                .toList() ??
            const [],
        note: _s(j['note']),
      );
}

class YogaPose {
  const YogaPose({
    required this.name,
    required this.benefit,
    required this.steps,
    required this.caution,
  });

  final String name;
  final String benefit;
  final List<String> steps;
  final String caution;

  factory YogaPose.fromJson(Map<String, dynamic> j) => YogaPose(
        name: _s(j['name']),
        benefit: _s(j['benefit']),
        steps: _strs(j['steps']),
        caution: _s(j['caution']),
      );
}

class ExerciseItem {
  const ExerciseItem({
    required this.name,
    required this.benefit,
    required this.howTo,
    required this.minutes,
  });

  final String name;
  final String benefit;
  final String howTo;
  final int minutes;

  factory ExerciseItem.fromJson(Map<String, dynamic> j) => ExerciseItem(
        name: _s(j['name']),
        benefit: _s(j['benefit']),
        howTo: _s(j['howTo']),
        minutes: (j['minutes'] as num?)?.toInt() ?? 0,
      );
}

class WellnessPlan {
  const WellnessPlan({
    required this.focus,
    required this.yoga,
    required this.exercises,
    required this.healthTips,
    required this.avoid,
    required this.disclaimer,
  });

  final String focus;
  final List<YogaPose> yoga;
  final List<ExerciseItem> exercises;
  final List<String> healthTips;
  final List<String> avoid;
  final String disclaimer;

  factory WellnessPlan.fromJson(Map<String, dynamic> j) => WellnessPlan(
        focus: _s(j['focus']),
        yoga: (j['yoga'] as List<dynamic>?)
                ?.map((e) => YogaPose.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        exercises: (j['exercises'] as List<dynamic>?)
                ?.map((e) => ExerciseItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        healthTips: _strs(j['healthTips']),
        avoid: _strs(j['avoid']),
        disclaimer: _s(j['disclaimer'], _kDisclaimer),
      );
}
