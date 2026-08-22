import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/home_widget_service.dart';
import '../../../ai_tools/domain/ai_models.dart';
import '../../../ai_tools/presentation/ai_tools_providers.dart';
import '../../../document_scan/presentation/scan_providers.dart';
import '../../../journal/domain/journal_entry.dart';
import '../../../mood/domain/mood_entry.dart';
import '../../../mood/presentation/mood_providers.dart';
import '../../../profile/presentation/controllers/profile_providers.dart';
import '../../../sleep/presentation/sleep_providers.dart';
import '../../../week_tracker/presentation/controllers/week_content_providers.dart';
import '../../data/daily_content.dart';

/// Today's rotating quote for the dashboard.
final dailyQuoteProvider = Provider<String>((ref) {
  return DailyContent.quoteFor(DateTime.now());
});

/// Today's rotating nutrition tip.
final dailyNutritionTipProvider = Provider<String>((ref) {
  return DailyContent.nutritionTipFor(DateTime.now());
});

/// Today's gentle "focus for the day" tied to pregnancy wellbeing.
final dailyFocusProvider = Provider<String>((ref) {
  return DailyContent.dailyFocusFor(DateTime.now());
});

/// Today's light-hearted smile (a wholesome joke / happy line).
final dailySmileProvider = Provider<String>((ref) {
  return DailyContent.smileFor(DateTime.now());
});

/// Today's "pregnancy myth vs fact" (myth, fact), rotated daily. This is the
/// instant, offline fallback shown while (or if) the AI stage-myth isn't ready.
final dailyMythProvider = Provider<(String, String)>((ref) {
  return DailyContent.mythFor(DateTime.now());
});

/// A stage-aware AI "myth of the day" tailored to the mother's current
/// trimester and any conditions. Generated once per day and cached on device
/// (so it's one AI call/day and shows instantly afterwards). Returns null if
/// the AI is unavailable/offline — the card then falls back to
/// [dailyMythProvider].
final stageMythProvider = FutureProvider<DailyMyth?>((ref) async {
  final ctx = ref.watch(aiContextProvider);
  // No pregnancy context yet → let the static myth handle it.
  if (ctx['currentWeek'] == null) return null;

  final now = DateTime.now();
  final dateKey =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final cacheKey = 'stage_myth_${dateKey}_w${ctx['currentWeek']}';

  final prefs = await SharedPreferences.getInstance();
  final cached = prefs.getString(cacheKey);
  if (cached != null) {
    try {
      return DailyMyth.fromJson(jsonDecode(cached) as Map<String, dynamic>);
    } catch (_) {/* fall through to refetch */}
  }

  try {
    final myth =
        await ref.read(documentAiRepositoryProvider).mythOfDay(context: ctx);
    await prefs.setString(cacheKey, jsonEncode(myth.toJson()));
    return myth;
  } catch (_) {
    return null; // offline / AI error → static fallback
  }
});

/// A proactive wellbeing nudge, derived from the mother's OWN logged data:
/// several short nights → offer sleep help; several low-mood days → offer a
/// lift. Returns the feeling to look up + a gentle message, or null if nothing
/// stands out. The home wellbeing card surfaces this without her having to ask.
final wellbeingNudgeProvider =
    Provider<({String feeling, String message})?>((ref) {
  // Short sleep: last few nights average under 6.5h.
  final sleep = ref.watch(sleepEntriesProvider).valueOrNull ?? const [];
  if (sleep.length >= 2) {
    final recent = ([...sleep]..sort((a, b) => b.loggedAt.compareTo(a.loggedAt)))
        .take(5)
        .toList();
    final avg =
        recent.fold<double>(0, (s, e) => s + e.hours) / recent.length;
    if (avg < 6.5) {
      return (
        feeling: 'Not sleeping well',
        message:
            "You've had some short nights lately — want gentle tips to sleep better?"
      );
    }
  }

  // Low mood: 2+ low/rough days in the last week.
  final moods = ref.watch(moodByDateProvider);
  final now = DateTime.now();
  var low = 0;
  for (var i = 0; i < 7; i++) {
    final m = moods[MoodEntry.keyFor(now.subtract(Duration(days: i)))];
    if (m != null &&
        (m.mood == JournalMood.low || m.mood == JournalMood.rough)) {
      low++;
    }
  }
  if (low >= 2) {
    return (
      feeling: 'Low mood',
      message:
          'The last few days have felt low. A few gentle ideas might help — want some?'
    );
  }
  return null;
});

/// Keeps the Android home-screen widget in sync with the current pregnancy.
/// Watched (as a side effect) from the dashboard so the widget refreshes
/// whenever the week/baby-size data changes. No-op off Android.
final homeWidgetSyncProvider = Provider<void>((ref) {
  final preg = ref.watch(activePregnancyProvider).valueOrNull;
  if (preg == null) return;
  final size = ref
      .watch(weekContentProvider(preg.currentWeek))
      .valueOrNull
      ?.sizeComparison;
  HomeWidgetService().update(
    weekLine: 'Week ${preg.currentWeek} of 40',
    subLine: '${preg.daysRemaining} days to go · ${preg.trimester.label}',
    sizeLine: (size != null && size.isNotEmpty)
        ? 'Baby is the size of a ${size.toLowerCase()}'
        : '',
  );
});
