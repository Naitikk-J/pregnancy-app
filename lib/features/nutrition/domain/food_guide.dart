import 'package:equatable/equatable.dart';

/// How safe a food is during pregnancy.
enum FoodSafety {
  safe,
  limit,
  avoid;

  String get label => switch (this) {
        FoodSafety.safe => 'Eat well',
        FoodSafety.limit => 'Limit',
        FoodSafety.avoid => 'Avoid',
      };
}

/// A food-guide entry: what it is, how safe it is, and why.
class FoodItem extends Equatable {
  const FoodItem(this.name, this.safety, this.reason);

  final String name;
  final FoodSafety safety;
  final String reason;

  @override
  List<Object?> get props => [name, safety, reason];
}

/// A recommended nutrient with a short why and common sources.
class NutrientTip extends Equatable {
  const NutrientTip(this.nutrient, this.why, this.sources);

  final String nutrient;
  final String why;
  final String sources;

  @override
  List<Object?> get props => [nutrient, why, sources];
}

/// Curated, India-first food-safety guide. Static content (no I/O).
const List<FoodItem> kFoodGuide = [
  // Eat well
  FoodItem('Leafy greens (palak, methi)', FoodSafety.safe, 'Folate, iron & fibre.'),
  FoodItem('Dairy (milk, curd, paneer)', FoodSafety.safe, 'Calcium & protein — pasteurised only.'),
  FoodItem('Dals & legumes', FoodSafety.safe, 'Protein, iron and fibre.'),
  FoodItem('Fruits (well washed)', FoodSafety.safe, 'Vitamins, fibre and hydration.'),
  FoodItem('Whole grains (oats, brown rice)', FoodSafety.safe, 'Steady energy and fibre.'),
  FoodItem('Nuts & seeds', FoodSafety.safe, 'Healthy fats, protein and iron.'),
  FoodItem('Eggs (fully cooked)', FoodSafety.safe, 'Protein and choline.'),
  // Limit
  FoodItem('Caffeine (tea/coffee)', FoodSafety.limit, 'Keep under ~200 mg/day (about 1–2 cups).'),
  FoodItem('Sugary sweets & fried snacks', FoodSafety.limit, 'Extra calories with little nutrition.'),
  FoodItem('Added salt / pickles', FoodSafety.limit, 'Too much salt can raise blood pressure.'),
  FoodItem('Large fish (king mackerel)', FoodSafety.limit, 'Higher mercury — choose small fish, cooked.'),
  // Avoid
  FoodItem('Raw / undercooked meat & eggs', FoodSafety.avoid, 'Risk of listeria/salmonella.'),
  FoodItem('Unpasteurised milk & soft cheese', FoodSafety.avoid, 'Listeria risk.'),
  FoodItem('Papaya (raw/unripe) & pineapple in excess', FoodSafety.avoid, 'Traditionally avoided; ask your doctor.'),
  FoodItem('Alcohol', FoodSafety.avoid, 'No amount is considered safe.'),
  FoodItem('Street/cut fruit & unwashed salads', FoodSafety.avoid, 'Contamination risk.'),
];

/// Key nutrients to prioritise during pregnancy.
const List<NutrientTip> kNutrientTips = [
  NutrientTip('Folic acid', 'Prevents neural-tube defects.', 'Greens, dals, fortified grains, supplement'),
  NutrientTip('Iron', 'Supports increased blood volume; prevents anaemia.', 'Greens, jaggery, dates, legumes, meat'),
  NutrientTip('Calcium', "Builds baby's bones; protects yours.", 'Milk, curd, paneer, ragi, sesame'),
  NutrientTip('Protein', 'Baby growth and your tissues.', 'Dals, eggs, dairy, paneer, nuts'),
  NutrientTip('Iodine', 'Brain development.', 'Iodised salt, dairy'),
];
