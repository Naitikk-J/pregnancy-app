import 'package:flutter_test/flutter_test.dart';
import 'package:pregnancy_companion/core/constants/enums.dart';
import 'package:pregnancy_companion/features/shopping/domain/shopping_item.dart';

void main() {
  group('ShoppingItem', () {
    test('round-trips through JSON', () {
      const item = ShoppingItem(
        id: 's_carseat',
        label: 'Car seat',
        category: ShoppingCategory.nursery,
        bought: true,
      );
      final restored = ShoppingItem.fromJson(item.toJson());
      expect(restored, item);
      expect(restored.category, ShoppingCategory.nursery);
      expect(restored.bought, isTrue);
    });

    test('copyWith flips bought but preserves custom flag', () {
      const item = ShoppingItem(
        id: 'x',
        label: 'Custom item',
        category: ShoppingCategory.mother,
        custom: true,
      );
      final done = item.copyWith(bought: true);
      expect(done.bought, isTrue);
      expect(done.custom, isTrue);
      expect(done.id, 'x');
    });
  });

  group('Shopping catalog', () {
    test('every default item has a stable id and label, non-custom', () {
      for (final i in kDefaultShoppingItems) {
        expect(i.id.trim(), isNotEmpty);
        expect(i.label.trim(), isNotEmpty);
        expect(i.custom, isFalse);
      }
    });

    test('default ids are unique', () {
      final ids = kDefaultShoppingItems.map((i) => i.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('covers every shopping category', () {
      final cats = kDefaultShoppingItems.map((i) => i.category).toSet();
      expect(cats, containsAll(ShoppingCategory.values));
    });
  });

  group('ShoppingCategory', () {
    test('fromName resolves known and falls back on unknown', () {
      expect(ShoppingCategory.fromName('feeding'), ShoppingCategory.feeding);
      expect(ShoppingCategory.fromName('nonsense'), ShoppingCategory.baby);
    });

    test('every value has a label', () {
      for (final c in ShoppingCategory.values) {
        expect(c.label.trim(), isNotEmpty);
      }
    });
  });
}
