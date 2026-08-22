import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pregnancy_companion/core/services/connectivity_service.dart';

class _MockConnectivity extends Mock implements Connectivity {}

void main() {
  late _MockConnectivity connectivity;
  late ConnectivityService service;

  setUp(() {
    connectivity = _MockConnectivity();
    service = ConnectivityService(connectivity: connectivity);
  });

  group('ConnectivityService.isOnline', () {
    test('is true when any interface is connected', () async {
      when(() => connectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
      expect(await service.isOnline, isTrue);
    });

    test('is false when there is no connectivity', () async {
      when(() => connectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);
      expect(await service.isOnline, isFalse);
    });
  });

  group('ConnectivityService.onStatusChange', () {
    test('maps connectivity events to online/offline booleans', () {
      when(() => connectivity.onConnectivityChanged).thenAnswer(
        (_) => Stream.fromIterable([
          [ConnectivityResult.none],
          [ConnectivityResult.mobile],
          [ConnectivityResult.none, ConnectivityResult.wifi],
        ]),
      );
      expect(service.onStatusChange, emitsInOrder([false, true, true]));
    });
  });
}
