import 'package:equatable/equatable.dart';

/// Gender a name is commonly associated with.
enum NameGender {
  boy,
  girl,
  unisex;

  String get label => switch (this) {
        NameGender.boy => 'Boy',
        NameGender.girl => 'Girl',
        NameGender.unisex => 'Unisex',
      };

  static NameGender fromName(String? name) => NameGender.values.firstWhere(
        (g) => g.name == name,
        orElse: () => NameGender.unisex,
      );
}

/// A baby-name suggestion from the built-in catalog. Static content — no I/O.
class BabyName extends Equatable {
  const BabyName({
    required this.name,
    required this.gender,
    required this.origin,
    required this.meaning,
  });

  final String name;
  final NameGender gender;
  final String origin;
  final String meaning;

  /// Stable id for favouriting (case/space-insensitive).
  String get slug => name.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '-');

  @override
  List<Object?> get props => [name, gender, origin, meaning];
}

/// A name the mother saved, stored at `pregnancies/{pid}/favoriteNames/{slug}`.
class FavoriteName extends Equatable {
  const FavoriteName({
    required this.id,
    required this.name,
    required this.gender,
    required this.meaning,
    required this.savedAt,
  });

  final String id;
  final String name;
  final NameGender gender;
  final String meaning;
  final DateTime savedAt;

  factory FavoriteName.from(BabyName n) => FavoriteName(
        id: n.slug,
        name: n.name,
        gender: n.gender,
        meaning: n.meaning,
        savedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'gender': gender.name,
        'meaning': meaning,
        'savedAt': savedAt.toUtc().toIso8601String(),
      };

  factory FavoriteName.fromJson(Map<String, dynamic> json) => FavoriteName(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        gender: NameGender.fromName(json['gender'] as String?),
        meaning: json['meaning'] as String? ?? '',
        savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
            DateTime.now(),
      );

  @override
  List<Object?> get props => [id, name, gender, meaning, savedAt];
}

/// A curated, India-first catalog of baby names with meanings.
const List<BabyName> kBabyNames = [
  // Girls
  BabyName(name: 'Aadhya', gender: NameGender.girl, origin: 'Sanskrit', meaning: 'First power; the beginning'),
  BabyName(name: 'Aarohi', gender: NameGender.girl, origin: 'Sanskrit', meaning: 'Musical ascent; rising melody'),
  BabyName(name: 'Anaya', gender: NameGender.girl, origin: 'Sanskrit', meaning: 'Caring; without a superior'),
  BabyName(name: 'Diya', gender: NameGender.girl, origin: 'Sanskrit', meaning: 'Lamp; light'),
  BabyName(name: 'Ira', gender: NameGender.girl, origin: 'Sanskrit', meaning: 'Earth; goddess Saraswati'),
  BabyName(name: 'Kiara', gender: NameGender.girl, origin: 'Italian', meaning: 'Bright; clear'),
  BabyName(name: 'Myra', gender: NameGender.girl, origin: 'Latin', meaning: 'Beloved; admirable'),
  BabyName(name: 'Navya', gender: NameGender.girl, origin: 'Sanskrit', meaning: 'Young; new'),
  BabyName(name: 'Pihu', gender: NameGender.girl, origin: 'Hindi', meaning: 'Sound of a peacock; sweet'),
  BabyName(name: 'Riya', gender: NameGender.girl, origin: 'Sanskrit', meaning: 'Singer; graceful'),
  BabyName(name: 'Saanvi', gender: NameGender.girl, origin: 'Sanskrit', meaning: 'Goddess Lakshmi; knowledge'),
  BabyName(name: 'Sara', gender: NameGender.girl, origin: 'Hebrew', meaning: 'Princess; pure'),
  BabyName(name: 'Tara', gender: NameGender.girl, origin: 'Sanskrit', meaning: 'Star'),
  BabyName(name: 'Zara', gender: NameGender.girl, origin: 'Arabic', meaning: 'Blooming flower; radiance'),
  BabyName(name: 'Meera', gender: NameGender.girl, origin: 'Sanskrit', meaning: 'Devotee of Krishna; prosperous'),

  // Boys
  BabyName(name: 'Aarav', gender: NameGender.boy, origin: 'Sanskrit', meaning: 'Peaceful; calm'),
  BabyName(name: 'Advik', gender: NameGender.boy, origin: 'Sanskrit', meaning: 'Unique; unprecedented'),
  BabyName(name: 'Arjun', gender: NameGender.boy, origin: 'Sanskrit', meaning: 'Bright; shining; hero'),
  BabyName(name: 'Dhruv', gender: NameGender.boy, origin: 'Sanskrit', meaning: 'Pole star; steadfast'),
  BabyName(name: 'Ishaan', gender: NameGender.boy, origin: 'Sanskrit', meaning: 'The sun; Lord Shiva'),
  BabyName(name: 'Kabir', gender: NameGender.boy, origin: 'Arabic', meaning: 'Great; noble'),
  BabyName(name: 'Krish', gender: NameGender.boy, origin: 'Sanskrit', meaning: 'Lord Krishna'),
  BabyName(name: 'Reyansh', gender: NameGender.boy, origin: 'Sanskrit', meaning: 'Ray of light; part of the sun'),
  BabyName(name: 'Rudra', gender: NameGender.boy, origin: 'Sanskrit', meaning: 'Lord Shiva; mighty'),
  BabyName(name: 'Vihaan', gender: NameGender.boy, origin: 'Sanskrit', meaning: 'Dawn; morning'),
  BabyName(name: 'Vivaan', gender: NameGender.boy, origin: 'Sanskrit', meaning: 'Full of life'),
  BabyName(name: 'Aryan', gender: NameGender.boy, origin: 'Sanskrit', meaning: 'Noble; honourable'),
  BabyName(name: 'Ved', gender: NameGender.boy, origin: 'Sanskrit', meaning: 'Sacred knowledge'),
  BabyName(name: 'Neil', gender: NameGender.boy, origin: 'Irish', meaning: 'Champion; cloud'),
  BabyName(name: 'Om', gender: NameGender.boy, origin: 'Sanskrit', meaning: 'Sacred sound; the universe'),

  // Unisex
  BabyName(name: 'Kiaan', gender: NameGender.unisex, origin: 'Sanskrit', meaning: 'Grace of God; ancient'),
  BabyName(name: 'Zia', gender: NameGender.unisex, origin: 'Arabic', meaning: 'Light; splendour'),
  BabyName(name: 'Avni', gender: NameGender.unisex, origin: 'Sanskrit', meaning: 'The earth'),
  BabyName(name: 'Riaan', gender: NameGender.unisex, origin: 'Sanskrit', meaning: 'Little king; God is gracious'),
  BabyName(name: 'Noor', gender: NameGender.unisex, origin: 'Arabic', meaning: 'Light'),
  BabyName(name: 'Amara', gender: NameGender.unisex, origin: 'Sanskrit', meaning: 'Eternal; immortal'),
];
