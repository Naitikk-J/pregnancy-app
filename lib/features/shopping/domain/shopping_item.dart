import 'package:equatable/equatable.dart';

import '../../../core/constants/enums.dart';

/// A shopping / essentials checklist item, stored at
/// `pregnancies/{pid}/shopping/{id}`. Default items use stable slug ids and are
/// only persisted once toggled; custom items are stored in full.
class ShoppingItem extends Equatable {
  const ShoppingItem({
    required this.id,
    required this.label,
    required this.category,
    this.bought = false,
    this.custom = false,
  });

  final String id;
  final String label;
  final ShoppingCategory category;
  final bool bought;
  final bool custom;

  ShoppingItem copyWith({bool? bought}) => ShoppingItem(
        id: id,
        label: label,
        category: category,
        bought: bought ?? this.bought,
        custom: custom,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'category': category.name,
        'bought': bought,
        'custom': custom,
      };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
        id: json['id'] as String,
        label: json['label'] as String? ?? '',
        category: ShoppingCategory.fromName(json['category'] as String?),
        bought: json['bought'] as bool? ?? false,
        custom: json['custom'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [id, label, category, bought, custom];
}

/// Default shopping catalog. Merged with stored bought-state by id.
const List<ShoppingItem> kDefaultShoppingItems = [
  // For mom
  ShoppingItem(id: 's_maternitywear', label: 'Maternity clothes & leggings', category: ShoppingCategory.mother),
  ShoppingItem(id: 's_nursingbra', label: 'Nursing bras', category: ShoppingCategory.mother),
  ShoppingItem(id: 's_pillow', label: 'Pregnancy / feeding pillow', category: ShoppingCategory.mother),
  ShoppingItem(id: 's_stretchcream', label: 'Stretch-mark cream / oil', category: ShoppingCategory.mother),
  ShoppingItem(id: 's_pads', label: 'Maternity pads', category: ShoppingCategory.mother),
  // Baby clothing
  ShoppingItem(id: 's_onesies', label: 'Onesies & bodysuits (0–3m)', category: ShoppingCategory.baby),
  ShoppingItem(id: 's_mittens', label: 'Caps, mittens & booties', category: ShoppingCategory.baby),
  ShoppingItem(id: 's_swaddles', label: 'Swaddle blankets', category: ShoppingCategory.baby),
  ShoppingItem(id: 's_socks', label: 'Baby socks', category: ShoppingCategory.baby),
  // Nursery & gear
  ShoppingItem(id: 's_crib', label: 'Crib / bassinet', category: ShoppingCategory.nursery),
  ShoppingItem(id: 's_mattress', label: 'Firm mattress & sheets', category: ShoppingCategory.nursery),
  ShoppingItem(id: 's_stroller', label: 'Stroller / pram', category: ShoppingCategory.nursery),
  ShoppingItem(id: 's_carseat', label: 'Car seat', category: ShoppingCategory.nursery),
  ShoppingItem(id: 's_carrier', label: 'Baby carrier / wrap', category: ShoppingCategory.nursery),
  ShoppingItem(id: 's_monitor', label: 'Baby monitor', category: ShoppingCategory.nursery),
  // Feeding
  ShoppingItem(id: 's_bottles', label: 'Feeding bottles & brush', category: ShoppingCategory.feeding),
  ShoppingItem(id: 's_sterilizer', label: 'Sterilizer', category: ShoppingCategory.feeding),
  ShoppingItem(id: 's_bibs', label: 'Bibs & burp cloths', category: ShoppingCategory.feeding),
  ShoppingItem(id: 's_pump', label: 'Breast pump (if needed)', category: ShoppingCategory.feeding),
  // Health & care
  ShoppingItem(id: 's_diapers', label: 'Newborn diapers', category: ShoppingCategory.health),
  ShoppingItem(id: 's_wipes', label: 'Baby wipes', category: ShoppingCategory.health),
  ShoppingItem(id: 's_bathtub', label: 'Baby bathtub', category: ShoppingCategory.health),
  ShoppingItem(id: 's_toiletries', label: 'Baby soap, lotion & oil', category: ShoppingCategory.health),
  ShoppingItem(id: 's_thermometer', label: 'Digital thermometer', category: ShoppingCategory.health),
  ShoppingItem(id: 's_nailclipper', label: 'Baby nail clipper & grooming kit', category: ShoppingCategory.health),
];
