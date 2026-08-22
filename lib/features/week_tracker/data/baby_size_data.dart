/// Approximate fetal size by gestational week — a compact, complete reference
/// (weeks 4–40) so the tracker always has a size comparison, length and weight
/// even when no detailed content is available offline.
///
/// Values are typical published averages (crown–rump early, crown–heel from
/// ~week 20). They are educational estimates, not clinical measurements.
class BabySize {
  const BabySize(this.fruit, this.lengthCm, this.weightG);
  final String fruit;
  final double lengthCm;
  final int weightG;
}

class BabySizeData {
  BabySizeData._();

  static const Map<int, BabySize> byWeek = {
    4: BabySize('Poppy seed', 0.1, 0),
    5: BabySize('Sesame seed', 0.2, 0),
    6: BabySize('Lentil', 0.6, 0),
    7: BabySize('Blueberry', 1.3, 1),
    8: BabySize('Kidney bean', 1.6, 1),
    9: BabySize('Grape', 2.3, 2),
    10: BabySize('Strawberry', 3.1, 4),
    11: BabySize('Fig', 4.1, 7),
    12: BabySize('Lime', 5.4, 14),
    13: BabySize('Pea pod', 7.4, 23),
    14: BabySize('Lemon', 8.7, 43),
    15: BabySize('Apple', 10.1, 70),
    16: BabySize('Avocado', 11.6, 100),
    17: BabySize('Pear', 13.0, 140),
    18: BabySize('Bell pepper', 14.2, 190),
    19: BabySize('Mango', 15.3, 240),
    20: BabySize('Banana', 25.6, 300),
    21: BabySize('Carrot', 26.7, 360),
    22: BabySize('Papaya', 27.8, 430),
    23: BabySize('Grapefruit', 28.9, 501),
    24: BabySize('Corn cob', 30.0, 600),
    25: BabySize('Rutabaga', 34.6, 660),
    26: BabySize('Lettuce head', 35.6, 760),
    27: BabySize('Cauliflower', 36.6, 875),
    28: BabySize('Eggplant', 37.6, 1005),
    29: BabySize('Butternut squash', 38.6, 1153),
    30: BabySize('Cabbage', 39.9, 1319),
    31: BabySize('Coconut', 41.1, 1502),
    32: BabySize('Squash', 42.4, 1702),
    33: BabySize('Pineapple', 43.7, 1918),
    34: BabySize('Cantaloupe', 45.0, 2146),
    35: BabySize('Honeydew melon', 46.2, 2383),
    36: BabySize('Romaine lettuce', 47.4, 2622),
    37: BabySize('Swiss chard', 48.6, 2859),
    38: BabySize('Leek', 49.8, 3083),
    39: BabySize('Mini watermelon', 50.7, 3288),
    40: BabySize('Small pumpkin', 51.2, 3462),
  };

  static BabySize? forWeek(int week) => byWeek[week];
}
