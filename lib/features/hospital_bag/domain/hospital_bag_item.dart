import 'package:equatable/equatable.dart';

import '../../../core/constants/enums.dart';

/// A hospital-bag checklist item, stored at
/// `pregnancies/{pid}/hospital_bag/{id}`. Default items use stable slug ids and
/// are only persisted once toggled; custom items are stored in full.
class HospitalBagItem extends Equatable {
  const HospitalBagItem({
    required this.id,
    required this.label,
    required this.category,
    this.packed = false,
    this.custom = false,
  });

  final String id;
  final String label;
  final HospitalBagCategory category;
  final bool packed;
  final bool custom;

  HospitalBagItem copyWith({bool? packed}) => HospitalBagItem(
        id: id,
        label: label,
        category: category,
        packed: packed ?? this.packed,
        custom: custom,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'category': category.name,
        'packed': packed,
        'custom': custom,
      };

  factory HospitalBagItem.fromJson(Map<String, dynamic> json) =>
      HospitalBagItem(
        id: json['id'] as String,
        label: json['label'] as String? ?? '',
        category: HospitalBagCategory.fromName(json['category'] as String?),
        packed: json['packed'] as bool? ?? false,
        custom: json['custom'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [id, label, category, packed, custom];
}

/// Default hospital-bag catalog. Merged with stored packed-state by id.
const List<HospitalBagItem> kDefaultBagItems = [
  // Mother
  HospitalBagItem(id: 'm_nightwear', label: 'Comfortable nightwear / gown', category: HospitalBagCategory.mother),
  HospitalBagItem(id: 'm_nursingbra', label: 'Nursing bras', category: HospitalBagCategory.mother),
  HospitalBagItem(id: 'm_pads', label: 'Maternity sanitary pads', category: HospitalBagCategory.mother),
  HospitalBagItem(id: 'm_toiletries', label: 'Toiletries', category: HospitalBagCategory.mother),
  HospitalBagItem(id: 'm_slippers', label: 'Slippers & warm socks', category: HospitalBagCategory.mother),
  HospitalBagItem(id: 'm_gohome', label: 'Going-home outfit', category: HospitalBagCategory.mother),
  HospitalBagItem(id: 'm_snacks', label: 'Snacks & water bottle', category: HospitalBagCategory.mother),
  // Baby
  HospitalBagItem(id: 'b_clothes', label: 'Baby clothes (2–3 sets)', category: HospitalBagCategory.baby),
  HospitalBagItem(id: 'b_swaddle', label: 'Swaddle / receiving blanket', category: HospitalBagCategory.baby),
  HospitalBagItem(id: 'b_diapers', label: 'Newborn diapers', category: HospitalBagCategory.baby),
  HospitalBagItem(id: 'b_wipes', label: 'Baby wipes', category: HospitalBagCategory.baby),
  HospitalBagItem(id: 'b_capmittens', label: 'Cap & mittens', category: HospitalBagCategory.baby),
  // Documents
  HospitalBagItem(id: 'd_id', label: 'ID proof (Aadhaar etc.)', category: HospitalBagCategory.documents),
  HospitalBagItem(id: 'd_insurance', label: 'Insurance / TPA card', category: HospitalBagCategory.documents),
  HospitalBagItem(id: 'd_records', label: 'Medical records & scans', category: HospitalBagCategory.documents),
  HospitalBagItem(id: 'd_hospital', label: 'Hospital registration papers', category: HospitalBagCategory.documents),
  // Partner
  HospitalBagItem(id: 'p_clothes', label: 'Change of clothes', category: HospitalBagCategory.partner),
  HospitalBagItem(id: 'p_charger', label: 'Phone charger & power bank', category: HospitalBagCategory.partner),
  HospitalBagItem(id: 'p_cash', label: 'Cash & cards', category: HospitalBagCategory.partner),
];
