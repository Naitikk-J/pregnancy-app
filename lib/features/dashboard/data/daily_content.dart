/// Curated, offline daily content for the dashboard: motivational quotes and
/// nutrition tips, rotated by day so the home screen feels fresh each day.
class DailyContent {
  DailyContent._();

  static const List<String> quotes = [
    'A baby fills a place in your heart you never knew was empty.',
    'You are growing a miracle — be gentle with yourself today.',
    'Every week is a step closer to meeting your little one.',
    'Rest when you can; you are doing the most important work.',
    'Your body is doing something incredible right now.',
    'Small habits today build a healthy start for your baby.',
    'Breathe. You and your baby are exactly where you need to be.',
    'Nourish yourself — you are nourishing two.',
    'Trust your body. It knows how to do this.',
    'The days are long but the months are quick. Savour them.',
    'Motherhood begins the moment you start caring for your bump.',
    'Kindness to yourself is care for your baby.',
    'Hydrate, breathe, and take it one day at a time.',
    'You are stronger than you think, and braver than you feel.',
    'A calm mother, a calm baby. Take a mindful moment today.',
  ];

  static const List<String> nutritionTips = [
    'Aim for a source of iron (spinach, lentils, red meat) with vitamin C to boost absorption.',
    'Folic acid is vital in early pregnancy — leafy greens, beans and fortified cereals help.',
    'Calcium builds your baby’s bones: include dairy, ragi, sesame or fortified plant milk.',
    'Stay hydrated — water supports the extra blood volume your body is making.',
    'Protein supports growth: eggs, dal, paneer, chicken, fish or tofu at each meal.',
    'Snack on nuts and seeds for healthy fats and steady energy.',
    'Choose whole grains over refined for fibre that eases constipation.',
    'Omega-3 (walnuts, flaxseed, oily fish) supports your baby’s brain development.',
    'Vitamin D helps calcium absorption — a little safe morning sun and fortified foods help.',
    'Eat small, frequent meals to manage nausea and heartburn.',
    'Colourful fruits and vegetables give a range of vitamins and antioxidants.',
    'Limit caffeine to about one cup a day and avoid sugary drinks.',
    'Wash fruits and vegetables well and cook meat and eggs thoroughly.',
    'Include curd/yoghurt for probiotics and easy-to-absorb calcium.',
    'Don’t skip breakfast — it steadies blood sugar and energy for the day.',
  ];

  /// A gentle "focus for today" — one small, encouraging action tied to
  /// looking after yourself and your baby. Rotated daily.
  static const List<String> dailyFocus = [
    'Take a slow 10-minute walk and notice your baby’s movements after.',
    'Drink a glass of water now, and keep your bottle within reach today.',
    'Do a few minutes of deep belly breathing to relax you and your baby.',
    'Add a portion of leafy greens or dal to a meal today for iron.',
    'Sit with your feet up for a little while to ease swelling.',
    'Take your prenatal vitamin and note anything to ask your doctor.',
    'Stretch gently — roll your shoulders and ease your lower back.',
    'Have a calcium-rich snack: curd, milk, ragi or sesame.',
    'Rest when you feel tired — a short nap is good for both of you.',
    'Talk or sing to your bump; your baby can hear your voice now.',
    'Check your posture when sitting to protect your back.',
    'Choose a fruit over a sugary snack for steady energy today.',
    'Do a set of pelvic-floor (Kegel) exercises.',
    'Write one line in your journal about how you feel today.',
    'Get a little safe morning sunlight for vitamin D.',
  ];

