import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pregnancy_companion/core/local/local_storage.dart';

void main() {
  late Directory dir;
  late Box<String> box;
  late LocalStorage storage;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('local_storage_test');
    Hive.init(dir.path);
    box = await Hive.openBox<String>('test_box');
    storage = LocalStorage(box);
  });

  tearDown(() async {
    await box.clear();
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('put then get round-trips a JSON map', () async {
    await storage.put('a', {'name': 'Asha', 'week': 20});
    expect(storage.get('a'), {'name': 'Asha', 'week': 20});
  });

  test('get returns null for a missing key', () {
    expect(storage.get('missing'), isNull);
  });

  test('containsKey reflects presence', () async {
    expect(storage.containsKey('a'), isFalse);
    await storage.put('a', {'x': 1});
    expect(storage.containsKey('a'), isTrue);
  });

  test('getAll returns every stored document', () async {
    await storage.put('a', {'n': 1});
    await storage.put('b', {'n': 2});
    final all = storage.getAll();
    expect(all, hasLength(2));
    expect(all.map((e) => e['n']).toSet(), {1, 2});
  });

  test('delete removes a single document', () async {
    await storage.put('a', {'n': 1});
    await storage.delete('a');
    expect(storage.get('a'), isNull);
  });

  test('clear empties the box', () async {
    await storage.put('a', {'n': 1});
    await storage.put('b', {'n': 2});
    await storage.clear();
    expect(storage.getAll(), isEmpty);
  });
}
