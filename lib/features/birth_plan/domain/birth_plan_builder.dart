import 'birth_plan.dart';

/// Pure formatter that turns a [BirthPlan] into a shareable plain-text summary
/// the mother can hand to her care team. No I/O — fully unit-testable.
class BirthPlanBuilder {
  const BirthPlanBuilder._();

  static String build(BirthPlan plan, {String? motherName}) {
    final b = StringBuffer();
    b.writeln('MY BIRTH PLAN');
    b.writeln('=============');
    if (motherName != null && motherName.trim().isNotEmpty) {
      b.writeln('For: ${motherName.trim()}');
    }
    b.writeln('');
    b.writeln('This plan describes my preferences. I understand circumstances');
    b.writeln('may change and I trust my care team to keep me and my baby safe.');
    b.writeln('');

    b.writeln('DELIVERY');
    b.writeln('- Preferred birth: ${plan.birthType.label}');
    b.writeln('- Pain management: ${plan.painPreference.label}');
    if (plan.companion.trim().isNotEmpty) {
      b.writeln('- Birth companion: ${plan.companion.trim()}');
    }
    b.writeln('');

    b.writeln('AFTER BIRTH');
    b.writeln('- Immediate skin-to-skin: ${_yn(plan.skinToSkin)}');
    b.writeln('- Delayed cord clamping: ${_yn(plan.delayedCordClamping)}');
    b.writeln('- Feeding: ${plan.feeding.label}');
    b.writeln('');

    if (plan.environmentNotes.trim().isNotEmpty) {
      b.writeln('ENVIRONMENT & COMFORT');
      b.writeln(plan.environmentNotes.trim());
      b.writeln('');
    }

    if (plan.specialRequests.trim().isNotEmpty) {
      b.writeln('SPECIAL REQUESTS');
      b.writeln(plan.specialRequests.trim());
      b.writeln('');
    }

    b.writeln('Thank you for supporting me through this journey.');
    return b.toString().trimRight();
  }

  static String _yn(bool v) => v ? 'Yes, please' : 'No preference';
}