  /// A daily smile — a light-hearted, wholesome line to lift the mood.
  /// Each begins with a cheerful emoji (a tiny "happy photo").
  static const List<String> smiles = [
    '😄 Pregnancy math: 1 person + growing a whole new person = you’re basically a superhero.',
    '🤰 They say you glow when pregnant. That’s just the sweat from getting off the sofa — and you’re still glowing.',
    '🍕 Craving pickles with ice cream? Baby has excellent taste already.',
    '😴 Napping isn’t lazy — you’re literally building a human. Rest up, champion.',
    '👶 Your baby’s current hobbies: kicking, hiccupping, and using your bladder as a trampoline.',
    '💛 You’re doing amazing. Yes, even on the day you cried at a nappy advert.',
    '🎉 Fun fact: your body created a brand-new organ (the placenta). Overachiever much?',
    '🦶 That’s not indigestion, that’s your little one practising football at 3 a.m.',
    '🌸 Some days you’re a radiant goddess, other days you’re a tired potato. Both are perfect.',
    '🍫 Chocolate has iron. This is science and we fully support it.',
    '😅 “I’ll just rest my eyes for a second” — you, asleep for two hours. Well earned.',
    '🐢 Bending down to tie your shoes is now an Olympic event. You’re winning gold.',
    '🥰 Your baby already thinks you have the best voice in the world. Sing away.',
    '☀️ You + this bump = the cutest team in the world. Keep going.',
    '📸 Today’s reminder: you are strong, you are glowing, and you are wonderfully brave.',
  ];

  /// A "pregnancy myth of the day" — a common myth paired with the real fact,
  /// so mothers get gently, accurately informed. India-relevant where helpful.
  /// Each entry is (myth, fact). Educational only — not medical advice.
  static const List<(String, String)> myths = [
    (
      'You must "eat for two" and double your food.',
      'You only need about 300–350 extra calories a day, mostly in the later months — quality matters more than quantity.'
    ),
    (
      'You should not exercise during pregnancy.',
      'For most pregnancies, gentle activity like walking and prenatal yoga is safe and good for you and baby. Check with your doctor.'
    ),
    (
      'Ripe papaya or pineapple will cause a miscarriage.',
      'Ripe papaya and normal amounts of pineapple are fine. Only large amounts of raw, unripe papaya are best avoided.'
    ),
    (
      'The shape of your bump tells the baby’s gender.',
      'Bump shape depends on your body, muscles and baby’s position — not the baby’s sex.'
    ),
    (
      'Heartburn means your baby will be born with lots of hair.',
      'Heartburn is caused by pregnancy hormones and the growing uterus, not by your baby’s hair.'
    ),
    (
      'Raising your arms wraps the cord around the baby.',
      'Your everyday movements do not affect the umbilical cord. Move comfortably.'
    ),
    (
      'You must avoid all fish and seafood.',
      'Well-cooked, low-mercury fish is a great source of omega-3. Just avoid raw and high-mercury fish.'
    ),
    (
      'Morning sickness only happens in the morning.',
      'Pregnancy nausea can happen at any time of day or night. Small, frequent meals can help.'
    ),
    (
      'You can’t have any coffee at all.',
      'Up to about one cup a day (≈200 mg caffeine) is generally considered okay. Less is better.'
    ),
    (
      'Cravings reveal whether it’s a boy or a girl.',
      'Cravings are driven by hormones and habit — they don’t predict your baby’s sex.'
    ),
    (
      'Going outside during an eclipse harms the baby.',
      'There is no medical evidence that eclipses affect pregnancy. Rest easy.'
    ),
    (
      'Spicy food brings on labour.',
      'There’s no proven link — spicy food may just cause heartburn, not contractions.'
    ),
    (
      'Your due date is the exact day baby will arrive.',
      'Only about 1 in 20 babies arrive on the due date — it’s a best estimate, and a window is normal.'
    ),
    (
      'A little bleeding always means something is wrong.',
      'Light spotting can be common, but always tell your doctor about any bleeding so they can check.'
    ),
    (
      'You should sleep only flat on your back.',
      'In later pregnancy, sleeping on your side (especially the left) is more comfortable and better for blood flow.'
    ),
  ];

  /// Deterministic index for a given date, so content is stable across a day.
  static int _indexFor(DateTime date, int length) {
    final dayOfYear =
        date.difference(DateTime(date.year)).inDays; // 0-based
    return dayOfYear % length;
  }

  static String quoteFor(DateTime date) => quotes[_indexFor(date, quotes.length)];

  static String nutritionTipFor(DateTime date) =>
      nutritionTips[_indexFor(date, nutritionTips.length)];

  static String dailyFocusFor(DateTime date) =>
      dailyFocus[_indexFor(date, dailyFocus.length)];

  static String smileFor(DateTime date) => smiles[_indexFor(date, smiles.length)];

  /// The (myth, fact) pair for the given day.
  static (String, String) mythFor(DateTime date) =>
      myths[_indexFor(date, myths.length)];
}
