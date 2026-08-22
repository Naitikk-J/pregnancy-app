import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Pushes a compact pregnancy summary to the Android home-screen widget
/// (see `PregnancyWidgetProvider.kt`). Data is stored via the home_widget
/// plugin's SharedPreferences and the widget re-renders on [updateWidget].
class HomeWidgetService {
  static const String _providerName = 'PregnancyWidgetProvider';

  Future<void> update({
    required String weekLine,
    required String subLine,
    required String sizeLine,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('week_line', weekLine);
      await HomeWidget.saveWidgetData<String>('sub_line', subLine);
      await HomeWidget.saveWidgetData<String>('size_line', sizeLine);
      await HomeWidget.updateWidget(
        name: _providerName,
        androidName: _providerName,
      );
    } catch (e) {
      // The widget is a nice-to-have; never let it break the app.
      if (kDebugMode) debugPrint('[home_widget] update failed: $e');
    }
  }
}
