import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits the current time once a second. Screens with a live stopwatch (kick
/// counter, contraction timer) watch this so their elapsed labels tick without
/// each holding its own `Timer`. Auto-disposes when no screen is watching, so
/// the periodic timer stops the moment those screens close.
final tickerProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );
});
